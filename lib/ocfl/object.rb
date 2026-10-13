# frozen_string_literal: true

module OCFL
  # An OCFL Object is a group of one or more content files and administrative information
  # https://ocfl.io/1.1/spec/#object-spec
  class Object
    class FileNotFound < RuntimeError; end

    # @param [String] identifier an object identifier
    # @param [Pathname, String] root the path to the object root within the OCFL structure
    # @param [Inventory, nil] inventory this is only passed in when creating a new version
    # @param [String, nil] content_directory the directory to store versions in
    # @param [String] digest_algorithm ("sha512") the digest type to use
    def initialize(root:, identifier:, inventory: nil, content_directory: nil, digest_algorithm: "sha512")
      @identifier = identifier
      @root = Pathname.new(root)
      @content_directory = content_directory
      @digest_algorithm = digest_algorithm
      @version_inventory = {}
      @version_inventory_errors = {}
      @inventory = inventory
    end

    attr_reader :root, :errors, :identifier

    delegate :head, :versions, :manifest, to: :inventory

    def exists?
      namaste_file.exist?
    end

    def path(filepath:, version: nil)
      version ||= head
      relative_path = version_inventory(version).path(filepath)

      raise FileNotFound, "Path '#{filepath}' not found in #{version} inventory" if relative_path.nil?

      root / relative_path
    end

    def inventory
      @inventory ||= begin
        maybe_inventory, inventory_loading_errors = load_or_initialize_inventory
        if maybe_inventory
          maybe_inventory
        else
          @errors = inventory_loading_errors
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
        maybe_inventory, inventory_loading_errors = load_or_initialize_inventory(version:)
        if maybe_inventory
          maybe_inventory
        else
          @version_inventory_errors[version] = inventory_loading_errors
          puts @version_inventory_errors[version].messages.inspect
          nil
        end
      end
    end

    def valid?
      InventoryValidator.new(directory: root).valid? &&
        exists? &&
        !inventory.nil? && # Ensures it could be loaded
        head_directory_valid?
    end

    def head_directory_valid?
      InventoryValidator.new(directory: root / inventory.head).valid? &&
        !head_inventory.nil? # Ensures it could be loaded
    end

    # Start a completely new version
    def begin_new_version
      VersionBuilder.new(object: self, state:)
    end

    # Get a handle for the head version
    def head_version
      VersionBuilder.new(object: self, overwrite_head: true, state: head_inventory.state)
    end

    # Get a handle that will replace the existing head version
    def overwrite_current_version
      VersionBuilder.new(object: self, overwrite_head: true)
    end

    def reload
      @version_inventory = {}
      @inventory = nil
      @errors = nil
      @version_inventory_errors = {}
      true
    end

    def namaste_file
      root / "0=ocfl_object_1.1"
    end

    private

    def load_or_initialize_inventory(version: "")
      inventory_path = root / version / "inventory.json"

      return [new_inventory, nil] unless inventory_path.exist?

      data = InventoryLoader.load(inventory_path)
      if data.success?
        [Inventory.new(data: data.value!), nil]
      else
        [nil, data.failure]
      end
    end

    def state
      return {} if inventory.head == "v0"

      head_inventory.state
    end

    def new_inventory # rubocop:disable Metrics/MethodLength
      Inventory.new(
        data: Inventory::InventoryStruct.new(
          {
            id: identifier,
            version: "v0",
            type: Inventory::URI_1_1,
            digestAlgorithm: @digest_algorithm,
            head: "v0",
            versions: {},
            manifest: {}
          }.tap { |attrs| attrs[:contentDirectory] = @content_directory if @content_directory }
        )
      )
    end
  end
end
