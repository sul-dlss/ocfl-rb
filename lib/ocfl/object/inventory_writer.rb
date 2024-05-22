# frozen_string_literal: true

require "digest"

module OCFL
  module Object
    # Writes a OCFL Inventory to json on disk
    class InventoryWriter
      def initialize(inventory:, path:)
        @path = path
        @inventory = inventory
      end

      attr_reader :inventory, :path

      def write
        write_inventory
        update_inventory_checksum
      end

      def write_inventory
        File.write(inventory_file, JSON.pretty_generate(inventory.to_h))
      end

      def inventory_file
        path / "inventory.json"
      end

      def checksum_file
        path / "inventory.json.sha512"
      end

      def update_inventory_checksum
        digest = Digest::SHA512.file inventory_file
        File.write(checksum_file, "#{digest} inventory.json")
      end
    end
  end
end
