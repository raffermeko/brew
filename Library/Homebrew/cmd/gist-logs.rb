#:  * `gist-logs` [`--new-issue`|`-n`] <formula>:
#:    Upload logs for a failed build of <formula> to a new Gist.
#:
#:    <formula> is usually the name of the formula to install, but it can be specified
#:    in several different ways. See [SPECIFYING FORMULAE][].
#:
#:    If `--new-issue` is passed, automatically create a new issue in the appropriate
#:    GitHub repository as well as creating the Gist.
#:
#:    If no logs are found, an error message is presented.

require "formula"
require "system_config"
require "stringio"
require "socket"

module Homebrew
  def gistify_logs(f)
    files = load_logs(f.logs)
    build_time = f.logs.ctime
    timestamp = build_time.strftime("%Y-%m-%d_%H-%M-%S")

    s = StringIO.new
    SystemConfig.dump_verbose_config s
    # Dummy summary file, asciibetically first, to control display title of gist
    files["# #{f.name} - #{timestamp}.txt"] = { :content => brief_build_info(f) }
    files["00.config.out"] = { :content => s.string }
    files["00.doctor.out"] = { :content => `brew doctor 2>&1` }
    unless f.core_formula?
      tap = <<-EOS.undent
        Formula: #{f.name}
        Tap: #{f.tap}
        Path: #{f.path}
      EOS
      files["00.tap.out"] = { :content => tap }
    end

    # Description formatted to work well as page title when viewing gist
    if f.core_formula?
      descr = "#{f.name} on #{OS_VERSION} - Homebrew build logs"
    else
      descr = "#{f.name} (#{f.full_name}) on #{OS_VERSION} - Homebrew build logs"
    end
    url = create_gist(files, descr)

    if ARGV.include?("--new-issue") || ARGV.switch?("n")
      if GitHub.api_credentials_type == :none
        puts "You can create a personal access token: https://github.com/settings/tokens"
        puts "and then set HOMEBREW_GITHUB_API_TOKEN as authentication method."
        puts
        login!
      end

      url = new_issue(f.tap, "#{f.name} failed to build on #{MacOS.full_version}", url)
    end

    puts url if url
  end

  def brief_build_info(f)
    build_time_str = f.logs.ctime.strftime("%Y-%m-%d %H:%M:%S")
    s = <<-EOS.undent
      Homebrew build logs for #{f.full_name} on #{OS_VERSION}
    EOS
    if ARGV.include?("--with-hostname")
      hostname = Socket.gethostname
      s << "Host: #{hostname}\n"
    end
    s << "Build date: #{build_time_str}\n"
    s
  end

  # Hack for ruby < 1.9.3
  def noecho_gets
    system "stty -echo"
    result = $stdin.gets
    system "stty echo"
    puts
    result
  end

  def login!
    print "GitHub User: "
    ENV["HOMEBREW_GITHUB_API_USERNAME"] = $stdin.gets.chomp
    print "Password: "
    ENV["HOMEBREW_GITHUB_API_PASSWORD"] = noecho_gets.chomp
    puts
  end

  def load_logs(dir)
    logs = {}
    dir.children.sort.each do |file|
      contents = file.size? ? file.read : "empty log"
      # small enough to avoid GitHub "unicorn" page-load-timeout errors
      max_file_size = 1_000_000
      contents = truncate_text_to_approximate_size(contents, max_file_size, :front_weight => 0.2)
      logs[file.basename.to_s] = { :content => contents }
    end if dir.exist?
    raise "No logs." if logs.empty?
    logs
  end

  def create_gist(files, description)
    data = { "public" => true, "files" => files, "description" => description }
    GitHub.open("https://api.github.com/gists", data)["html_url"]
  end

  def new_issue(repo, title, body)
    data = { "title" => title, "body" => body }
    GitHub.open("https://api.github.com/repos/#{repo}/issues", data)["html_url"]
  end

  def gist_logs
    raise FormulaUnspecifiedError if ARGV.resolved_formulae.length != 1

    gistify_logs(ARGV.resolved_formulae.first)
  end
end
