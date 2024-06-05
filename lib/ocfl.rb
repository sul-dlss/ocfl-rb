# frozen_string_literal: true

require "zeitwerk"
require "active_support"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/blank"
require "digest"
require "dry/monads"
require "dry-schema"
require "dry-struct"
require "json"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("ocfl" => "OCFL")
loader.setup

# Root module holding all OCFL functionality in this gem
module OCFL
  class Error < StandardError; end

  # Path to where OCFL documents are stored in the gem
  def self.docs_path
    Pathname.new(__dir__)
            .parent
            .join("docs")
  end

  module Extensions
    CONFIG_FILE = "config.json"
    STORAGE_ROOT_SUBDIRECTORY = "extensions"
  end

  # Schema types
  module Types
    include Dry.Types()
  end
end
