require "formula"
require "formula_versions"

class Descriptions
  CACHE_FILE = HOMEBREW_CACHE + "desc_cache.json"

  def self.cache
    @cache || self.load_cache
  end

  # If the cache file exists, load it into, and return, a hash; otherwise,
  # return nil.
  def self.load_cache
    if CACHE_FILE.exist?
      @cache = Utils::JSON.load(CACHE_FILE.read)
    end
  end

  # Write the cache to disk after ensuring the existence of the containing
  # directory.
  def self.save_cache
    HOMEBREW_CACHE.mkpath
    CACHE_FILE.atomic_write Utils::JSON.dump(@cache)
  end

  # Create a hash mapping all formulae to their descriptions;
  # save it for future use.
  def self.generate_cache
    @cache = {}
    Formula.map do |f|
      @cache[f.full_name] = f.desc
    end
    self.save_cache
  end

  # Return true if the cache exists, and neither Homebrew nor any of the Taps
  # repos were updated more recently than it was.
  def self.cache_fresh?
    return false unless CACHE_FILE.exist?
    cache_mtime = File.mtime(CACHE_FILE)
    ref_master = ".git/refs/heads/master"

    master = HOMEBREW_REPOSITORY/ref_master

    # If ref_master doesn't exist, it means brew update is never run.
    # Since cache is found, we can assume it's fresh.
    if master.exist?
      core_mtime = File.mtime(master)
      return false if core_mtime > cache_mtime
    end

    Tap.each do |tap|
      next unless tap.git?
      repo_mtime = File.mtime(tap.path/ref_master)
      return false if repo_mtime > cache_mtime
    end

    true
  end

  # Create the cache if it doesn't already exist.
  def self.ensure_cache
    self.generate_cache unless self.cache_fresh? && self.cache
  end

  # Take a {Report}, as generated by cmd/update.rb.
  # Unless the cache file exists, do nothing.
  # If it does exist, but the Report is empty, just touch the cache file.
  # Otherwise, use the report to update the cache.
  def self.update_cache(report)
    if CACHE_FILE.exist?
      if report.empty?
        FileUtils.touch CACHE_FILE
      else
        renamings = report.select_formula(:R)
        alterations = report.select_formula(:A) + report.select_formula(:M) +
                      renamings.map(&:last)
        self.cache_formulae(alterations, :save => false)
        self.uncache_formulae(report.select_formula(:D) +
                              renamings.map(&:first))
      end
    end
  end

  # Given an array of formula names, add them and their descriptions to the
  # cache. Save the updated cache to disk, unless explicitly told not to.
  def self.cache_formulae(formula_names, options = { :save => true })
    if self.cache
      formula_names.each do |name|
        begin
          desc = Formulary.factory(name).desc
        rescue FormulaUnavailableError, *FormulaVersions::IGNORED_EXCEPTIONS
        end
        @cache[name] = desc
      end
      self.save_cache if options[:save]
    end
  end

  # Given an array of formula names, remove them and their descriptions from
  # the cache. Save the updated cache to disk, unless explicitly told not to.
  def self.uncache_formulae(formula_names, options = { :save => true })
    if self.cache
      formula_names.each { |name| @cache.delete(name) }
      self.save_cache if options[:save]
    end
  end

  # Given a regex, find all formulae whose specified fields contain a match.
  def self.search(regex, field = :either)
    self.ensure_cache

    results = case field
    when :name
      @cache.select { |name, _| name =~ regex }
    when :desc
      @cache.select { |_, desc| desc =~ regex }
    when :either
      @cache.select { |name, desc| (name =~ regex) || (desc =~ regex) }
    end

    results = Hash[results] if RUBY_VERSION <= "1.8.7"

    new(results)
  end

  # Create an actual instance.
  def initialize(descriptions)
    @descriptions = descriptions
  end

  # Take search results -- a hash mapping formula names to descriptions -- and
  # print them.
  def print
    blank = "#{Tty.yellow}[no description]#{Tty.reset}"
    @descriptions.keys.sort.each do |name|
      description = @descriptions[name] || blank
      puts "#{Tty.white}#{name}:#{Tty.reset} #{description}"
    end
  end
end
