require "integration_cmds_tests"

class IntegrationCommandTestReinstallPinned < IntegrationCommandTests
  def test_reinstall_pinned
    setup_test_formula "testball"

    HOMEBREW_CELLAR.join("testball/0.1").mkpath
    HOMEBREW_PINNED_KEGS.mkpath
    FileUtils.ln_s HOMEBREW_CELLAR.join("testball/0.1"), HOMEBREW_PINNED_KEGS/"testball"

    assert_match "testball is pinned. You must unpin it to reinstall.", cmd("reinstall", "testball")

    HOMEBREW_PINNED_KEGS.rmtree
  end
end
