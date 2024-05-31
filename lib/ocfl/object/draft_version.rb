# frozen_string_literal: true

module OCFL
  module Object
    # A new OCFL version
    class DraftVersion
      # @params [Directory] object_directory
      def initialize(object_directory:, overwrite_head: false, state: {})
        @object_directory = object_directory
        @manifest = object_directory.inventory.manifest.dup
        @state = state

        number = object_directory.head.delete_prefix("v").to_i
        @version_number = "v#{overwrite_head ? number : number + 1}"
        @prepared_content = @prepared = overwrite_head
      end

      attr_reader :object_directory, :manifest, :state, :version_number

      delegate :file_names, to: :to_version_struct

      def move_file(incoming_path)
        prepare_content_directory
        add(incoming_path)
        FileUtils.mv(incoming_path, content_path)
      end

      def copy_file(incoming_path, destination_path: "")
        prepare_content_directory
        copy_one(destination_path.presence || File.basename(incoming_path), incoming_path)
      end

      # Note, this only removes the file from this version. Previous versions may still use it.
      def delete_file(sha512_digest)
        state.delete(sha512_digest)
        # If the manifest points at the current content directory, then we can delete it.
        file_paths = manifest[sha512_digest]
        return unless file_paths.all? { |path| path.start_with?("#{version_number}/") }

        File.unlink (object_directory.object_root + file_paths.first).to_s
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
        write_inventory(build_inventory)
        object_directory.reload
      end

      def to_version_struct
        Version.new(state:, created: Time.now.utc.iso8601)
      end

      private

      def write_inventory(inventory)
        InventoryWriter.new(inventory:, path:).write
        FileUtils.cp(path / "inventory.json", object_directory.object_root)
        FileUtils.cp(path / "inventory.json.sha512", object_directory.object_root)
      end

      # @param [String] logical_file_path where we're going to store the file (e.g. 'object/directory_builder_spec.rb')
      # @param [String] incoming_path where's this file from (e.g. 'spec/ocfl/object/directory_builder_spec.rb')
      def copy_one(logical_file_path, incoming_path)
        add(incoming_path, logical_file_path:)
        parent_dir = (content_path / logical_file_path).parent
        FileUtils.mkdir_p(parent_dir) unless parent_dir == content_path
        FileUtils.cp(incoming_path, content_path / logical_file_path)
      end

      def add(incoming_path, logical_file_path: File.basename(incoming_path))
        digest = Digest::SHA512.file(incoming_path).to_s
        version_content_path = content_path.relative_path_from(object_directory.object_root)
        file_path_relative_to_root = (version_content_path / logical_file_path).to_s
        @manifest[digest] = [file_path_relative_to_root]
        @state[digest] = [logical_file_path]
      end

      def prepare_content_directory
        prepare_directory
        return if @prepared_content

        FileUtils.mkdir(content_path)
        @prepared_content = true
      end

      def prepare_directory
        return if @prepared

        FileUtils.mkdir(path)
        @prepared = true
      end

      def content_path
        path / object_directory.inventory.content_directory
      end

      def path
        object_directory.object_root / version_number
      end

      def build_inventory
        old_data = object_directory.inventory.data
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
end
