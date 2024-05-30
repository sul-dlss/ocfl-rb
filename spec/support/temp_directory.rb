# frozen_string_literal: true

require "tmpdir"

RSpec.shared_context("with temp directory") do
  # Create the object root directory
  around do |example|
    Dir.mktmpdir("ocfl-rspec-") do |dir|
      @base_directory = dir
      example.run
    end
  end

  attr_reader :base_directory
end
