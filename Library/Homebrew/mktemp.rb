# typed: false
# frozen_string_literal: true

# Performs {Formula#mktemp}'s functionality, and tracks the results.
# Each instance is only intended to be used once.
class Mktemp
  extend T::Sig

  include FileUtils

  # Path to the tmpdir used in this run, as a {Pathname}.
  attr_reader :tmpdir

  def initialize(prefix, opts = {})
    @prefix = prefix
    @retain_in_sources = opts[:retain_in_sources]
    @retain = opts[:retain] || @retain_in_sources
    @quiet = false
  end

  # Instructs this {Mktemp} to retain the staged files.
  sig { void }
  def retain!
    @retain = true
  end

  # True if the staged temporary files should be retained.
  def retain?
    @retain
  end

  # True if the source files should be retained.
  def retain_in_sources?
    @retain_in_sources
  end

  # Instructs this Mktemp to not emit messages when retention is triggered.
  sig { void }
  def quiet!
    @quiet = true
  end

  sig { returns(String) }
  def to_s
    "[Mktemp: #{tmpdir} retain=#{@retain} quiet=#{@quiet}]"
  end

  def run
    if @retain_in_sources
      source_dir = "#{HOMEBREW_CACHE}/Sources/#{@prefix.tr "@", "AT"}"
      chmod_rm_rf(source_dir) # clear out previous (otherwise not sure what happens)
      FileUtils.mkdir_p(source_dir)
      @tmpdir = Pathname.new(source_dir)
    else
      @tmpdir = Pathname.new(Dir.mktmpdir("#{@prefix.tr "@", "AT"}-", HOMEBREW_TEMP))
    end

    # Make sure files inside the temporary directory have the same group as the
    # brew instance.
    #
    # Reference from `man 2 open`
    # > When a new file is created, it is given the group of the directory which
    # contains it.
    group_id = if HOMEBREW_BREW_FILE.grpowned?
      HOMEBREW_BREW_FILE.stat.gid
    else
      Process.gid
    end
    begin
      chown(nil, group_id, tmpdir)
    rescue Errno::EPERM
      opoo "Failed setting group \"#{Etc.getgrgid(group_id).name}\" on #{tmpdir}"
    end

    begin
      Dir.chdir(tmpdir) { yield self }
    ensure
      ignore_interrupts { chmod_rm_rf(tmpdir) } unless retain?
    end
  ensure
    if retain? && !@tmpdir.nil? && !@quiet
      message = retain_in_sources? ? "Source files for debugging available at:" : "Temporary files retained at:"
      ohai message, @tmpdir.to_s
    end
  end

  private

  def chmod_rm_rf(path)
    if path.directory? && !path.symlink?
      chmod("u+rw", path) if path.owned? # Need permissions in order to see the contents
      path.children.each { |child| chmod_rm_rf(child) }
      rmdir(path)
    else
      rm_f(path)
    end
  rescue
    nil # Just skip this directory.
  end
end
