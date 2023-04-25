# typed: true
# frozen_string_literal: true

require "cli/parser"
require "formula_installer"
require "install"
require "upgrade"
require "cask/utils"
require "cask/upgrade"
require "cask/macos"
require "api"

module Homebrew
  module_function

  sig { returns(CLI::Parser) }
  def upgrade_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Upgrade outdated casks and outdated, unpinned formulae using the same options they were originally
        installed with, plus any appended brew formula options. If <cask> or <formula> are specified,
        upgrade only the given <cask> or <formula> kegs (unless they are pinned; see `pin`, `unpin`).

        Unless `HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK` is set, `brew upgrade` or `brew reinstall` will be run for
        outdated dependents and dependents with broken linkage, respectively.

        Unless `HOMEBREW_NO_INSTALL_CLEANUP` is set, `brew cleanup` will then be run for the
        upgraded formulae or, every 30 days, for all formulae.
      EOS
      switch "-d", "--debug",
             description: "If brewing fails, open an interactive debugging session with access to IRB " \
                          "or a shell inside the temporary build directory."
      switch "-f", "--force",
             description: "Install formulae without checking for previously installed keg-only or " \
                          "non-migrated versions. When installing casks, overwrite existing files " \
                          "(binaries and symlinks are excluded, unless originally from the same cask)."
      switch "-v", "--verbose",
             description: "Print the verification and postinstall steps."
      switch "-n", "--dry-run",
             description: "Show what would be upgraded, but do not actually upgrade anything."
      [
        [:switch, "--formula", "--formulae", {
          description: "Treat all named arguments as formulae. If no named arguments " \
                       "are specified, upgrade only outdated formulae.",
        }],
        [:switch, "-s", "--build-from-source", {
          description: "Compile <formula> from source even if a bottle is available.",
        }],
        [:switch, "-i", "--interactive", {
          description: "Download and patch <formula>, then open a shell. This allows the user to " \
                       "run `./configure --help` and otherwise determine how to turn the software " \
                       "package into a Homebrew package.",
        }],
        [:switch, "--force-bottle", {
          description: "Install from a bottle if it exists for the current or newest version of " \
                       "macOS, even if it would not normally be used for installation.",
        }],
        [:switch, "--fetch-HEAD", {
          description: "Fetch the upstream repository to detect if the HEAD installation of the " \
                       "formula is outdated. Otherwise, the repository's HEAD will only be checked for " \
                       "updates when a new stable or development version has been released.",
        }],
        [:switch, "--ignore-pinned", {
          description: "Set a successful exit status even if pinned formulae are not upgraded.",
        }],
        [:switch, "--keep-tmp", {
          description: "Retain the temporary files created during installation.",
        }],
        [:switch, "--debug-symbols", {
          depends_on:  "--build-from-source",
          description: "Generate debug symbols on build. Source will be retained in a cache directory.",
        }],
        [:switch, "--display-times", {
          env:         :display_install_times,
          description: "Print install times for each package at the end of the run.",
        }],
      ].each do |args|
        options = args.pop
        send(*args, **options)
        conflicts "--cask", args.last
      end
      formula_options
      [
        [:switch, "--cask", "--casks", {
          description: "Treat all named arguments as casks. If no named arguments " \
                       "are specified, upgrade only outdated casks.",
        }],
        [:switch, "--skip-cask-deps", {
          description: "Skip installing cask dependencies.",
        }],
        [:switch, "-g", "--greedy", {
          description: "Also include casks with `auto_updates true` or `version :latest`.",
        }],
        [:switch, "--greedy-latest", {
          description: "Also include casks with `version :latest`.",
        }],
        [:switch, "--greedy-auto-updates", {
          description: "Also include casks with `auto_updates true`.",
        }],
        [:switch, "--[no-]binaries", {
          description: "Disable/enable linking of helper executables (default: enabled).",
          env:         :cask_opts_binaries,
        }],
        [:switch, "--require-sha",  {
          description: "Require all casks to have a checksum.",
          env:         :cask_opts_require_sha,
        }],
        [:switch, "--[no-]quarantine", {
          description: "Disable/enable quarantining of downloads (default: enabled).",
          env:         :cask_opts_quarantine,
        }],
      ].each do |args|
        options = args.pop
        send(*args, **options)
        conflicts "--formula", args.last
      end
      cask_options

      conflicts "--build-from-source", "--force-bottle"

      named_args [:outdated_formula, :outdated_cask]
    end
  end

  sig { void }
  def upgrade
    args = upgrade_args.parse

    formulae, casks = args.named.to_resolved_formulae_to_casks
    # If one or more formulae are specified, but no casks were
    # specified, we want to make note of that so we don't
    # try to upgrade all outdated casks.
    only_upgrade_formulae = formulae.present? && casks.blank?
    only_upgrade_casks = casks.present? && formulae.blank?

    upgrade_outdated_formulae(formulae, args: args) unless only_upgrade_casks
    upgrade_outdated_casks(casks, args: args) unless only_upgrade_formulae

    Cleanup.periodic_clean!(dry_run: args.dry_run?)

    Homebrew.messages.display_messages(display_times: args.display_times?)
  end

  sig { params(formulae: T::Array[Formula], args: T.untyped).returns(T::Boolean) }
  def upgrade_outdated_formulae(formulae, args:)
    return false if args.cask?

    if args.build_from_source?
      unless DevelopmentTools.installed?
        raise BuildFlagsError.new(["--build-from-source"], bottled: formulae.all?(&:bottled?))
      end

      unless Homebrew::EnvConfig.developer?
        opoo "building from source is not supported!"
        puts "You're on your own. Failures are expected so don't create any issues, please!"
      end
    end

    Install.perform_preinstall_checks

    if formulae.blank?
      outdated = Formula.installed.select do |f|
        f.outdated?(fetch_head: args.fetch_HEAD?)
      end
    else
      outdated, not_outdated = formulae.partition do |f|
        f.outdated?(fetch_head: args.fetch_HEAD?)
      end

      not_outdated.each do |f|
        versions = f.installed_kegs.map(&:version)
        if versions.empty?
          ofail "#{f.full_specified_name} not installed"
        else
          version = versions.max
          opoo "#{f.full_specified_name} #{version} already installed"
        end
      end
    end

    return false if outdated.blank?

    pinned = outdated.select(&:pinned?)
    outdated -= pinned
    formulae_to_install = outdated.map do |f|
      f_latest = f.latest_formula
      if f_latest.latest_version_installed?
        f
      else
        f_latest
      end
    end

    if !pinned.empty? && !args.ignore_pinned?
      ofail "Not upgrading #{pinned.count} pinned #{Utils.pluralize("package", pinned.count)}:"
      puts pinned.map { |f| "#{f.full_specified_name} #{f.pkg_version}" } * ", "
    end

    if formulae_to_install.empty?
      oh1 "No packages to upgrade"
    else
      verb = args.dry_run? ? "Would upgrade" : "Upgrading"
      oh1 "#{verb} #{formulae_to_install.count} outdated #{Utils.pluralize("package", formulae_to_install.count)}:"
      formulae_upgrades = formulae_to_install.map do |f|
        if f.optlinked?
          "#{f.full_specified_name} #{Keg.new(f.opt_prefix).version} -> #{f.pkg_version}"
        else
          "#{f.full_specified_name} #{f.pkg_version}"
        end
      end
      puts formulae_upgrades.join("\n")
    end

    Upgrade.upgrade_formulae(
      formulae_to_install,
      flags:                      args.flags_only,
      dry_run:                    args.dry_run?,
      installed_on_request:       args.named.present?,
      force_bottle:               args.force_bottle?,
      build_from_source_formulae: args.build_from_source_formulae,
      interactive:                args.interactive?,
      keep_tmp:                   args.keep_tmp?,
      debug_symbols:              args.debug_symbols?,
      force:                      args.force?,
      debug:                      args.debug?,
      quiet:                      args.quiet?,
      verbose:                    args.verbose?,
    )

    Upgrade.check_installed_dependents(
      formulae_to_install,
      flags:                      args.flags_only,
      dry_run:                    args.dry_run?,
      installed_on_request:       args.named.present?,
      force_bottle:               args.force_bottle?,
      build_from_source_formulae: args.build_from_source_formulae,
      interactive:                args.interactive?,
      keep_tmp:                   args.keep_tmp?,
      debug_symbols:              args.debug_symbols?,
      force:                      args.force?,
      debug:                      args.debug?,
      quiet:                      args.quiet?,
      verbose:                    args.verbose?,
    )

    true
  end

  sig { params(casks: T::Array[Cask::Cask], args: T.untyped).returns(T::Boolean) }
  def upgrade_outdated_casks(casks, args:)
    return false if args.formula?

    Cask::Upgrade.upgrade_casks(
      *casks,
      force:               args.force?,
      greedy:              args.greedy?,
      greedy_latest:       args.greedy_latest?,
      greedy_auto_updates: args.greedy_auto_updates?,
      dry_run:             args.dry_run?,
      binaries:            args.binaries?,
      quarantine:          args.quarantine?,
      require_sha:         args.require_sha?,
      skip_cask_deps:      args.skip_cask_deps?,
      verbose:             args.verbose?,
      args:                args,
    )
  end
end
