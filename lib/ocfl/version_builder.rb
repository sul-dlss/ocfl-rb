# frozen_string_literal: true

module OCFL
  # Build a new version
  # rubocop:disable Metrics/ClassLength
  class VersionBuilder
    # @params [Object] object
    def initialize(object:, overwrite_head: false, state: {})
      @object = object
      # Map of digest to content paths
      # For example: "7dcc35...c31": [ "v1/content/foo/bar.xml" ]
      @manifest = object.inventory.manifest.dup

      # Map of logical file paths to digests
      @inverse_state = state.flat_map { |digest, paths| paths.map { |path| [path, digest] } }.to_h
      number = object.head.delete_prefix("v").to_i
      @version_number = "v#{overwrite_head ? number : number + 1}"
      @prepared_content = @prepared = overwrite_head
      @clear_content = overwrite_head && state.empty? # overwrite current version
    end

    attr_reader :object, :manifest, :inverse_state, :version_number

    delegate :file_names, to: :to_version_struct

    # Move the file into the ocfl object (instead of copying it)
    def move_file(incoming_path, destination_path: "")
      prepare_content_directory
      copy_one(destination_path.presence || File.basename(incoming_path), incoming_path, move: true)
    end

    # Copy the file into the ocfl object.
    def copy_file(incoming_path, destination_path: "")
      prepare_content_directory
      copy_one(destination_path.presence || File.basename(incoming_path), incoming_path)
    end

    # Note, this only removes the file from this version. Previous versions may still use it.
    # rubocop:disable Metrics/AbcSize
    def delete_file(filename)
      # Remove the file from the state
      raise "Unknown file: #{filename}" unless (digest = inverse_state.delete(filename))

      # If there are no more state entries for that digest and the file is stored for this version,
      # delete the file and remove the manifest entry.
      return unless !inverse_state.value?(digest) && manifest[digest].first.start_with?("#{version_number}/")

      File.unlink(object.root + manifest[digest].first)
      manifest.delete(digest)
    end
    # rubocop:enable Metrics/AbcSize

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
      write_inventory(build_inventory)
      object.reload
    end

    # Transforms the inverse state (logical path to digest) into a state (digest to logical paths)
    def state
      {}.tap do |state|
        inverse_state.each do |logical_file_path, digest|
          state[digest] ||= []
          state[digest].push(logical_file_path)
        end
      end
    end

    private

    def to_version_struct
      ObjectVersion.new(state:, created: Time.now.utc.iso8601)
    end

    def write_inventory(inventory)
      InventoryWriter.new(inventory:, path:).write
      FileUtils.cp(path / "inventory.json", object.root)
      FileUtils.cp(path / "inventory.json.sha512", object.root)
    end

    # @param [String] logical_file_path where we're going to store the file (e.g. 'object/directory_builder_spec.rb')
    # @param [String] incoming_path where's this file from (e.g. 'spec/ocfl/object/directory_builder_spec.rb')
    # rubocop:disable Metrics/AbcSize
    def copy_one(logical_file_path, incoming_path, move: false)
      # Generate the digest
      digest = Digest::SHA512.file(incoming_path).to_s
      # If the logical_file_path is in the state with that digest, then return.
      return if inverse_state[logical_file_path] == digest

      # If the digest isn't in manifest
      unless manifest.key?(digest)
        file_content_path = copy_or_move_file(digest, incoming_path, move)
        # Add to the manifest
        manifest[digest] = [file_content_path.relative_path_from(object.root).to_s]
      end

      # If the logical_file_path is already in the state (associated with a different digest), delete it.
      delete_file(logical_file_path) if inverse_state.key?(logical_file_path)

      # Add the logical_file_path to the state with the digest.
      inverse_state[logical_file_path] = digest
    end
    # rubocop:enable Metrics/AbcSize

    def copy_or_move_file(digest, incoming_path, move)
      file_content_path = content_path / digest
      # Copy / move  to the content directory using the digest as filename
      if move
        FileUtils.mv(incoming_path, file_content_path)
      else
        FileUtils.cp(incoming_path, file_content_path)
      end
      file_content_path
    end

    def prepare_content_directory
      prepare_directory
      clear_content

      return if @prepared_content

      FileUtils.mkdir(content_path)
      @prepared_content = true
    end

    def clear_content
      return unless @clear_content

      FileUtils.rm_rf(content_path)
      FileUtils.mkdir(content_path)
      manifest.delete_if { |_digest, paths| paths.first.start_with?("#{version_number}/") }
      @clear_content = false
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

    def build_inventory
      old_data = object.inventory.data
      versions = versions(old_data.versions)

      # Prune items from manifest if they are not part of any version
      Inventory::InventoryStruct.new(old_data.to_h.merge(manifest:,
                                                         head: version_number, versions:))
    end

    # This gives the update list of versions. The old list plus this new one.
    # @param [Hash] old_versions the versions prior to this one.
    def versions(old_versions)
      old_versions.merge(version_number => to_version_struct)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
