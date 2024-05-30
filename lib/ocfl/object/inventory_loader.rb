# frozen_string_literal: true

module OCFL
  class Object
    # Loads and Inventory object from JSON
    class InventoryLoader
      include Dry::Monads[:result]

      VersionEnum = Types::String.enum(Inventory::URI_1_1)
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

      def self.load(file_name)
        new(file_name).load
      end

      def initialize(file_name)
        @file_name = file_name
      end

      def load
        bytestream = File.read(@file_name)
        data = JSON.parse(bytestream)
        errors = Schema.call(data).errors
        if errors.empty?
          Success(Inventory::InventoryStruct.new(data))
        else
          Failure(errors)
        end
      end
    end
  end
end
