# frozen_string_literal: true

RSpec.describe OCFL::Object::DraftVersion do
  include_context "with temp directory"

  let(:builder) { OCFL::Object::DirectoryBuilder.new(object_root:, id: "http://example.com/minimal") }
  let(:object_root) { File.join(temp_dir, "abc123") }

  describe "#copy_file" do
    let(:directory) { builder.save }
    let(:new_version) { directory.begin_new_version }

    context "with a file in the current directory" do
      it "builds a valid object" do
        expect do
          new_version.copy_file("Gemfile.lock")
          new_version.save
        end.to change(directory, :head).from("v1").to("v2")
        expect(new_version.file_names).to eq ["Gemfile.lock"]
        expect(directory).to be_valid
      end
    end

    context "with a file a sub directory" do
      it "builds a valid object" do
        new_version.copy_file("sig/ocfl.rbs")
        new_version.save
        expect(directory).to be_valid
        expect(directory.path(version: "v2", filepath: "ocfl.rbs"))
          .to eq(Pathname.new(object_root) / "v2/content/ocfl.rbs")
        expect(directory.path(filepath: "ocfl.rbs"))
          .to eq(Pathname.new(object_root) / "v2/content/ocfl.rbs")
        expect(new_version.file_names).to eq ["ocfl.rbs"]
      end
    end

    context "when builder is given a content directory" do
      let(:builder) { OCFL::Object::DirectoryBuilder.new(object_root:, id: "http://example.com/minimal", content_directory:) }
      let(:content_directory) { "stuff" }

      it "builds a valid object in the expected directory" do
        new_version.copy_file("sig/ocfl.rbs")
        new_version.save
        expect(directory).to be_valid
        expect(directory.path(version: "v2", filepath: "ocfl.rbs"))
          .to eq(Pathname.new(object_root) / "v2/#{content_directory}/ocfl.rbs")
        expect(directory.path(filepath: "ocfl.rbs"))
          .to eq(Pathname.new(object_root) / "v2/#{content_directory}/ocfl.rbs")
      end
    end
  end

  describe "#copy_recursive" do
    let(:directory) { builder.save }
    let(:new_version) { directory.begin_new_version }

    context "without a destination path" do
      it "builds a valid object" do
        expect do
          new_version.copy_recursive("spec/ocfl/")
          new_version.save
        end.to change(directory, :head).from("v1").to("v2")
        expect(directory.versions["v2"].state.values.flatten).to include("object/draft_version_spec.rb")
        expect(directory.manifest.values.flatten).to include("v2/content/object/draft_version_spec.rb")
        expect(File.exist?("#{object_root}/v2/content/object/draft_version_spec.rb")).to be true

        expect(directory).to be_valid
      end
    end

    context "with a destination path" do
      it "builds a valid object" do
        expect do
          new_version.copy_recursive("spec/ocfl/", destination_path: "data/")
          new_version.save
        end.to change(directory, :head).from("v1").to("v2")
        expect(directory.versions["v2"].state.values.flatten).to include("data/object/draft_version_spec.rb")
        expect(directory.manifest.values.flatten).to include("v2/content/data/object/draft_version_spec.rb")
        expect(File.exist?("#{object_root}/v2/content/data/object/draft_version_spec.rb")).to be true

        expect(directory).to be_valid
      end
    end
  end

  describe "#delete_file" do
    let(:directory) { builder.save }
    let(:version) { directory.begin_new_version }
    let(:digest) { Digest::SHA512.file("Gemfile.lock").to_s }

    context "with a file in the current version" do
      let!(:file_path) do
        version.copy_file("Gemfile.lock")
        directory.object_root + version.manifest[digest].first
      end

      it "removes the file" do
        expect { version.delete_file(digest) }.to change(file_path, :exist?).from(true).to(false)
        expect(version.state).to be_empty
        expect(version.file_names).to be_empty
        version.save # save prunes the manifest
        expect(version.manifest).to be_empty
      end
    end

    context "with a file in the previous version" do
      let!(:file_path) do
        version.copy_file("Gemfile.lock")
        version.save
        directory.object_root + version.manifest[digest].first
      end

      it "builds a valid object" do
        new_version = directory.begin_new_version
        new_version.delete_file(digest)
        expect(file_path).to exist # Keep the file within the old version
        expect(new_version.manifest).to include(digest) # It's still in the object (previous versions)
        expect(new_version.state).to be_empty # but it's not in this version.
      end
    end
  end
end
