# frozen_string_literal: true

require "digest"

module OCFL
  module Object
    # Creates a OCFL Directory layout for a particular object.
    class DirectoryBuilder
      class ObjectExists < Error; end

      def initialize(object_root:, id:, content_directory: nil)
        @object_root = Pathname.new(object_root)
        raise ObjectExists, "The directory `#{object_root}' already exists" if @object_root.exist?

        @id = id
        inventory = Inventory.new(
          data: Inventory::InventoryStruct.new(
            new_inventory_attrs.tap { |attrs| attrs[:contentDirectory] = content_directory if content_directory }
          )
        )
        @object_directory = Directory.new(object_root:, inventory:)
      end

      attr_reader :id, :inventory, :object_root, :object_directory

      def copy_file(...)
        create_object_directory
        version.copy_file(...)
      end

      def copy_recursive(...)
        create_object_directory
        version.copy_recursive(...)
      end

      def create_object_directory
        FileUtils.mkdir_p(object_root)
      end

      # @return [Directory]
      def save
        version_path = object_root / "v1"
        FileUtils.mkdir_p(version_path)
        FileUtils.touch(object_directory.namaste_file)
        write_inventory
        object_directory
      end

      def version
        @version ||= DraftVersion.new(object_directory:)
      end

      def write_inventory
        version.save
      end

      private

      def new_inventory_attrs
        {
          id:,
          version: "v0",
          type: Inventory::URI_1_1,
          digestAlgorithm: "sha512",
          head: "v0",
          versions: {},
          manifest: {}
        }
      end
    end
  end
end
