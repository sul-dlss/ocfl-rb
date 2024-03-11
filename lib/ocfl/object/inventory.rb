# frozen_string_literal: true

require "json"

module OCFL
  module Object
    # Represents the JSON file that stores the object inventory
    # https://ocfl.io/1.1/spec/#inventory
    class Inventory
      def initialize(file_name:)
        data = File.read(file_name)
        @json = JSON.parse(data)
      end

      attr_reader :json

      def valid?
        json.include?("id")
      end
    end
  end
end
