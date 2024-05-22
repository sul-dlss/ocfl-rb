# frozen_string_literal: true

require "tmpdir"

RSpec.shared_context("with temp directory") do
  around do |example|
    Dir.mktmpdir("ocfl-rspec-") do |dir|
      @temp_dir = dir
      example.run
    end
  end

  attr_reader :temp_dir
end
