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
      delegate :state, to: :head_version

      def content_directory
        data.contentDirectory || "content"
      end

      # @return [String,nil] the path to the file relative to the object root. (e.g. v2/content/image.tiff)
      def path(logical_path)
        matching_paths = manifest.values.flatten.select do |path|
          path.match(%r{\Av\d+/#{content_directory}/#{logical_path}\z})
        end

        return if matching_paths.empty?

        matching_paths.max_by { |path| path[/\d+/].to_i }
      end

      def head_version
        versions[head]
      end
    end
  end
end
