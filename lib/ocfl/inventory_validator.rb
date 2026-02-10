# frozen_string_literal: true

module OCFL
  # Checks to see that the inventory.json and it's checksum in a direcotory are valid
  class InventoryValidator
    def initialize(directory:)
      @directory = Pathname.new(directory)
    end

    attr_reader :directory

    def valid?
      inventory_file_exists? &&
        inventory_file_result.success? &&
        inventory_file_matches_checksum?
    end

    private

    def inventory_file_exists?
      File.exist?(inventory_file)
    end

    def inventory_file_matches_checksum?
      return false unless File.exist?(inventory_checksum_file)

      actual = inventory_file_checksum
      inventory_checksum_file_content.match?(/\A#{actual}\s+inventory\.json\z/)
    end

    def inventory_checksum_file
      directory / "inventory.json.#{checksum.type}"
    end

    def inventory_file_checksum
      checksum.file inventory_file
    end

    def checksum
      @checksum ||= Checksum.new(inventory_file_result.value!.digestAlgorithm)
    end

    def inventory_file
      directory / "inventory.json"
    end

    def inventory_checksum_file_content
      File.read(inventory_checksum_file)
    end

    def inventory_file_result
      @inventory_file_result ||= InventoryLoader.load(inventory_file)
    end
  end
end
