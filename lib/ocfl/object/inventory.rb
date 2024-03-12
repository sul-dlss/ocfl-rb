# frozen_string_literal: true

module OCFL
  module Object
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
        attribute :versions, Types::Hash.map(Types::String, Version)
        attribute :manifest, Types::Hash
      end

      def initialize(data:)
        @data = data
      end

      attr_reader :errors, :data

      delegate :id, :head, :versions, :manifest, to: :data

      def content_directory
        data.contentDirectory || "content"
      end

      # @returns [String] the path to the file relative to the object root. (e.g. v2/content/image.tiff)
      def path(logical_path)
        sha = versions[head].state.find { |_sha, file_names| file_names.include?(logical_path) }&.first

        return unless sha

        manifest.fetch(sha).first
      end
    end
  end
end
