# frozen_string_literal: true

require "digest"

module OCFL
  module Object
    # A new OCFL version
    class DraftVersion
      # @params [Directory] object_directory
      def initialize(object_directory:)
        @object_directory = object_directory
        @manifest = object_directory.inventory.manifest.dup
        @state = {}
      end

      attr_reader :object_directory, :manifest, :state

      def move_file(incoming_path)
        prepare_content_directory
        add(incoming_path)
        FileUtils.mv(incoming_path, content_path)
      end

      def copy_file(incoming_path)
        prepare_content_directory
        add(incoming_path)
        FileUtils.cp(incoming_path, content_path)
      end

      # def copy_directory(incoming_path)
      #   prepare_content_directory
      #   Dir.foreach(incoming_path) do |file_name|
      #     next if ['.', '..'].include?(file_name)
      #     add(incoming_path)
      #     FileUtils.cp(incoming_path, content_path)
      #   end
      # end

      def add(incoming_path)
        digest = Digest::SHA512.file(incoming_path).to_s
        version_content_path = content_path.relative_path_from(object_directory.object_root)
        logical_file_path = File.basename(incoming_path)
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

      def version_number
        @version_number ||= "v#{object_directory.head.delete_prefix("v").to_i + 1}"
      end

      def build_inventory
        old_data = object_directory.inventory.data
        versions = old_data.versions.merge(version_number => Version.new(created: Time.now.utc.iso8601, state: @state))
        Inventory::InventoryStruct.new(old_data.to_h.merge(manifest:, head: version_number, versions:))
      end

      def save
        inventory = build_inventory
        InventoryWriter.new(inventory:, path:).write
        FileUtils.cp(path + "inventory.json", object_directory.object_root)
        FileUtils.cp(path + "inventory.json.sha512", object_directory.object_root)
        object_directory.reload
      end
    end
  end
end
