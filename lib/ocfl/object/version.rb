# frozen_string_literal: true

module OCFL
  module Object
    # Represents the OCFL version
    # https://ocfl.io/1.1/spec/#version
    class Version < Dry.Struct
      # Represents the OCFL user
      class User < Dry.Struct
        transform_keys(&:to_sym)
        attribute :name, Types::String
        attribute? :address, Types::String
      end

      transform_keys(&:to_sym)
      attribute :created, Types::String
      attribute :state, Types::Hash.map(Types::String, Types::Array.of(Types::String))
      attribute? :message, Types::String
      attribute? :user, User
    end
  end
end
