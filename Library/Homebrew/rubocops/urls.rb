# frozen_string_literal: true

require "rubocops/extend/formula"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits URLs and mirrors in Formulae.
      class Urls < FormulaCop
        # These are formulae that, sadly, require an upstream binary to bootstrap.
        BINARY_FORMULA_URLS_WHITELIST = %w[
          crystal
          fpc
          ghc
          ghc@8.2
          go
          go@1.9
          go@1.10
          go@1.11
          haskell-stack
          ldc
          mlton
          rust
        ].freeze

        # specific rust-nightly temporarily acceptable until a newer version is released.
        # DO NOT RE-ADD A NEWER RUST-NIGHTLY IN FUTURE.
        BINARY_URLS_WHITELIST = %w[
          https://static.rust-lang.org/dist/2019-08-24/rust-nightly-x86_64-apple-darwin.tar.xz
        ].freeze

        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          urls = find_every_func_call_by_name(body_node, :url)
          mirrors = find_every_func_call_by_name(body_node, :mirror)

          # GNU urls; doesn't apply to mirrors
          gnu_pattern = %r{^(?:https?|ftp)://ftpmirror.gnu.org/(.*)}
          audit_urls(urls, gnu_pattern) do |match, url|
            problem "Please use \"https://ftp.gnu.org/gnu/#{match[1]}\" instead of #{url}."
          end

          # Fossies upstream requests they aren't used as primary URLs
          # https://github.com/Homebrew/homebrew-core/issues/14486#issuecomment-307753234
          fossies_pattern = %r{^https?://fossies\.org/}
          audit_urls(urls, fossies_pattern) do
            problem "Please don't use fossies.org in the url (using as a mirror is fine)"
          end

          audit_urls(mirrors, /.*/) do |_, mirror|
            urls.each do |url|
              url_string = string_content(parameters(url).first)
              next unless url_string.eql?(mirror)

              problem "URL should not be duplicated as a mirror: #{url_string}"
            end
          end

          urls += mirrors

          # Check a variety of SSL/TLS URLs that don't consistently auto-redirect
          # or are overly common errors that need to be reduced & fixed over time.
          http_to_https_patterns = Regexp.union([%r{^http://ftp\.gnu\.org/},
                                                 %r{^http://ftpmirror\.gnu\.org/},
                                                 %r{^http://download\.savannah\.gnu\.org/},
                                                 %r{^http://download-mirror\.savannah\.gnu\.org/},
                                                 %r{^http://[^/]*\.apache\.org/},
                                                 %r{^http://code\.google\.com/},
                                                 %r{^http://fossies\.org/},
                                                 %r{^http://mirrors\.kernel\.org/},
                                                 %r{^http://mirrors\.ocf\.berkeley\.edu/},
                                                 %r{^http://(?:[^/]*\.)?bintray\.com/},
                                                 %r{^http://tools\.ietf\.org/},
                                                 %r{^http://launchpad\.net/},
                                                 %r{^http://github\.com/},
                                                 %r{^http://bitbucket\.org/},
                                                 %r{^http://anonscm\.debian\.org/},
                                                 %r{^http://cpan\.metacpan\.org/},
                                                 %r{^http://hackage\.haskell\.org/},
                                                 %r{^http://(?:[^/]*\.)?archive\.org},
                                                 %r{^http://(?:[^/]*\.)?freedesktop\.org},
                                                 %r{^http://(?:[^/]*\.)?mirrorservice\.org/}])
          audit_urls(urls, http_to_https_patterns) do |_, url|
            problem "Please use https:// for #{url}"
          end

          cpan_pattern = %r{^http://search\.mcpan\.org/CPAN/(.*)}i
          audit_urls(urls, cpan_pattern) do |match, url|
            problem "#{url} should be `https://cpan.metacpan.org/#{match[1]}`"
          end

          gnome_pattern = %r{^(http|ftp)://ftp\.gnome\.org/pub/gnome/(.*)}i
          audit_urls(urls, gnome_pattern) do |match, url|
            problem "#{url} should be `https://download.gnome.org/#{match[2]}`"
          end

          debian_pattern = %r{^git://anonscm\.debian\.org/users/(.*)}i
          audit_urls(urls, debian_pattern) do |match, url|
            problem "#{url} should be `https://anonscm.debian.org/git/users/#{match[1]}`"
          end

          # Prefer HTTP/S when possible over FTP protocol due to possible firewalls.
          mirror_service_pattern = %r{^ftp://ftp\.mirrorservice\.org}
          audit_urls(urls, mirror_service_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          cpan_ftp_pattern = %r{^ftp://ftp\.cpan\.org/pub/CPAN(.*)}i
          audit_urls(urls, cpan_ftp_pattern) do |match_obj, url|
            problem "#{url} should be `http://search.cpan.org/CPAN#{match_obj[1]}`"
          end

          # SourceForge url patterns
          sourceforge_patterns = %r{^https?://.*\b(sourceforge|sf)\.(com|net)}
          audit_urls(urls, sourceforge_patterns) do |_, url|
            # Skip if the URL looks like a SVN repo
            next if url.include? "/svnroot/"
            next if url.include? "svn.sourceforge"
            next if url.include? "/p/"

            if url =~ /(\?|&)use_mirror=/
              problem "Don't use #{Regexp.last_match(1)}use_mirror in SourceForge urls (url is #{url})."
            end

            problem "Don't use /download in SourceForge urls (url is #{url})." if url.end_with?("/download")

            if url =~ %r{^https?://sourceforge\.}
              problem "Use https://downloads.sourceforge.net to get geolocation (url is #{url})."
            end

            if url =~ %r{^https?://prdownloads\.}
              problem <<~EOS.chomp
                Don't use prdownloads in SourceForge urls (url is #{url}).
                        See: http://librelist.com/browser/homebrew/2011/1/12/prdownloads-is-bad/
              EOS
            end

            if url =~ %r{^http://\w+\.dl\.}
              problem "Don't use specific dl mirrors in SourceForge urls (url is #{url})."
            end

            problem "Please use https:// for #{url}" if url.start_with? "http://downloads"
          end

          # Debian has an abundance of secure mirrors. Let's not pluck the insecure
          # one out of the grab bag.
          unsecure_deb_pattern = %r{^http://http\.debian\.net/debian/(.*)}i
          audit_urls(urls, unsecure_deb_pattern) do |match, _|
            problem <<~EOS
              Please use a secure mirror for Debian URLs.
              We recommend:
                https://deb.debian.org/debian/#{match[1]}
            EOS
          end

          # Check to use canonical urls for Debian packages
          noncanon_deb_pattern =
            Regexp.union([%r{^https://mirrors\.kernel\.org/debian/},
                          %r{^https://mirrors\.ocf\.berkeley\.edu/debian/},
                          %r{^https://(?:[^/]*\.)?mirrorservice\.org/sites/ftp\.debian\.org/debian/}])
          audit_urls(urls, noncanon_deb_pattern) do |_, url|
            problem "Please use https://deb.debian.org/debian/ for #{url}"
          end

          # Check for new-url Google Code download urls, https:// is preferred
          google_code_pattern = Regexp.union([%r{^http://.*\.googlecode\.com/files.*},
                                              %r{^http://code\.google\.com/}])
          audit_urls(urls, google_code_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          # Check for git:// GitHub repo urls, https:// is preferred.
          git_gh_pattern = %r{^git://[^/]*github\.com/}
          audit_urls(urls, git_gh_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          # Check for git:// Gitorious repo urls, https:// is preferred.
          git_gitorious_pattern = %r{^git://[^/]*gitorious\.org/}
          audit_urls(urls, git_gitorious_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          # Check for http:// GitHub repo urls, https:// is preferred.
          gh_pattern = %r{^http://github\.com/.*\.git$}
          audit_urls(urls, gh_pattern) do |_, url|
            problem "Please use https:// for #{url}"
          end

          # Check for master branch GitHub archives.
          tarball_gh_pattern = %r{^https://github\.com/.*archive/master\.(tar\.gz|zip)$}
          audit_urls(urls, tarball_gh_pattern) do
            problem "Use versioned rather than branch tarballs for stable checksums."
          end

          # Use new-style archive downloads
          archive_gh_pattern = %r{https://.*github.*/(?:tar|zip)ball/}
          audit_urls(urls, archive_gh_pattern) do |_, url|
            next unless url !~ /\.git$/

            problem "Use /archive/ URLs for GitHub tarballs (url is #{url})."
          end

          # Don't use GitHub .zip files
          zip_gh_pattern = %r{https://.*github.*/(archive|releases)/.*\.zip$}
          audit_urls(urls, zip_gh_pattern) do |_, url|
            next unless url !~ %r{releases/download}

            problem "Use GitHub tarballs rather than zipballs (url is #{url})."
          end

          # Don't use GitHub codeload URLs
          codeload_gh_pattern = %r{https?://codeload\.github\.com/(.+)/(.+)/(?:tar\.gz|zip)/(.+)}
          audit_urls(urls, codeload_gh_pattern) do |match, url|
            problem <<~EOS
              Use GitHub archive URLs:
                https://github.com/#{match[1]}/#{match[2]}/archive/#{match[3]}.tar.gz
              Rather than codeload:
                #{url}
            EOS
          end

          # Check for Maven Central urls, prefer HTTPS redirector over specific host
          maven_pattern = %r{https?://(?:central|repo\d+)\.maven\.org/maven2/(.+)$}
          audit_urls(urls, maven_pattern) do |match, url|
            problem "#{url} should be `https://search.maven.org/remotecontent?filepath=#{match[1]}`"
          end

          return if formula_tap != "homebrew-core"

          # Check for binary URLs
          audit_urls(urls, /(darwin|macos|osx)/i) do |_, url|
            next if url !~ /x86_64/i && url !~ /amd64/i
            next if BINARY_FORMULA_URLS_WHITELIST.include?(@formula_name)
            next if BINARY_URLS_WHITELIST.include?(url)

            problem "#{url} looks like a binary package, not a source archive. " \
                    "Homebrew/homebrew-core is source-only."
          end
        end
      end

      class PyPiUrls < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          urls = find_every_func_call_by_name(body_node, :url)
          mirrors = find_every_func_call_by_name(body_node, :mirror)
          urls += mirrors

          # Check pypi urls
          @pypi_pattern = %r{^https?://pypi.python.org/(.*)}
          audit_urls(urls, @pypi_pattern) do |match, url|
            problem "#{url} should be `https://files.pythonhosted.org/#{match[1]}`"
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            url_string_node = parameters(node).first
            url = string_content(url_string_node)
            match = regex_match_group(url_string_node, @pypi_pattern)
            correction = node.source.sub(url, "https://files.pythonhosted.org/#{match[1]}")
            corrector.insert_before(node.source_range, correction)
            corrector.remove(node.source_range)
          end
        end
      end
    end
  end
end
