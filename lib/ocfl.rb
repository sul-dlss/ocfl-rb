# frozen_string_literal: true

require "zeitwerk"
require "json"
require "dry/monads"
require "dry-schema"
require "dry-struct"
require "active_support"
require "active_support/core_ext/module/delegation"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("ocfl" => "OCFL")
loader.setup

module OCFL
  class Error < StandardError; end

  # Schema types
  module Types
    include Dry.Types()
  end
end
