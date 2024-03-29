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

  let(:object_root) { File.join(@temp_dir, "abc123") }

  describe "#copy_file" do
    let(:directory) { builder.save }
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
        expect(directory.path("v2", "ocfl.rbs")).to eq Pathname.new(object_root) + "v2/content/ocfl.rbs"
        expect(directory.path(:head, "ocfl.rbs")).to eq Pathname.new(object_root) + "v2/content/ocfl.rbs"
      end
    end
  end

  describe "#copy_recursive" do
    let(:directory) { builder.save }
    let(:new_version) { directory.begin_new_version }

    context "without a destination path" do
      it "has built a valid object" do
        expect do
          new_version.copy_recursive("spec/")
          new_version.save
        end.to change(directory, :head).from("v1").to("v2")
        expect(directory.versions["v2"].state.values.flatten).to include("object/draft_version_spec.rb")
        expect(directory.manifest.values.flatten).to include("v2/content/object/draft_version_spec.rb")
        expect(File.exist?("#{object_root}/v2/content/object/draft_version_spec.rb")).to be true

        expect(directory).to be_valid
      end
    end

    context "with a destination path" do
      it "has built a valid object" do
        expect do
          new_version.copy_recursive("spec/", destination_path: "data/")
          new_version.save
        end.to change(directory, :head).from("v1").to("v2")
        expect(directory.versions["v2"].state.values.flatten).to include("data/object/draft_version_spec.rb")
        expect(directory.manifest.values.flatten).to include("v2/content/data/object/draft_version_spec.rb")
        expect(File.exist?("#{object_root}/v2/content/data/object/draft_version_spec.rb")).to be true

        expect(directory).to be_valid
      end
    end
  end
end
