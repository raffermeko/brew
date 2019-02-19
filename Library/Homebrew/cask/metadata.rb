module Cask
  module Metadata
    METADATA_SUBDIR = ".metadata".freeze

    def metadata_master_container_path
      @metadata_master_container_path ||= caskroom_path.join(METADATA_SUBDIR)
    end

    def metadata_versioned_path(version: self.version)
      cask_version = (version || :unknown).to_s

      raise CaskError, "Cannot create metadata path with empty version." if cask_version.empty?

      metadata_master_container_path.join(cask_version)
    end

    def metadata_timestamped_path(version: self.version, timestamp: :latest, create: false)
      raise CaskError, "Cannot create metadata path when timestamp is :latest." if create && timestamp == :latest

      path = if timestamp == :latest
        Pathname.glob(metadata_versioned_path(version: version).join("*")).max
      else
        timestamp = new_timestamp if timestamp == :now
        metadata_versioned_path(version: version).join(timestamp)
      end

      if create && !path.directory?
        odebug "Creating metadata directory #{path}."
        path.mkpath
      end

      path
    end

    def metadata_subdir(leaf, version: self.version, timestamp: :latest, create: false)
      raise CaskError, "Cannot create metadata subdir when timestamp is :latest." if create && timestamp == :latest

      unless leaf.respond_to?(:empty?) && !leaf.empty?
        raise CaskError, "Cannot create metadata subdir for empty leaf."
      end

      parent = metadata_timestamped_path(version: version, timestamp: timestamp, create: create)

      return if parent.nil?

      subdir = parent.join(leaf)

      if create && !subdir.directory?
        odebug "Creating metadata subdirectory #{subdir}."
        subdir.mkpath
      end

      subdir
    end

    private

    def new_timestamp(time = Time.now)
      time = time.utc

      timestamp = time.strftime("%Y%m%d%H%M%S")
      fraction = format("%.3f", time.to_f - time.to_i)[1..-1]

      timestamp.concat(fraction)
    end
  end
end
