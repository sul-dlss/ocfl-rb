# frozen_string_literal: true

module OCFL
  # An OCFL Storage Root is the base directory of an OCFL storage layout.
  # https://ocfl.io/1.1/spec/#storage-root
  class StorageRoot
    attr_reader :base_directory, :layout

    delegate :path_to, to: :layout

    def initialize(base_directory:)
      @base_directory = Pathname.new(base_directory)
      @layout = Layouts::DruidTree
    end

    def exists?
      File.directory?(base_directory)
    end

    def valid?
      File.exist?(namaste_file)
    end

    def save
      # TODO: optionally write the OCFL 1.1 spec
      # TODO: optionally write any given extensions (like the TBD druid-tree layout)
      return if exists? && valid?

      FileUtils.mkdir_p(base_directory)
      FileUtils.touch(namaste_file)
      true
    end

    def object(identifier)
      root = base_directory / path_to(identifier)

      Object.new(root:)
    end

    private

    def namaste_file
      base_directory / "0=ocfl_1.1"
    end
  end
end
