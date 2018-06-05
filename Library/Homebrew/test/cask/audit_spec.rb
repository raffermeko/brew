describe Hbc::Audit, :cask do
  def include_msg?(messages, msg)
    if msg.is_a?(Regexp)
      Array(messages).any? { |m| m =~ msg }
    else
      Array(messages).include?(msg)
    end
  end

  matcher :pass do
    match do |audit|
      !audit.errors? && !audit.warnings?
    end
  end

  matcher :fail do
    match(&:errors?)
  end

  matcher :warn do
    match do |audit|
      audit.warnings? && !audit.errors?
    end
  end

  matcher :fail_with do |error_msg|
    match do |audit|
      include_msg?(audit.errors, error_msg)
    end
  end

  matcher :warn_with do |warning_msg|
    match do |audit|
      include_msg?(audit.warnings, warning_msg)
    end
  end

  let(:cask) { instance_double(Hbc::Cask) }
  let(:download) { false }
  let(:check_token_conflicts) { false }
  let(:fake_system_command) { class_double(Hbc::SystemCommand) }
  let(:audit) {
    Hbc::Audit.new(cask, download:              download,
                         check_token_conflicts: check_token_conflicts,
                         command:               fake_system_command)
  }

  describe "#result" do
    subject { audit.result }

    context "when there are errors" do
      before do
        audit.add_error "bad"
      end

      it { is_expected.to match(/failed/) }
    end

    context "when there are warnings" do
      before do
        audit.add_warning "eh"
      end

      it { is_expected.to match(/warning/) }
    end

    context "when there are errors and warnings" do
      before do
        audit.add_error "bad"
        audit.add_warning "eh"
      end

      it { is_expected.to match(/failed/) }
    end

    context "when there are no errors or warnings" do
      it { is_expected.to match(/passed/) }
    end
  end

  describe "#run!" do
    subject { audit.run! }

    let(:cask) { Hbc::CaskLoader.load(cask_token) }

    describe "required stanzas" do
      %w[version sha256 url name homepage].each do |stanza|
        context "when missing #{stanza}" do
          let(:cask_token) { "missing-#{stanza}" }

          it { is_expected.to fail_with(/#{stanza} stanza is required/) }
        end
      end
    end

    describe "pkg allow_untrusted checks" do
      let(:error_msg) { "allow_untrusted is not permitted in official Homebrew-Cask taps" }

      context "when the Cask has no pkg stanza" do
        let(:cask_token) { "basic-cask" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask does not have allow_untrusted" do
        let(:cask_token) { "with-uninstall-pkgutil" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has allow_untrusted" do
        let(:cask_token) { "with-allow-untrusted" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "when the Cask stanza requires uninstall" do
      let(:error_msg) { "installer and pkg stanzas require an uninstall stanza" }

      context "when the Cask does not require an uninstall" do
        let(:cask_token) { "basic-cask" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the pkg Cask has an uninstall" do
        let(:cask_token) { "with-uninstall-pkgutil" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the installer Cask has an uninstall" do
        let(:cask_token) { "installer-with-uninstall" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the installer Cask does not have an uninstall" do
        let(:cask_token) { "with-installer-manual" }

        it { is_expected.to warn_with(error_msg) }
      end

      context "when the pkg Cask does not have an uninstall" do
        let(:cask_token) { "pkg-without-uninstall" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "preflight stanza checks" do
      let(:error_msg) { "only a single preflight stanza is allowed" }

      context "when the Cask has no preflight stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has only one preflight stanza" do
        let(:cask_token) { "with-preflight" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has multiple preflight stanzas" do
        let(:cask_token) { "with-preflight-multi" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "uninstall_postflight stanza checks" do
      let(:error_msg) { "only a single postflight stanza is allowed" }

      context "when the Cask has no postflight stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has only one postflight stanza" do
        let(:cask_token) { "with-postflight" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has multiple postflight stanzas" do
        let(:cask_token) { "with-postflight-multi" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "uninstall stanza checks" do
      let(:error_msg) { "only a single uninstall stanza is allowed" }

      context "when the Cask has no uninstall stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has only one uninstall stanza" do
        let(:cask_token) { "with-uninstall-rmdir" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has multiple uninstall stanzas" do
        let(:cask_token) { "with-uninstall-multi" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "uninstall_preflight stanza checks" do
      let(:error_msg) { "only a single uninstall_preflight stanza is allowed" }

      context "when the Cask has no uninstall_preflight stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has only one uninstall_preflight stanza" do
        let(:cask_token) { "with-uninstall-preflight" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has multiple uninstall_preflight stanzas" do
        let(:cask_token) { "with-uninstall-preflight-multi" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "uninstall_postflight stanza checks" do
      let(:error_msg) { "only a single uninstall_postflight stanza is allowed" }

      context "when the Cask has no uninstall_postflight stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has only one uninstall_postflight stanza" do
        let(:cask_token) { "with-uninstall-postflight" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has multiple uninstall_postflight stanzas" do
        let(:cask_token) { "with-uninstall-postflight-multi" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "zap stanza checks" do
      let(:error_msg) { "only a single zap stanza is allowed" }

      context "when the Cask has no zap stanza" do
        let(:cask_token) { "with-uninstall-rmdir" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has only one zap stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask has multiple zap stanzas" do
        let(:cask_token) { "with-zap-multi" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "version checks" do
      let(:error_msg) { "you should use version :latest instead of version 'latest'" }

      context "when version is 'latest'" do
        let(:cask_token) { "version-latest-string" }

        it { is_expected.to fail_with(error_msg) }
      end

      context "when version is :latest" do
        let(:cask_token) { "version-latest-with-checksum" }

        it { is_expected.not_to fail_with(error_msg) }
      end
    end

    describe "sha256 checks" do
      context "when version is :latest and sha256 is not :no_check" do
        let(:cask_token) { "version-latest-with-checksum" }

        it { is_expected.to fail_with("you should use sha256 :no_check when version is :latest") }
      end

      context "when sha256 is not a legal SHA-256 digest" do
        let(:cask_token) { "invalid-sha256" }

        it { is_expected.to fail_with("sha256 string must be of 64 hexadecimal characters") }
      end

      context "when sha256 is sha256 for empty string" do
        let(:cask_token) { "sha256-for-empty-string" }

        it { is_expected.to fail_with(/cannot use the sha256 for an empty string/) }
      end
    end

    describe "appcast checks" do
      context "when appcast has no sha256" do
        let(:cask_token) { "appcast-missing-checkpoint" }

        it { is_expected.to fail_with(/checkpoint sha256 is required for appcast/) }
      end

      context "when appcast checkpoint is not a string of 64 hexadecimal characters" do
        let(:cask_token) { "appcast-invalid-checkpoint" }

        it { is_expected.to fail_with(/string must be of 64 hexadecimal characters/) }
      end

      context "when appcast checkpoint is sha256 for empty string" do
        let(:cask_token) { "appcast-checkpoint-sha256-for-empty-string" }

        it { is_expected.to fail_with(/cannot use the sha256 for an empty string/) }
      end

      context "when appcast checkpoint is valid sha256" do
        let(:cask_token) { "appcast-valid-checkpoint" }

        it { is_expected.not_to fail_with(/appcast :checkpoint/) }
      end

      context "when verifying appcast HTTP code" do
        let(:cask_token) { "appcast-valid-checkpoint" }
        let(:download) { instance_double(Hbc::Download) }
        let(:wrong_code_msg) { /unexpected HTTP response code/ }
        let(:curl_error_msg) { /error retrieving appcast/ }
        let(:fake_curl_result) { instance_double(Hbc::SystemCommand::Result) }

        before do
          allow(audit).to receive(:check_appcast_checkpoint_accuracy)
          allow(fake_system_command).to receive(:run).and_return(fake_curl_result)
          allow(fake_curl_result).to receive(:success?).and_return(success)
        end

        context "when curl succeeds" do
          let(:success) { true }

          before do
            allow(fake_curl_result).to receive(:stdout).and_return(stdout)
          end

          context "when HTTP code is 200" do
            let(:stdout) { "200" }

            it { is_expected.not_to warn_with(wrong_code_msg) }
          end

          context "when HTTP code is not 200" do
            let(:stdout) { "404" }

            it { is_expected.to warn_with(wrong_code_msg) }
          end
        end

        context "when curl fails" do
          let(:success) { false }

          before do
            allow(fake_curl_result).to receive(:stderr).and_return("Some curl error")
          end

          it { is_expected.to warn_with(curl_error_msg) }
        end
      end

      context "when verifying appcast checkpoint" do
        let(:cask_token) { "appcast-valid-checkpoint" }
        let(:download) { instance_double(Hbc::Download) }
        let(:mismatch_msg) { /appcast checkpoint mismatch/ }
        let(:curl_error_msg) { /error retrieving appcast/ }
        let(:fake_curl_result) { instance_double(Hbc::SystemCommand::Result) }
        let(:expected_checkpoint) { "d5b2dfbef7ea28c25f7a77cd7fa14d013d82b626db1d82e00e25822464ba19e2" }

        before do
          allow(audit).to receive(:check_appcast_http_code)
          allow(Hbc::SystemCommand).to receive(:run).and_return(fake_curl_result)
          allow(fake_curl_result).to receive(:success?).and_return(success)
        end

        context "when appcast download succeeds" do
          let(:success) { true }
          let(:appcast_text) { instance_double(::String) }

          before do
            allow(fake_curl_result).to receive(:stdout).and_return(appcast_text)
            allow(appcast_text).to receive(:gsub).and_return(appcast_text)
            allow(appcast_text).to receive(:end_with?).with("\n").and_return(true)
            allow(Digest::SHA2).to receive(:hexdigest).and_return(actual_checkpoint)
          end

          context "when appcast checkpoint is out of date" do
            let(:actual_checkpoint) { "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef" }

            it { is_expected.to warn_with(mismatch_msg) }
            it { is_expected.not_to warn_with(curl_error_msg) }
          end

          context "when appcast checkpoint is up to date" do
            let(:actual_checkpoint) { expected_checkpoint }

            it { is_expected.not_to warn_with(mismatch_msg) }
            it { is_expected.not_to warn_with(curl_error_msg) }
          end
        end

        context "when appcast download fails" do
          let(:success) { false }

          before do
            allow(fake_curl_result).to receive(:stderr).and_return("Some curl error")
          end

          it { is_expected.to warn_with(curl_error_msg) }
        end
      end
    end

    describe "GitHub releases appcast check" do
      let(:error_msg) { /Cask uses GitHub releases/ }

      context "when the Cask does not use GitHub releases" do
        let(:cask_token) { "basic-cask" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask uses GitHub releases and has an appcast" do
        let(:cask_token) { "github-with-appcast" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask uses GitHub releases and does not have an appcast" do
        let(:cask_token) { "github-without-appcast" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "SourceForge appcast check" do
      let(:error_msg) { /Cask hosted on SourceForge/ }

      context "when the Cask is not hosted on SourceForge" do
        let(:cask_token) { "basic-cask" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask is hosted on SourceForge and has an appcast" do
        let(:cask_token) { "sourceforge-with-appcast" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask is hosted on SourceForge and does not have an appcast" do
        let(:cask_token) { "sourceforge-correct-url-format" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "latest with appcast checks" do
      let(:error_msg) { "Casks with an appcast should not use version :latest" }

      context "when the Cask is :latest and does not have an appcast" do
        let(:cask_token) { "version-latest" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask is versioned and has an appcast" do
        let(:cask_token) { "with-appcast" }

        it { is_expected.not_to warn_with(error_msg) }
      end

      context "when the Cask is :latest and has an appcast" do
        let(:cask_token) { "latest-with-appcast" }

        it { is_expected.to warn_with(error_msg) }
      end
    end

    describe "preferred download URL formats" do
      let(:warning_msg) { /URL format incorrect/ }

      context "with incorrect SourceForge URL format" do
        let(:cask_token) { "sourceforge-incorrect-url-format" }

        it { is_expected.to warn_with(warning_msg) }
      end

      context "with correct SourceForge URL format" do
        let(:cask_token) { "sourceforge-correct-url-format" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "with correct SourceForge URL format for version :latest" do
        let(:cask_token) { "sourceforge-version-latest-correct-url-format" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "with incorrect OSDN URL format" do
        let(:cask_token) { "osdn-incorrect-url-format" }

        it { is_expected.to warn_with(warning_msg) }
      end

      context "with correct OSDN URL format" do
        let(:cask_token) { "osdn-correct-url-format" }

        it { is_expected.not_to warn_with(warning_msg) }
      end
    end

    describe "generic artifact checks" do
      context "with relative target" do
        let(:cask_token) { "generic-artifact-relative-target" }

        it { is_expected.to fail_with(/target must be absolute path for Generic Artifact/) }
      end

      context "with absolute target" do
        let(:cask_token) { "generic-artifact-absolute-target" }

        it { is_expected.not_to fail_with(/target required for Generic Artifact/) }
      end
    end

    describe "url checks" do
      context "given a block" do
        let(:cask_token) { "booby-trap" }

        context "when loading the cask" do
          it "does not evaluate the block" do
            expect { cask }.not_to raise_error
          end
        end

        context "when doing the audit" do
          it "evaluates the block" do
            expect(subject).to fail_with(/Boom/)
          end
        end
      end
    end

    describe "token conflicts" do
      let(:cask_token) { "with-binary" }
      let(:check_token_conflicts) { true }

      before do
        expect(audit).to receive(:core_formula_names).and_return(formula_names)
      end

      context "when cask token conflicts with a core formula" do
        let(:formula_names) { %w[with-binary other-formula] }

        it { is_expected.to warn_with(/possible duplicate/) }
      end

      context "when cask token does not conflict with a core formula" do
        let(:formula_names) { %w[other-formula] }

        it { is_expected.not_to warn_with(/possible duplicate/) }
      end
    end

    describe "audit of downloads" do
      let(:cask_token) { "with-binary" }
      let(:cask) { Hbc::CaskLoader.load(cask_token) }
      let(:download) { instance_double(Hbc::Download) }
      let(:verify) { class_double(Hbc::Verify).as_stubbed_const }
      let(:error_msg) { "Download Failed" }

      context "when download and verification succeed" do
        before do
          expect(download).to receive(:perform)
          expect(verify).to receive(:all)
        end

        it { is_expected.not_to fail_with(/#{error_msg}/) }
      end

      context "when download fails" do
        before do
          expect(download).to receive(:perform).and_raise(StandardError.new(error_msg))
        end

        it { is_expected.to fail_with(/#{error_msg}/) }
      end

      context "when verification fails" do
        before do
          expect(download).to receive(:perform)
          expect(verify).to receive(:all).and_raise(StandardError.new(error_msg))
        end

        it { is_expected.to fail_with(/#{error_msg}/) }
      end
    end

    context "when an exception is raised" do
      let(:cask) { instance_double(Hbc::Cask) }

      before do
        expect(cask).to receive(:version).and_raise(StandardError.new)
      end

      it { is_expected.to fail_with(/exception while auditing/) }
    end
  end
end
