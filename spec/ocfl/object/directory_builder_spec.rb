# frozen_string_literal: true

require "fileutils"

RSpec.describe OCFL::Object::DirectoryBuilder do
  subject(:builder) { described_class.new(object_root:, id: "http://example.com/minimal") }

  include_context "with temp directory"

  let(:object_root) { File.join(temp_dir, "abc123") }

  describe "#save" do
    it "builds a valid object with a file" do
      builder.copy_file("Gemfile.lock")

      directory = builder.save
      expect(directory).to be_valid
      expect(directory.path("v1", "Gemfile.lock")).to eq(Pathname.new(object_root) / "v1/content/Gemfile.lock")
    end
  end

  describe "#initialize" do
    subject(:builder) { described_class.new(object_root:, id: "http://example.com/minimal", content_directory:) }

    let(:content_directory) { "my_documents" }

    it "uses the content_directory param when instantiating an inventory" do
      expect(builder.object_directory.inventory.content_directory).to eq(content_directory)
    end
  end
end
