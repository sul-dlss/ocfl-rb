# frozen_string_literal: true

require "digest"

module OCFL
  module Object
    # A new OCFL version
    class DraftVersion
      # @params [Directory] object_directory
      def initialize(object_directory:, overwrite_head: false)
        @object_directory = object_directory
        @manifest = object_directory.inventory.manifest.dup
        @state = {}

        number = object_directory.head.delete_prefix("v").to_i
        @version_number = "v#{overwrite_head ? number : number + 1}"
        @prepared_content = @prepared = overwrite_head
      end

      attr_reader :object_directory, :manifest, :state, :version_number

      def move_file(incoming_path)
        prepare_content_directory
        add(incoming_path)
        FileUtils.mv(incoming_path, content_path)
      end

      def copy_file(incoming_path, destination_path: "")
        prepare_content_directory
        copy_one(File.basename(incoming_path), incoming_path, destination_path)
      end

      # Copies files into the object and preserves their relative paths as logical directories in the object
      def copy_recursive(incoming_path, destination_path: "")
        prepare_content_directory
        incoming_path = incoming_path.delete_suffix("/")
        Dir.glob("#{incoming_path}/**/*").reject { |fn| File.directory?(fn) }.each do |file|
          copy_one(file.delete_prefix(incoming_path).delete_prefix("/"), file, destination_path)
        end
      end

      def save
        inventory = build_inventory
        InventoryWriter.new(inventory:, path:).write
        FileUtils.cp(path + "inventory.json", object_directory.object_root)
        FileUtils.cp(path + "inventory.json.sha512", object_directory.object_root)
        object_directory.reload
      end

      private

      def copy_one(logical_file_path, incoming_path, destination_path)
        logical_file_path = File.join(destination_path, logical_file_path) unless destination_path.empty?
        add(incoming_path, logical_file_path:)
        parent_dir = (content_path + logical_file_path).parent
        FileUtils.mkdir_p(parent_dir) unless parent_dir == content_path
        FileUtils.cp(incoming_path, content_path + logical_file_path)
      end

      def add(incoming_path, logical_file_path: File.basename(incoming_path))
        digest = Digest::SHA512.file(incoming_path).to_s
        version_content_path = content_path.relative_path_from(object_directory.object_root)
        file_path_relative_to_root = (version_content_path + logical_file_path).to_s
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
        path + "content"
      end

      def path
        object_directory.object_root + version_number
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
        old_versions.merge(version_number => Version.new(created: Time.now.utc.iso8601, state: @state))
      end

      # The manifest after unused SHAs have been filtered out.
      def filtered_manifest(versions)
        shas_in_versions = versions.values.flat_map { |v| v.state.keys }.uniq
        manifest.slice(*shas_in_versions)
      end
    end
  end
end
