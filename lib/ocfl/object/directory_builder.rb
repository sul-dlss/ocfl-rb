# frozen_string_literal: true

require "digest"

module OCFL
  module Object
    # Creates a OCFL Directory layout for a particular object.
    # rubocop:disable Style/StringConcatenation
    class DirectoryBuilder
      def initialize(object_root:, id:, version: "v1")
        @object_root = Pathname.new(object_root)
        @id = id
        @version = version
      end

      attr_reader :id, :version, :object_root

      # @return [Directory]
      def build
        FileUtils.mkdir_p(object_root)
        FileUtils.touch(object_root + "0=ocfl_object_1.1")
        write_inventory
        update_inventory_checksum
        create_head_version
        Directory.new(object_root:)
      end

      def create_head_version
        FileUtils.mkdir(object_root + version)
        FileUtils.cp(inventory_file, object_root + version + "inventory.json")
        FileUtils.cp(checksum_file, object_root + version + "inventory.json.sha512")
      end

      def write_inventory
        File.write(inventory_file, build_inventory.to_h.to_json)
      end

      def inventory_file
        object_root + "inventory.json"
      end

      def checksum_file
        object_root + "inventory.json.sha512"
      end

      def update_inventory_checksum
        digest = Digest::SHA512.file inventory_file
        File.write(object_root + "inventory.json.sha512", "#{digest} inventory.json")
      end

      def build_inventory
        versions = { version => Version.new(created: Time.now.utc.iso8601, state: {}) }
        Inventory::InventoryStruct.new(id:, version:, type: Inventory::URI_1_1, digestAlgorithm: "sha512",
                                       head: version, versions:, manifest: {})
      end
    end
    # rubocop:enable Style/StringConcatenation
  end
end
