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

  let(:object_root) { @temp_dir }

  describe "#build" do
    it "has built a valid object" do
      builder.build
      expect(OCFL::Object::Directory.new(object_root:)).to be_valid
    end
  end
end
