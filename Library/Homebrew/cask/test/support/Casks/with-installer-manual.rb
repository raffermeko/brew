test_cask 'with-installer-manual' do
  version '1.2.3'
  sha256 '67cdb8a02803ef37fdbf7e0be205863172e41a561ca446cd84f0d7ab35a99d94'

  url TestHelper.local_binary_url('caffeine.zip')
  homepage 'http://example.com/local-caffeine'

  installer manual: 'Caffeine.app'
end
