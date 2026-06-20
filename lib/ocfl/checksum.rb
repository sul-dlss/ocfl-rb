# frozen_string_literal: true

module OCFL
  # Runs checksums
  class Checksum
    def initialize(type)
      @type = type
    end

    attr_accessor :type

    def implementation
      case type
      when "sha512"
        Digest::SHA512
      when "md5"
        Digest::MD5
      end
    end

    delegate :file, to: :implementation
  end
end
