# frozen_string_literal: true

class Formula
  class << self
    def uses_from_macos(dep, **args)
      depends_on(dep) if add_mac_dependency?(args)
    end

    private

    def add_mac_dependency?(args)
      args.each { |key, version| args[key] = OS::Mac::Version.from_symbol(version) }

      args.blank? ||
        args[:before] && OS::Mac.version < args[:before] ||
        args[:after] && OS::Mac.version >= args[:after]
    end
  end
end
