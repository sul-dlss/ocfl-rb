# frozen_string_literal: true

require_relative "ocfl/version"
require "zeitwerk"
require "json"
require "dry/monads"
require "dry-schema"
require "dry-struct"
require "active_support"
require "active_support/core_ext/module/delegation"

# Custom zeitwerk inflector for OCFL
class OCFLInflector < Zeitwerk::Inflector
  def camelize(basename, _abspath)
    return "OCFL" if basename == "ocfl"

    super
  end
end

loader = Zeitwerk::Loader.for_gem
loader.inflector = OCFLInflector.new
loader.setup

module OCFL
  class Error < StandardError; end

  # Schema types
  module Types
    include Dry.Types()
  end
end
