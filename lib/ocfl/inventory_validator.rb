# frozen_string_literal: true

module OCFL
  # Checks to see that the inventory.json and it's checksum in a direcotory are valid
  class InventoryValidator
    def initialize(directory:)
      @directory = Pathname.new(directory)
    end

    attr_reader :directory

    def valid?
      inventory_file_exists? && inventory_file_matches_checksum?
    end

    def inventory_file_exists?
      File.exist?(inventory_file)
    end

    def inventory_file_matches_checksum?
      return false unless File.exist?(inventory_checksum_file)

      actual = inventory_file_checksum
      expected = File.read(inventory_checksum_file)
      expected.match?(/\A#{actual}\s+inventory\.json\z/)
    end

    def inventory_checksum_file
      directory / "inventory.json.sha512"
    end

    def inventory_file_checksum
      Digest::SHA512.file inventory_file
    end

    def inventory_file
      directory / "inventory.json"
    end
  end
end
