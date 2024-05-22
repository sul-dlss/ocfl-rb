# frozen_string_literal: true

module OCFL
  module Object
    # An OCFL Directory layout for a particular object.
    class Directory
      # @param [String] object_root
      # @param [Inventory] inventory this is only passed in when creating a new object. (see DirectoryBuilder)
      def initialize(object_root:, inventory: nil)
        @object_root = Pathname.new(object_root)
        @version_inventory = {}
        @version_inventory_errors = {}
        @inventory = inventory
      end

      attr_reader :object_root, :errors

      delegate :head, :versions, :manifest, to: :inventory

      def path(version, filename)
        version = head if version == :head
        relative_path = version_inventory(version).path(filename)
        object_root / relative_path
      end

      def inventory
        @inventory ||= begin
          data = InventoryLoader.load(object_root / "inventory.json")
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
        version_inventory(inventory.head)
      end

      def version_inventory(version)
        @version_inventory[version] ||= begin
          data = InventoryLoader.load(object_root / version / "inventory.json")
          if data.success?
            Inventory.new(data: data.value!)
          else
            @version_inventory_errors[version] = data.failure
            puts @version_inventory_errors[version].messages.inspect
            nil
          end
        end
      end

      def reload
        @version_inventory = {}
        @inventory = nil
        @errors = nil
        @version_inventory_errors = {}
        true
      end

      def begin_new_version
        DraftVersion.new(object_directory: self)
      end

      def overwrite_current_version
        DraftVersion.new(object_directory: self, overwrite_head: true)
      end

      def exists?
        namaste_exists?
      end

      def valid?
        InventoryValidator.new(directory: object_root).valid? &&
          namaste_exists? &&
          !inventory.nil? && # Ensures it could be loaded
          head_directory_valid?
      end

      def head_directory_valid?
        InventoryValidator.new(directory: object_root / inventory.head).valid? &&
          !head_inventory.nil? # Ensures it could be loaded
      end

      def namaste_exists?
        File.exist?(namaste_file)
      end

      def namaste_file
        object_root / "0=ocfl_object_1.1"
      end
    end
  end
end
