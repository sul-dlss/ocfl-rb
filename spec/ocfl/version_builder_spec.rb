# frozen_string_literal: true

RSpec.describe OCFL::VersionBuilder do
  include_context "with temp directory"

  let(:identifier) { "mh769bt9659" }
  let(:object) { storage_root.object(identifier) }

  describe "#copy_file" do
    let(:new_version) { object.begin_new_version }

    context "with a file in the current directory" do
      it "builds a valid object" do
        expect do
          new_version.copy_file("Gemfile.lock")
          new_version.save
        end.to change(object, :head).from("v0").to("v1")
        expect(new_version.file_names).to eq ["Gemfile.lock"]
        expect(object).to be_valid
      end
    end

    context "with a file that is a duplicate" do
      before do
        FileUtils.copy("Gemfile.lock", "tmp/Gemfile.bak")
      end

      it "builds a valid object" do
        expect do
          new_version.copy_file("Gemfile.lock")
          new_version.copy_file("tmp/Gemfile.bak", destination_path: "path/to/renamed.bak")
          new_version.save
        end.to change(object, :head).from("v0").to("v1")

        expect(new_version.file_names).to eq ["Gemfile.lock", "path/to/renamed.bak"]
        expect(object).to be_valid
      end
    end

    context "with a file a subdirectory" do
      it "builds a valid object" do
        new_version.copy_file("sig/ocfl.rbs")
        new_version.save
        expect(object).to be_valid
        expect(object.path(version: "v1", filepath: "ocfl.rbs"))
          .to eq(Pathname.new(object.root) / "v1/content/#{OCFL_RBS_DIGEST}")
        expect(object.path(filepath: "ocfl.rbs"))
          .to eq(Pathname.new(object.root) / "v1/content/#{OCFL_RBS_DIGEST}")
        expect(new_version.file_names).to eq ["ocfl.rbs"]
      end
    end

    context "with a destination path" do
      it "builds a valid object" do
        new_version.copy_file("sig/ocfl.rbs", destination_path: "ocfl/types/generated.rbs")
        new_version.save
        expect(object.path(version: "v1", filepath: "ocfl/types/generated.rbs"))
          .to eq(Pathname.new(object.root) / "v1/content/#{OCFL_RBS_DIGEST}")
      end
    end

    context "when builder is given a content directory" do
      let(:content_directory) { "stuff" }
      let(:object) { storage_root.object(identifier, content_directory) }

      it "builds a valid object in the expected directory" do
        new_version.copy_file("sig/ocfl.rbs")
        new_version.save
        expect(object).to be_valid
        expect(object.path(version: "v1", filepath: "ocfl.rbs"))
          .to eq(Pathname.new(object.root) / "v1/#{content_directory}/#{OCFL_RBS_DIGEST}")
        expect(object.path(filepath: "ocfl.rbs"))
          .to eq(Pathname.new(object.root) / "v1/#{content_directory}/#{OCFL_RBS_DIGEST}")
      end
    end

    context "with a logical path that already exists, but with a different file" do
      let(:original_path) do
        new_version.copy_file("sig/ocfl.rbs", destination_path: "file1.txt")
        new_version.save
        object.path(version: "v1", filepath: "file1.txt")
      end

      it "builds a valid object" do
        expect(original_path).to exist
        new_version.copy_file("spec/fixtures/files/file1.txt", destination_path: "file1.txt")
        new_version.save
        expect(object.path(version: "v1", filepath: "file1.txt"))
          .to eq(Pathname.new(object.root) / "v1/content/#{FILE1_TXT_DIGEST}")
        expect(original_path).not_to exist
        expect(object).to be_valid
      end
    end
  end

  describe "#copy_recursive" do
    let(:new_version) { object.begin_new_version }

    context "without a destination path" do
      it "builds a valid object" do
        expect do
          new_version.copy_recursive("spec/fixtures/")
          new_version.save
        end.to change(object, :head).from("v0").to("v1")
        expect(object.versions["v1"].state.values.flatten).to include("files/file1.txt")
        expect(object.manifest.values.flatten).to include("v1/content/#{FILE1_TXT_DIGEST}")
        expect(File.exist?("#{object.root}/v1/content/#{FILE1_TXT_DIGEST}")).to be true

        expect(object).to be_valid
      end
    end

    context "with a destination path" do
      it "builds a valid object" do
        expect do
          new_version.copy_recursive("spec/fixtures/", destination_path: "data/")
          new_version.save
        end.to change(object, :head).from("v0").to("v1")
        expect(object.versions["v1"].state.values.flatten).to include("data/file2.txt")
        expect(object.manifest.values.flatten).to include("v1/content/#{FILE2_TXT_DIGEST}")
        expect(File.exist?("#{object.root}/v1/content/#{FILE2_TXT_DIGEST}")).to be true

        expect(object).to be_valid
      end
    end
  end

  describe "#delete_file" do
    let(:version) { object.begin_new_version }
    let(:digest) { Digest::SHA512.file("Gemfile.lock").to_s }

    context "with a file in the current version" do
      let!(:file_path) do
        version.copy_file("Gemfile.lock")
        object.root + version.manifest[digest].first
      end

      it "removes the file" do
        expect { version.delete_file("Gemfile.lock") }.to change(file_path, :exist?).from(true).to(false)
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
        object.root + version.manifest[digest].first
      end

      it "builds a valid object" do
        new_version = object.begin_new_version
        new_version.delete_file("Gemfile.lock")
        expect(file_path).to exist # Keep the file within the old version
        expect(new_version.manifest).to include(digest) # It's still in the object (previous versions)
        expect(new_version.state).to be_empty # but it's not in this version.
      end
    end

    context "with an unknown file" do
      it "removes the file" do
        expect { version.delete_file("Gemfile.lock") }.to raise_error("Unknown file: Gemfile.lock")
        expect(version.state).to be_empty
        expect(version.file_names).to be_empty
        version.save # save prunes the manifest
        expect(version.manifest).to be_empty
      end
    end
  end
end
