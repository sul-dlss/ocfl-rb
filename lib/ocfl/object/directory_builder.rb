# frozen_string_literal: true

require "digest"

module OCFL
  module Object
    # Creates a OCFL Directory layout for a particular object.
    class DirectoryBuilder
      class ObjectExists < Error; end

      def initialize(object_root:, id:)
        @object_root = Pathname.new(object_root)
        raise ObjectExists, "The directory `#{object_root}' already exists" if @object_root.exist?

        @id = id
      end

      attr_reader :id, :object_root, :object_directory

      def copy_file(...)
        create_directory
        version.copy_file(...)
      end

      def create_directory
        FileUtils.mkdir_p(object_root)
      end

      # @return [Directory]
      def save
        version_path = object_root + "v1"
        FileUtils.mkdir_p(version_path) unless version_path.exist? # in case no files were added

        FileUtils.touch(object_root + "0=ocfl_object_1.1")
        write_inventory
        object_directory
      end

      def version
        @version ||= begin
          data = Inventory::InventoryStruct.new(id:, version: "v0", type: Inventory::URI_1_1, digestAlgorithm: "sha512",
                                                head: "v0", versions: {}, manifest: {})
          inventory = Inventory.new(data:)
          @object_directory = Directory.new(object_root: @object_root, inventory:)
          DraftVersion.new(object_directory:)
        end
      end

      def write_inventory
        version.save
      end
    end
    # rubocop:enable Style/StringConcatenation
  end
end
