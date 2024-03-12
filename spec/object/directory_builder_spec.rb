# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe OCFL::Object::DirectoryBuilder do
  subject(:builder) { described_class.new(object_root:, id: "http://example.com/minimal") }

  around do |example|
    Dir.mktmpdir("ocfl-rspec-") do |dir|
      @temp_dir = dir
      example.run
    end
  end

  let(:object_root) { File.join(@temp_dir, "abc123") }

  describe "#save" do
    it "has built a valid object with a file" do
      builder.copy_file("Gemfile.lock")

      directory = builder.save
      expect(directory).to be_valid
      expect(directory.path("v1", "Gemfile.lock")).to eq Pathname.new(object_root) + "v1/content/Gemfile.lock"
    end
  end
end
