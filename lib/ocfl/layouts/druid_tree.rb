# frozen_string_literal: true

module OCFL
  module Layouts
    # An OCFL Storage Root layout for the druid-tree structure
    # @see https://ocfl.io/1.1/spec/#root-structure
    class DruidTree
      DRUID_PARTS_PATTERN = /\A([b-df-hjkmnp-tv-z]{2})([0-9]{3})([b-df-hjkmnp-tv-z]{2})([0-9]{4})\z/i

      attr_reader :base_directory

      def initialize(base_directory:)
        @base_directory = base_directory
      end

      def save
        File.write(base_directory / StorageRoot::LAYOUT_FILE, to_layout_json)
        FileUtils.mkdir_p(extension_directory)
        File.write(extension_directory / Extensions::CONFIG_FILE, to_config_json)
      end

      def path_to(identifier)
        segments = Array(identifier&.match(DRUID_PARTS_PATTERN)&.captures)

        raise "druid '#{identifier}' is invalid" unless segments.count == 4

        Pathname.new(
          File.join(segments)
        )
      end

      private

      def extension_name
        "0010-differential-n-tuple-omit-prefix-storage-layout"
      end

      def extension_directory
        base_directory / Extensions::STORAGE_ROOT_SUBDIRECTORY / extension_name
      end

      def to_config_json
        JSON.generate(
          {
            extensionName: extension_name,
            delimiter: ":",
            tupleSegmentSizes: [2, 3, 2, 4],
            fullIdentifierAsObjectRoot: false
          }
        )
      end

      def to_layout_json
        JSON.generate(
          {
            extension: extension_name,
            description: "Objects are stored in a druid-tree beneath this directory. " \
                         "For an object identified by `bc123df4567`, it will be found in `bc/123/df/4567/`"
          }
        )
      end
    end
  end
end
