# frozen_string_literal: true

module OCFL
  # Build a new version
  class VersionBuilder
    # @params [Object] object
    def initialize(object:, overwrite_head: false, state: {})
      @object = object
      @manifest = object.inventory.manifest.dup
      @state = state

      number = object.head.delete_prefix("v").to_i
      @version_number = "v#{overwrite_head ? number : number + 1}"
      @prepared_content = @prepared = overwrite_head
    end

    attr_reader :object, :manifest, :state, :version_number

    delegate :file_names, to: :to_version_struct

    def move_file(incoming_path)
      prepare_content_directory
      already_stored = add(incoming_path)
      return if already_stored

      FileUtils.mv(incoming_path, content_path)
    end

    def copy_file(incoming_path, destination_path: "")
      prepare_content_directory
      copy_one(destination_path.presence || File.basename(incoming_path), incoming_path)
    end

    def digest_for_filename(filename)
      state.find { |_, filenames| filenames.include?(filename) }&.first
    end

    # Note, this only removes the file from this version. Previous versions may still use it.
    def delete_file(filename)
      checksum_digest = digest_for_filename(filename)
      raise "Unknown file: #{filename}" unless checksum_digest

      state.delete(checksum_digest)
      # If the manifest points at the current content directory, then we can delete it.
      file_paths = manifest[checksum_digest]
      return unless file_paths.all? { |path| path.start_with?("#{version_number}/") }

      File.unlink (object.root + file_paths.first).to_s
    end

    # Copies files into the object and preserves their relative paths as logical directories in the object
    def copy_recursive(incoming_path, destination_path: "")
      prepare_content_directory
      incoming_path = incoming_path.delete_suffix("/")
      Dir.glob("#{incoming_path}/**/*").reject { |fn| File.directory?(fn) }.each do |file|
        logical_file_path = file.delete_prefix(incoming_path).delete_prefix("/")
        logical_file_path = File.join(destination_path, logical_file_path) unless destination_path.empty?

        copy_one(logical_file_path, file)
      end
    end

    def save
      prepare_directory # only necessary if the version has no new content (deletes only)
      write_inventory(build_inventory_struct)
      object.reload
    end

    private

    def checksum
      @checksum ||= Checksum.new(object.inventory.data.digestAlgorithm)
    end

    def to_version_struct
      ObjectVersion.new(state:, created: Time.now.utc.iso8601)
    end

    def write_inventory(inventory)
      InventoryWriter.new(inventory:, path:, checksum:).write
      FileUtils.cp(path / "inventory.json", object.root)
      FileUtils.cp(path / "inventory.json.#{checksum.type}", object.root)
    end

    # @param [String] logical_file_path where we're going to store the file (e.g. 'object/directory_builder_spec.rb')
    # @param [String] incoming_path where's this file from (e.g. 'spec/ocfl/object/directory_builder_spec.rb')
    def copy_one(logical_file_path, incoming_path)
      already_stored = add(incoming_path, logical_file_path:)
      return if already_stored

      parent_dir = (content_path / logical_file_path).parent
      FileUtils.mkdir_p(parent_dir) unless parent_dir == content_path
      FileUtils.cp(incoming_path, content_path / logical_file_path)
    end

    # @return [Boolean] true if the file already existed in this object. If false, the object must be
    #                   moved to the content directory.
    # rubocop:disable Metrics/AbcSize
    def add(incoming_path, logical_file_path: File.basename(incoming_path))
      digest = checksum.file(incoming_path).to_s
      version_content_path = content_path.relative_path_from(object.root)
      file_path_relative_to_root = (version_content_path / logical_file_path).to_s
      result = @manifest.key?(digest)
      @manifest[digest] ||= []
      @state[digest] ||= []
      @manifest[digest].push(file_path_relative_to_root)
      @state[digest].push(logical_file_path)
      result
    end
    # rubocop:enable Metrics/AbcSize

    def prepare_content_directory
      prepare_directory
      return if @prepared_content

      FileUtils.mkdir(content_path)
      @prepared_content = true
    end

    def prepare_directory
      return if @prepared

      FileUtils.mkdir_p(path)
      FileUtils.touch(object.namaste_file) if version_number == "v1"
      @prepared = true
    end

    def content_path
      path / object.inventory.content_directory
    end

    def path
      object.root / version_number
    end

    def build_inventory_struct
      old_data = object.inventory.data
      versions = versions(old_data.versions)

      # Prune items from manifest if they are not part of any version
      Inventory::InventoryStruct.new(old_data.to_h.merge(manifest: filtered_manifest(versions),
                                                         head: version_number, versions:))
    end

    # This gives the update list of versions. The old list plus this new one.
    # @param [Hash] old_versions the versions prior to this one.
    def versions(old_versions)
      old_versions.merge(version_number => to_version_struct)
    end

    # The manifest after unused SHAs have been filtered out.
    def filtered_manifest(versions)
      shas_in_versions = versions.values.flat_map { |v| v.state.keys }.uniq
      manifest.slice!(*shas_in_versions)
      manifest
    end
  end
end
