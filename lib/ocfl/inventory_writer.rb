# frozen_string_literal: true

module OCFL
  # Writes a OCFL Inventory to json on disk
  class InventoryWriter
    def initialize(inventory:, path:, checksum:)
      @path = path
      @inventory = inventory
      @checksum = checksum
    end

    attr_reader :inventory, :path, :checksum

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
      path / "inventory.json.#{checksum.type}"
    end

    def update_inventory_checksum
      digest = checksum.file inventory_file
      File.write(checksum_file, "#{digest} inventory.json")
    end
  end
end
