# frozen_string_literal: true

module OCFL
  # Represents the JSON file that stores the object inventory
  # https://ocfl.io/1.1/spec/#inventory
  class Inventory
    URI_1_1 = "https://ocfl.io/1.1/spec/#inventory"

    # A data structure for the inventory
    class InventoryStruct < Dry::Struct
      transform_keys(&:to_sym)
      attribute :id, Types::String
      attribute :type, Types::String
      attribute :digestAlgorithm, Types::String
      attribute :head, Types::String
      attribute? :contentDirectory, Types::String
      attribute :versions, Types::Hash.map(Types::String, ObjectVersion)
      attribute :manifest, Types::Hash
    end

    # @param [InventoryStruct] data
    def initialize(data:)
      @data = data
    end

    attr_reader :errors, :data

    delegate :id, :head, :versions, :manifest, to: :data
    delegate :state, to: :head_version

    def content_directory
      data.contentDirectory || "content"
    end

    # @return [String,nil] the path to the file relative to the object root. (e.g. v2/content/image.tiff)
    def path(logical_path)
      return unless head_version # object does not exist on disk

      digest, = state.find { |_, logical_paths| logical_paths.include?(logical_path) }
      return unless digest

      manifest[digest]&.first
    end

    def head_version
      versions[head]
    end
  end
end
