# frozen_string_literal: true

module OCFL
  module Layouts
    # An OCFL Storage Root layout for the druid-tree structure
    # @see https://ocfl.io/1.1/spec/#root-structure
    class DruidTree
      DRUID_PARTS_PATTERN = /\A([b-df-hjkmnp-tv-z]{2})([0-9]{3})([b-df-hjkmnp-tv-z]{2})([0-9]{4})\z/i

      def self.path_to(identifier)
        segments = Array(identifier&.match(DRUID_PARTS_PATTERN)&.captures)

        raise "druid '#{identifier}' is invalid" unless segments.count == 4

        Pathname.new(
          File.join(segments)
        )
      end
    end
  end
end
