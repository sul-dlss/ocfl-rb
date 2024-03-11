# frozen_string_literal: true

module OCFL
  module Object
    # An OCFL Directory layout for a particular object.
    class Directory
      def initialize(object_root:)
        @object_root = object_root
      end

      def inventory
        Inventory.new(inventory_file)
      end

      def valid?
        directory_exists? &&
          inventory_file_exists? &&
          inventory_file_matches_checksum? &&
          inventory.valid?
      end
    end
  end
end
