require "formula"
require "blacklist"

module Homebrew extend self
  def search
    if ARGV.include? '--macports'
      exec "open", "http://www.macports.org/ports.php?by=name&substr=#{ARGV.next}"
    elsif ARGV.include? '--fink'
      exec "open", "http://pdb.finkproject.org/pdb/browse.php?summary=#{ARGV.next}"
    else
      query = ARGV.first
      rx = case query
      when nil then ""
      when %r{^/(.*)/$} then Regexp.new($1)
      else
        /.*#{Regexp.escape query}.*/i
      end

      search_results = search_brews rx
      puts_columns search_results

      if not query.to_s.empty? and $stdout.tty? and msg = blacklisted?(query)
        unless search_results.empty?
          puts
          puts "If you meant `#{query}' precisely:"
          puts
        end
        puts msg
      end

      $found = search_results.length
      puts_columns search_tap "adamv", "alt", rx
      puts_columns search_tap "josegonzalez", "php", rx
      puts_columns search_tap "Homebrew", "versions", rx
      puts_columns search_tap "Homebrew", "dupes", rx

      if $found == 0 and not blacklisted? query
        puts "No formula found for \"#{query}\". Searching open pull requests..."
        GitHub.find_pull_requests(rx) { |pull| puts pull }
      end
    end
  end

  def search_tap user, repo, rx
    return [] if (HOMEBREW_LIBRARY/"Taps/#{user}-#{repo}").directory?

    require 'open-uri'
    require 'yaml'

    results = []
    open "http://github.com/api/v2/yaml/blob/all/#{user}/homebrew-#{repo}/master" do |f|
      user.downcase! if user == "Homebrew" # special handling for the Homebrew organization
      YAML::load(f.read)["blobs"].each do |file, _|
        name = File.basename(file, '.rb')
        if file =~ /\.rb$/ and name =~ rx
          results << "#{user}/#{repo}/#{name}"
          $found += 1
        end
      end
    end
    results
  rescue
    []
  end

  def search_brews rx
    if rx.to_s.empty?
      Formula.names
    else
      aliases = Formula.aliases
      results = (Formula.names+aliases).grep rx

      # Filter out aliases when the full name was also found
      results.reject do |alias_name|
        if aliases.include? alias_name
          resolved_name = (HOMEBREW_REPOSITORY+"Library/Aliases"+alias_name).readlink.basename('.rb').to_s
          results.include? resolved_name
        end
      end
    end
  end
end
