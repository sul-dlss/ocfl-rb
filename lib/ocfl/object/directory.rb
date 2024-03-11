# frozen_string_literal: true

require "digest"

module OCFL
  module Object
    # An OCFL Directory layout for a particular object.
    # rubocop:disable Style/StringConcatenation
    class Directory
      def initialize(object_root:)
        @object_root = Pathname.new(object_root)
      end

      attr_reader :object_root

      def inventory
        @inventory ||= begin
          data = InventoryLoader.load(inventory_file.to_s)
          if data.success?
            Inventory.new(data: data.value!)
          else
            @errors = data.failure
            puts @errors.inspect
            nil
          end
        end
      end

      def valid?
        directory_exists? &&
          namaste_exists? &&
          inventory_file_exists? &&
          inventory_file_matches_checksum? &&
          !!inventory # Ensures it could be loaded
      end

      def directory_exists?
        File.directory?(object_root)
      end

      def inventory_file_exists?
        File.exist?(inventory_file)
      end

      def namaste_exists?
        File.exist?(namaste_file)
      end

      def namaste_file
        object_root + "0=ocfl_object_1.1"
      end

      def inventory_file
        object_root + "inventory.json"
      end

      def inventory_checksum_file
        object_root + "inventory.json.sha512"
      end

      def inventory_file_matches_checksum?
        return false unless File.exist?(inventory_checksum_file)

        actual = inventory_file_checksum
        expected = File.read(inventory_checksum_file)
        expected.match?(/\A#{actual}\s+inventory\.json\z/)
      end

      def inventory_file_checksum
        Digest::SHA512.file inventory_file
      end

      def write_inventory; end

      def update_inventory_checksum; end
    end
    # rubocop:enable Style/StringConcatenation
  end
end
