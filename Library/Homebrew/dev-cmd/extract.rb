#:  * `extract` [`--force`] <formula> <tap> [`--version=`<version>]:
#:    Looks through repository history to find the <version> of <formula> and
#:    creates a copy in <tap>/Formula/<formula>@<version>.rb. If the tap is
#:    not installed yet, attempts to install/clone the tap before continuing.
#:
#:    If `--force` is passed, the file at the destination will be overwritten
#:    if it already exists. Otherwise, existing files will be preserved.
#:
#:    If an argument is passed through `--version`, <version> of <formula>
#:    will be extracted and placed in the destination tap. Otherwise, the most
#:    recent version that can be found will be used.

require "cli_parser"
require "utils/git"
require "formulary"
require "tap"

# rubocop:disable Style/MethodMissingSuper
class BottleSpecification
  def method_missing(*); end

  def respond_to_missing?(*)
    true
  end
end

class Module
  def method_missing(*); end

  def respond_to_missing?(*)
    true
  end
end

class DependencyCollector
  def parse_symbol_spec(*); end

  module Compat
    def parse_string_spec(spec, tags)
      super
    end
  end

  prepend Compat
end

# rubocop:enable Style/MethodMissingSuper
module Homebrew
  module_function

  def extract
    Homebrew::CLI::Parser.parse do
      flag   "--version="
      switch :debug
      switch :force
    end

    # Expect exactly two named arguments: formula and tap
    raise UsageError if ARGV.named.length != 2

    destination_tap = Tap.fetch(ARGV.named[1])
    odie "Cannot extract formula to homebrew/core!" if destination_tap.core_tap?
    destination_tap.install unless destination_tap.installed?

    name = ARGV.named.first.downcase
    repo = CoreTap.instance.path
    # Formulae can technically live in "<repo>/<formula>.rb" or
    # "<repo>/Formula/<formula>.rb", but explicitly use the latter for now
    # since that is now core tap is structured.
    file = repo/"Formula/#{name}.rb"

    if args.version
      version = args.version
      rev = "HEAD"
      test_formula = nil
      loop do
        loop do
          rev = Git.last_revision_commit_of_file(repo, file, before_commit: "#{rev}~1")
          break if rev.empty?
          break unless Git.last_revision_of_file(repo, file, before_commit: rev).empty?
          ohai "Skipping revision #{rev} - file is empty at this revision" if ARGV.debug?
        end
        test_formula = formula_at_revision(repo, name, file, rev)
        break if test_formula.nil? || test_formula.version == version
        ohai "Trying #{test_formula.version} from revision #{rev} against desired #{version}" if ARGV.debug?
      end
      odie "Could not find #{name}! The formula or version may not have existed." if test_formula.nil?
      result = Git.last_revision_of_file(repo, file, before_commit: rev)
    elsif File.exist?(file)
      version = Formulary.factory(file).version
      result = File.read(file)
    else
      rev = Git.last_revision_commit_of_file(repo, file)
      version = formula_at_revision(repo, name, file, rev).version
      odie "Could not find #{name}! The formula or version may not have existed." if rev.empty?
      result = Git.last_revision_of_file(repo, file)
    end

    # The class name has to be renamed to match the new filename,
    # e.g. Foo version 1.2.3 becomes FooAT123 and resides in Foo@1.2.3.rb.
    class_name = name.capitalize
    versioned_name = Formulary.class_s("#{class_name}@#{version}")
    result.gsub!("class #{class_name} < Formula", "class #{versioned_name} < Formula")

    path = destination_tap.path/"Formula/#{name}@#{version}.rb"
    if path.exist?
      unless ARGV.force?
        odie <<~EOS
          Destination formula already exists: #{path}
          To overwrite it and continue anyways, run:
            `brew extract #{name} --version=#{version} --tap=#{destination_tap.name} --force`
        EOS
      end
      ohai "Overwriting existing formula at #{path}" if ARGV.debug?
      path.delete
    end
    ohai "Writing formula for #{name} from #{rev} to #{path}"
    path.write result
  end

  # @private
  def formula_at_revision(repo, name, file, rev)
    return if rev.empty?
    contents = Git.last_revision_of_file(repo, file, before_commit: rev)
    contents.gsub!("@url=", "url ")
    contents.gsub!("require 'brewkit'", "require 'formula'")
    Formulary.from_contents(name, file, contents)
  end
end
