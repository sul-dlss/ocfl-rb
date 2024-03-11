# frozen_string_literal: true

require "json"
require "dry-schema"
require "dry-struct"

module OCFL
  module Object
    # Represents the JSON file that stores the object inventory
    # https://ocfl.io/1.1/spec/#inventory
    class Inventory
      URI_1_1 = "https://ocfl.io/1.1/spec/#inventory"

      # Schema types
      module Types
        include Dry.Types()
      end
      VersionEnum = Types::String.enum(URI_1_1)
      DigestAlgorithm = Types::String.enum("md5", "sha1", "sha256", "sha512", "blake2b-512")

      # https://ocfl.io/1.1/spec/#inventory-structure
      # Validation of the incoming data
      Schema = Dry::Schema.Params do
        required(:id).filled(:string)
        required(:type).filled(VersionEnum)
        required(:digestAlgorithm).filled(DigestAlgorithm)
        required(:head).filled(:string)
        optional(:contentDirectory).filled(:string)
      end

      # A data structure for the inventory
      class InventoryStruct < Dry::Struct
        transform_keys(&:to_sym)
        attribute :id, Types::String
        attribute :type, Types::String
        attribute :digestAlgorithm, Types::String
        attribute :head, Types::String
        attribute? :contentDirectory, Types::String
      end

      def initialize(file_name:)
        @file_name = file_name
      end

      attr_reader :errors, :data, :file_name

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
