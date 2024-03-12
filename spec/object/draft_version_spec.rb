# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe OCFL::Object::DraftVersion do
  let(:builder) { OCFL::Object::DirectoryBuilder.new(object_root:, id: "http://example.com/minimal") }

  around do |example|
    Dir.mktmpdir("ocfl-rspec-") do |dir|
      @temp_dir = dir
      example.run
    end
  end

  let(:object_root) { @temp_dir }

  describe "#copy_file" do
    let(:directory) { builder.build }
    let(:new_version) { directory.begin_new_version }

    context "with a file in the current directory" do
      it "has built a valid object" do
        expect do
          new_version.copy_file("Gemfile.lock")
          new_version.save
        end.to change(directory, :head).from("v1").to("v2")
        expect(directory).to be_valid
      end
    end

    context "with a file a sub directory" do
      it "has built a valid object" do
        new_version.copy_file("sig/ocfl.rbs")
        new_version.save
        expect(directory).to be_valid
      end
    end
  end
end