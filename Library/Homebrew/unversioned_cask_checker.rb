# typed: true
# frozen_string_literal: true

require "bundle_version"
require "cask/cask"
require "cask/installer"

module Homebrew
  # Check unversioned casks for updates by extracting their
  # contents and guessing the version from contained files.
  #
  # @api private
  class UnversionedCaskChecker
    extend T::Sig

    sig {  returns(Cask::Cask) }
    attr_reader :cask

    sig { params(cask: Cask::Cask).void }
    def initialize(cask)
      @cask = cask
    end

    sig { returns(Cask::Installer) }
    def installer
      @installer ||= Cask::Installer.new(cask, verify_download_integrity: false)
    end

    sig { returns(T::Array[Cask::Artifact::App]) }
    def apps
      @apps ||= @cask.artifacts.select { |a| a.is_a?(Cask::Artifact::App) }
    end

    sig { returns(T::Array[Cask::Artifact::Pkg]) }
    def pkgs
      @pkgs ||= @cask.artifacts.select { |a| a.is_a?(Cask::Artifact::Pkg) }
    end

    sig { returns(T::Boolean) }
    def single_app_cask?
      apps.count == 1
    end

    sig { returns(T::Boolean) }
    def single_pkg_cask?
      pkgs.count == 1
    end

    # Filter paths to `Info.plist` files so that ones belonging
    # to e.g. nested `.app`s are ignored.
    sig { params(paths: T::Array[Pathname]).returns(T::Array[Pathname]) }
    def top_level_info_plists(paths)
      # Go from `./Contents/Info.plist` to `./`.
      top_level_paths = paths.map { |path| path.parent.parent }

      paths.reject do |path|
        top_level_paths.any? do |_other_top_level_path|
          path.ascend.drop(3).any? { |parent_path| top_level_paths.include?(parent_path) }
        end
      end
    end

    sig { returns(T.nilable(String)) }
    def guess_cask_version
      if apps.empty? && pkgs.empty?
        opoo "Cask #{cask} does not contain any apps or PKG installers."
        return
      end

      Dir.mktmpdir do |dir|
        dir = Pathname(dir)

        installer.yield_self do |i|
          i.extract_primary_container(to: dir)
        rescue ErrorDuringExecution => e
          onoe e
          return nil
        end

        info_plist_paths = apps.flat_map do |app|
          top_level_info_plists(Pathname.glob(dir/"**"/app.source.basename/"Contents"/"Info.plist")).sort
        end

        info_plist_paths.each do |info_plist_path|
          if (version = BundleVersion.from_info_plist(info_plist_path))
            return version.nice_version
          end
        end

        pkg_paths = pkgs.flat_map do |pkg|
          Pathname.glob(dir/"**"/pkg.path.basename).sort
        end

        pkg_paths.each do |pkg_path|
          packages =
            system_command!("installer", args: ["-plist", "-pkginfo", "-pkg", pkg_path])
            .plist
            .map { |package| package.fetch("Package") }

          Dir.mktmpdir do |extract_dir|
            extract_dir = Pathname(extract_dir)
            FileUtils.rmdir extract_dir

            begin
              system_command! "pkgutil", args: ["--expand-full", pkg_path, extract_dir]
            rescue ErrorDuringExecution => e
              onoe "Failed to extract #{pkg_path.basename}: #{e}"
              next
            end

            top_level_info_plist_paths = top_level_info_plists(Pathname.glob(extract_dir/"**/Contents/Info.plist"))

            unique_info_plist_versions =
              top_level_info_plist_paths.map { |i| BundleVersion.from_info_plist(i)&.nice_version }
                                        .compact.uniq
            return unique_info_plist_versions.first if unique_info_plist_versions.count == 1

            package_info_path = extract_dir/"PackageInfo"
            if package_info_path.exist?
              if (version = BundleVersion.from_package_info(package_info_path))
                return version.nice_version
              end
            elsif packages.count == 1
              onoe "#{pkg_path.basename} does not contain a `PackageInfo` file."
            end

            distribution_path = extract_dir/"Distribution"
            if distribution_path.exist?
              Homebrew.install_bundler_gems!
              require "nokogiri"

              xml = Nokogiri::XML(distribution_path.read)

              product_version = xml.xpath("//installer-gui-script//product").first&.attr("version")
              return product_version if product_version
            end

            opoo "#{pkg_path.basename} contains multiple packages: #{packages}" if packages.count != 1

            $stderr.puts Pathname.glob(extract_dir/"**/*")
                                 .map { |path|
                                   regex = %r{\A(.*?\.(app|qlgenerator|saver|plugin|kext|bundle|osax))/.*\Z}
                                   path.to_s.sub(regex, '\1')
                                 }.uniq
          ensure
            Cask::Utils.gain_permissions_remove(extract_dir)
            extract_dir.mkpath
          end
        end

        nil
      end
    end
  end
end
