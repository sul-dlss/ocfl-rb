# frozen_string_literal: true

module OCFL
  # An OCFL Storage Root is the base directory of an OCFL storage layout.
  # https://ocfl.io/1.1/spec/#storage-root
  class StorageRoot
    LAYOUT_FILE = "ocfl_layout.json"
    SPECIFICATION_FILE = "ocfl_1.1.md"

    attr_reader :base_directory, :layout

    def initialize(base_directory:)
      @base_directory = Pathname.new(base_directory)
      @layout = Layouts::DruidTree.new(base_directory: @base_directory)
    end

    def exists?
      base_directory.directory?
    end

    def valid?
      namaste_file.exist?
    end

    def save
      return if exists? && valid?

      FileUtils.mkdir_p(base_directory)
      FileUtils.touch(namaste_file)
      FileUtils.cp(OCFL.docs_path / SPECIFICATION_FILE,
                   base_directory / SPECIFICATION_FILE)
      layout.save
      true
    end

    def object(identifier, content_directory = nil)
      root = base_directory / layout.path_to(identifier)

      Object.new(identifier:, root:, content_directory:)
    end

    private

    def namaste_file
      base_directory / "0=ocfl_1.1"
    end
  end
end
