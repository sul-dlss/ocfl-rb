# frozen_string_literal: true

require_relative "ocfl/version"
require "zeitwerk"

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
  # Your code goes here...
end
