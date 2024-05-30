# frozen_string_literal: true

module OCFL
  # An OCFL Object is a group of one or more content files and administrative information
  # https://ocfl.io/1.1/spec/#object-spec
  class Object
    class FileNotFound < RuntimeError; end

    attr_reader :root

    def initialize(root:)
      @root = root
    end
  end
end
