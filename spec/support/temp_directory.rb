# frozen_string_literal: true

require "tmpdir"

RSpec.shared_context("with temp directory") do
  # Create an OCFL storage root
  around do |example|
    Dir.mktmpdir("ocfl-rspec-") do |base_directory|
      @base_directory = base_directory
      @storage_root = OCFL::StorageRoot.new(base_directory:).tap(&:save)
      example.run
    end
  rescue Errno::ENOENT
    # A test cleaned up the directory for us.
  end

  let(:base_directory) { @base_directory }
  let(:storage_root) { @storage_root }
end
