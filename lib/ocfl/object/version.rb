# frozen_string_literal: true

module OCFL
  module Object
    # Represents the OCFL version
    # https://ocfl.io/1.1/spec/#version
    class Version < Dry.Struct
      transform_keys(&:to_sym)
      attribute :created, Types::String
      attribute :state, Types::Hash.map(Types::String, Types::Array.of(Types::String))
    end
  end
end
