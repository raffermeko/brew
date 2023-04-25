# typed: true
# frozen_string_literal: true

# Helper functions for updating PyPI resources.
#
# @api private
module PyPI
  extend T::Sig

  PYTHONHOSTED_URL_PREFIX = "https://files.pythonhosted.org/packages/"
  private_constant :PYTHONHOSTED_URL_PREFIX

  # PyPI Package
  #
  # @api private
  class Package
    extend T::Sig

    attr_accessor :name, :extras, :version

    sig { params(package_string: String, is_url: T::Boolean).void }
    def initialize(package_string, is_url: false)
      @pypi_info = nil

      if is_url
        match = if package_string.start_with?(PYTHONHOSTED_URL_PREFIX)
          File.basename(package_string).match(/^(.+)-([a-z\d.]+?)(?:.tar.gz|.zip)$/)
        end
        raise ArgumentError, "Package should be a valid PyPI URL" if match.blank?

        @name = PyPI.normalize_python_package(match[1])
        @version = match[2]
        return
      end

      if package_string.include? "=="
        @name, @version = package_string.split("==")
      else
        @name = package_string
      end

      return unless (match = T.must(@name).match(/^(.*?)\[(.+)\]$/))

      @name = match[1]
      @extras = T.must(match[2]).split ","
    end

    # Get name, URL, SHA-256 checksum, and latest version for a given PyPI package.
    sig { params(version: T.nilable(T.any(String, Version))).returns(T.nilable(T::Array[String])) }
    def pypi_info(version: nil)
      return @pypi_info if @pypi_info.present? && version.blank?

      version ||= @version
      metadata_url = if version.present?
        "https://pypi.org/pypi/#{@name}/#{version}/json"
      else
        "https://pypi.org/pypi/#{@name}/json"
      end
      out, _, status = curl_output metadata_url, "--location", "--fail"

      return unless status.success?

      begin
        json = JSON.parse out
      rescue JSON::ParserError
        return
      end

      sdist = json["urls"].find { |url| url["packagetype"] == "sdist" }
      return json["info"]["name"] if sdist.nil?

      @pypi_info = [json["info"]["name"], sdist["url"], sdist["digests"]["sha256"], json["info"]["version"]]
    end

    sig { returns(T::Boolean) }
    def valid_pypi_package?
      info = pypi_info
      info.present? && info.is_a?(Array)
    end

    sig { returns(String) }
    def to_s
      out = @name
      out += "[#{@extras.join(",")}]" if @extras.present?
      out += "==#{@version}" if @version.present?
      out
    end

    sig { params(other: Package).returns(T::Boolean) }
    def same_package?(other)
      T.must(@name.tr("_", "-").casecmp(other.name.tr("_", "-"))).zero?
    end

    # Compare only names so we can use .include? and .uniq on a Package array
    sig { params(other: Package).returns(T::Boolean) }
    def ==(other)
      same_package?(other)
    end
    alias eql? ==

    sig { returns(Integer) }
    def hash
      @name.tr("_", "-").downcase.hash
    end

    sig { params(other: Package).returns(T.nilable(Integer)) }
    def <=>(other)
      @name <=> other.name
    end
  end

  sig { params(url: String, version: T.any(String, Version)).returns(T.nilable(String)) }
  def self.update_pypi_url(url, version)
    package = Package.new url, is_url: true

    return unless package.valid_pypi_package?

    _, url = package.pypi_info(version: version)
    url
  rescue ArgumentError
    nil
  end

  # Return true if resources were checked (even if no change).
  sig {
    params(
      formula:                  Formula,
      version:                  T.nilable(String),
      package_name:             T.nilable(String),
      extra_packages:           T.nilable(T::Array[String]),
      exclude_packages:         T.nilable(T::Array[String]),
      print_only:               T.nilable(T::Boolean),
      silent:                   T.nilable(T::Boolean),
      ignore_non_pypi_packages: T.nilable(T::Boolean),
    ).returns(T.nilable(T::Boolean))
  }
  def self.update_python_resources!(formula, version: nil, package_name: nil, extra_packages: nil,
                                    exclude_packages: nil, print_only: false, silent: false,
                                    ignore_non_pypi_packages: false)

    auto_update_list = formula.tap&.pypi_formula_mappings
    if auto_update_list.present? && auto_update_list.key?(formula.full_name) &&
       package_name.blank? && extra_packages.blank? && exclude_packages.blank?

      list_entry = auto_update_list[formula.full_name]
      case list_entry
      when false
        unless print_only
          odie "The resources for \"#{formula.name}\" need special attention. Please update them manually."
        end
      when String
        package_name = list_entry
      when Hash
        package_name = list_entry["package_name"]
        extra_packages = list_entry["extra_packages"]
        exclude_packages = list_entry["exclude_packages"]
      end
    end

    main_package = if package_name.present?
      Package.new(package_name)
    else
      begin
        Package.new(formula.stable.url, is_url: true)
      rescue ArgumentError
        nil
      end
    end

    if main_package.blank?
      return if ignore_non_pypi_packages

      odie <<~EOS
        Could not infer PyPI package name from URL:
          #{Formatter.url(formula.stable.url)}
      EOS
    end

    unless main_package.valid_pypi_package?
      return if ignore_non_pypi_packages

      odie "\"#{main_package}\" is not available on PyPI."
    end

    main_package.version = version if version.present?

    extra_packages = (extra_packages || []).map { |p| Package.new p }
    exclude_packages = (exclude_packages || []).map { |p| Package.new p }
    exclude_packages += %W[#{main_package.name} argparse pip setuptools wsgiref].map { |p| Package.new p }
    # remove packages from the exclude list if we've explicitly requested them as an extra package
    exclude_packages.delete_if { |package| extra_packages.include?(package) }

    input_packages = [main_package]
    extra_packages.each do |extra_package|
      if !extra_package.valid_pypi_package? && !ignore_non_pypi_packages
        odie "\"#{extra_package}\" is not available on PyPI."
      end

      input_packages.each do |existing_package|
        if existing_package.same_package?(extra_package) && existing_package.version != extra_package.version
          odie "Conflicting versions specified for the `#{extra_package.name}` package: " \
               "#{existing_package.version}, #{extra_package.version}"
        end
      end

      input_packages << extra_package unless input_packages.include? extra_package
    end

    formula.resources.each do |resource|
      if !print_only && !resource.url.start_with?(PYTHONHOSTED_URL_PREFIX)
        odie "\"#{formula.name}\" contains non-PyPI resources. Please update the resources manually."
      end
    end

    ensure_formula_installed!("python")

    ohai "Retrieving PyPI dependencies for \"#{input_packages.join(" ")}\"..." if !print_only && !silent
    command =
      [Formula["python"].bin/"python3", "-m", "pip", "install", "-q", "--dry-run", "--ignore-installed", "--report",
       "/dev/stdout", *input_packages.map(&:to_s)]
    pip_output = Utils.popen_read({ "PIP_REQUIRE_VIRTUALENV" => "false" }, *command)
    unless $CHILD_STATUS.success?
      odie <<~EOS
        Unable to determine dependencies for "#{input_packages.join(" ")}" because of a failure when running
        `#{command.join(" ")}`.
        Please update the resources for "#{formula.name}" manually.
      EOS
    end

    found_packages = pip_report_to_packages(JSON.parse(pip_output), exclude_packages).uniq

    new_resource_blocks = ""
    found_packages.sort.each do |package|
      if exclude_packages.include? package
        ohai "Excluding \"#{package}\"" if !print_only && !silent
        next
      end

      ohai "Getting PyPI info for \"#{package}\"" if !print_only && !silent
      name, url, checksum = package.pypi_info
      # Fail if unable to find name, url or checksum for any resource
      if name.blank?
        odie "Unable to resolve some dependencies. Please update the resources for \"#{formula.name}\" manually."
      elsif url.blank? || checksum.blank?
        odie <<~EOS
          Unable to find the URL and/or sha256 for the "#{name}" resource.
          Please update the resources for "#{formula.name}" manually.
        EOS
      end

      # Append indented resource block
      new_resource_blocks += <<-EOS
  resource "#{name}" do
    url "#{url}"
    sha256 "#{checksum}"
  end

      EOS
    end

    if print_only
      puts new_resource_blocks.chomp
      return
    end

    # Check whether resources already exist (excluding virtualenv dependencies)
    if formula.resources.all? { |resource| resource.name.start_with?("homebrew-") }
      # Place resources above install method
      inreplace_regex = /  def install/
      new_resource_blocks += "  def install"
    else
      # Replace existing resource blocks with new resource blocks
      inreplace_regex = /  (resource .* do\s+url .*\s+sha256 .*\s+ end\s*)+/
      new_resource_blocks += "  "
    end

    ohai "Updating resource blocks" unless silent
    Utils::Inreplace.inreplace formula.path do |s|
      if s.inreplace_string.scan(inreplace_regex).length > 1
        odie "Unable to update resource blocks for \"#{formula.name}\" automatically. Please update them manually."
      end
      s.sub! inreplace_regex, new_resource_blocks
    end

    true
  end

  def self.normalize_python_package(name)
    name.gsub(/[-_.]+/, "-").downcase
  end

  def self.pip_report_to_packages(report, exclude_packages)
    return [] if report.blank?

    report["install"].map do |package|
      name = normalize_python_package(package["metadata"]["name"])
      version = package["metadata"]["version"]

      package = Package.new "#{name}==#{version}"

      package if exclude_packages.exclude? package
    end.compact
  end
end
