module UnpackStrategy
  class Zip
    include UnpackStrategy

    using Magic

    def self.extensions
      [".zip"]
    end

    def self.can_extract?(path)
      path.magic_number.match?(/\APK(\003\004|\005\006)/n)
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      quiet_flags = verbose ? [] : ["-qq"]
      system_command! "unzip",
                      args: [*quiet_flags, path, "-d", unpack_dir],
                      verbose: verbose
    end
  end
end

require "extend/os/mac/unpack_strategy/zip" if OS.mac?
