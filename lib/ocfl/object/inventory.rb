# frozen_string_literal: true

module OCFL
  module Object
    # Represents the JSON file that stores the object inventory
    # https://ocfl.io/1.1/spec/#inventory
    class Inventory
      URI_1_1 = "https://ocfl.io/1.1/spec/#inventory"
      VersionEnum = Types::String.enum(URI_1_1)
      DigestAlgorithm = Types::String.enum("md5", "sha1", "sha256", "sha512", "blake2b-512")

      # https://ocfl.io/1.1/spec/#inventory-structure
      # Validation of the incoming data
      Schema = Dry::Schema.Params do
        # config.validate_keys = true
        required(:id).filled(:string)
        required(:type).filled(VersionEnum)
        required(:digestAlgorithm).filled(DigestAlgorithm)
        required(:head).filled(:string)
        optional(:contentDirectory).filled(:string)
        required(:versions).hash
        required(:manifest).hash
      end

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

      def initialize(file_name:)
        @file_name = file_name
      end

      attr_reader :errors, :data, :file_name

      delegate :id, :head, :versions, :manifest, to: :data

      def load
        return if @loaded

        @loaded = true
        data = File.read(file_name)
        json = JSON.parse(data)
        @errors = Schema.call(json).errors
        @data = InventoryStruct.new(json) if valid?
      end

      def valid?
        load
        errors.empty?
      end
    end
  end
end
