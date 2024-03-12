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
          data = InventoryLoader.load(object_root + "inventory.json")
          if data.success?
            Inventory.new(data: data.value!)
          else
            @errors = data.failure
            puts @errors.messages.inspect
            nil
          end
        end
      end

      def head_inventory
        @head_inventory ||= begin
          data = InventoryLoader.load(object_root + inventory.head + "inventory.json")
          if data.success?
            Inventory.new(data: data.value!)
          else
            @head_directory_validerrors = data.failure
            puts @head_errors.messages.inspect
            nil
          end
        end
      end

      def valid?
        InventoryValidator.new(directory: object_root).valid? &&
          namaste_exists? &&
          !inventory.nil? && # Ensures it could be loaded
          head_directory_valid?
      end

      def head_directory_valid?
        InventoryValidator.new(directory: object_root + inventory.head).valid? &&
          !head_inventory.nil? # Ensures it could be loaded
      end

      def namaste_exists?
        File.exist?(namaste_file)
      end

      def namaste_file
        object_root + "0=ocfl_object_1.1"
      end
    end
    # rubocop:enable Style/StringConcatenation
  end
end
