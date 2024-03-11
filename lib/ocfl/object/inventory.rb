# frozen_string_literal: true

require "json"
require "dry-schema"

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
      Schema = Dry::Schema.JSON do
        required(:id).filled(:string)
        required(:type).filled(VersionEnum)
        required(:digestAlgorithm).filled(DigestAlgorithm)
        required(:head).filled(:string)
        optional(:contentDirectory).filled(:string)
      end

      def initialize(file_name:)
        data = File.read(file_name)
        @json = JSON.parse(data)
      end

      attr_reader :json

      def valid?
        Schema.call(@json).errors.empty?
      end
    end
  end
end
