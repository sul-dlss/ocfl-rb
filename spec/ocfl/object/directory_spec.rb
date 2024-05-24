# frozen_string_literal: true

require "fileutils"

RSpec.describe OCFL::Object::Directory do
  subject(:directory) { described_class.new(object_root:) }

  include_context "with temp directory"

  describe "#valid?" do
    context "when the directory doesn't exist" do
      let(:object_root) { "/non-existing" }

      it { is_expected.not_to be_valid }
    end

    context "when the NAMASTE doesn't exist" do
      before { FileUtils.touch("#{temp_dir}/inventory.json") }

      let(:object_root) { temp_dir }

      it { is_expected.not_to be_valid }
    end

    context "when the inventory file doesn't exist" do
      before { FileUtils.touch("#{temp_dir}/0=ocfl_object_1.1") }

      let(:object_root) { temp_dir }

      it { is_expected.not_to be_valid }
    end

    context "when the inventory checksum doesn't exist" do
      before do
        FileUtils.touch("#{temp_dir}/0=ocfl_object_1.1")
        FileUtils.touch("#{temp_dir}/inventory.json")
      end

      let(:object_root) { temp_dir }

      it { is_expected.not_to be_valid }
    end

    context "when the inventory checksum doesn't match" do
      before do
        FileUtils.touch("#{temp_dir}/0=ocfl_object_1.1")
        FileUtils.touch("#{temp_dir}/inventory.json")
        File.write("#{temp_dir}/inventory.json.sha512",
                   "31598ebd1468eaa3b082afafdc90e500f32502d8824696dcc6674c9ccddb8fecd4bb4f0495a49d8ae83" \
                   "922c332e8ebdf0e34988589dbc3dfa6acaedf9b706870  inventory.json")
      end

      let(:object_root) { temp_dir }

      it { is_expected.not_to be_valid }
    end

    context "when the inventory isn't valid" do
      before do
        FileUtils.touch("#{temp_dir}/0=ocfl_object_1.1")
        FileUtils.touch("#{temp_dir}/inventory.json")
        File.write("#{temp_dir}/inventory.json", '{"manifest":{}}')
        File.write("#{temp_dir}/inventory.json.sha512",
                   "dd95136fa794284f8ffd5eb444b2b08732aa3f4d0d08a5f20b1c03a182294c34501066ac4b02159d38b" \
                   "cb6c8557fc724c636929775212c5194984d68cb1508a1  inventory.json")
      end

      let(:object_root) { temp_dir }

      it { is_expected.not_to be_valid }
    end
  end

  describe "#path" do
    let(:builder) { OCFL::Object::DirectoryBuilder.new(object_root:, id: "http://example.com/minimal") }
    let(:directory) do
      builder.copy_file("Gemfile.lock")
      builder.save
    end
    let(:object_root) { File.join(temp_dir, "abc123") }

    before do
      directory.begin_new_version.tap do |version|
        version.copy_recursive("sig/")
        version.save
      end
    end

    it "returns the path from the specified version's inventory" do
      expect(directory.path(filepath: "ocfl.rbs", version: "v2"))
        .to eq(Pathname.new(object_root) / "v2/content/ocfl.rbs")
    end

    context "when the filepath does not exist" do
      it "raises a FileNotFound exception" do
        expect { directory.path(filepath: "ocfl.rbs", version: "v1") }
          .to raise_error(OCFL::Object::FileNotFound, /Path 'ocfl.rbs' not found in v1 inventory/)
      end
    end

    context "when version is nil" do
      it "returns the path from the object's inventory" do
        expect(directory.path(filepath: "Gemfile.lock"))
          .to eq(Pathname.new(object_root) / "v1/content/Gemfile.lock")
      end

      context "when the filepath does not exist" do
        it "raises a FileNotFound exception" do
          expect { directory.path(filepath: "image.jp2") }
            .to raise_error(OCFL::Object::FileNotFound, /Path 'image.jp2' not found in v2 inventory/)
        end
      end
    end
  end

  describe "#overwrite_current_version" do
    let(:builder) { OCFL::Object::DirectoryBuilder.new(object_root:, id: "http://example.com/minimal") }
    let(:directory) do
      builder.copy_file("Gemfile.lock")
      builder.save
    end
    let(:object_root) { File.join(temp_dir, "abc123") }
    let(:overwrite) { directory.overwrite_current_version }

    context "with a file in the current directory" do
      let!(:before_keys) { directory.inventory.manifest.keys }

      around do |example|
        FileUtils.touch("spec/Gemfile.lock")
        example.run
      ensure
        FileUtils.rm("spec/Gemfile.lock")
      end

      it "overwrites the file" do
        expect do
          overwrite.copy_file("spec/Gemfile.lock")
          overwrite.save
        end.not_to change(directory, :head)
        expect(directory).to be_valid
        expect(directory.inventory.manifest.keys).not_to include before_keys.first
        expect(directory.inventory.manifest.values).to eq [["v1/content/Gemfile.lock"]]
        expect(directory.inventory.versions["v1"].state.values).to eq [["Gemfile.lock"]]
      end
    end
  end

  describe "#begin_new_version" do
    let(:object_root) { File.join(temp_dir, "abc123") }
    let(:builder) { OCFL::Object::DirectoryBuilder.new(object_root:, id: "http://example.com/minimal") }
    let(:directory) do
      builder.copy_file("spec/file1.xml")
      builder.save
    end
    let(:new_version) { directory.begin_new_version }

    context "with a file in the current directory" do
      let!(:before_keys) { directory.inventory.manifest.keys }

      around do |example|
        FileUtils.touch("spec/file1.xml")
        example.run
        FileUtils.rm("spec/file1.xml")
      end

      it "copies in the files from the previous version" do
        expect { new_version.save }.to change(directory, :head)
        expect(directory).to be_valid
        expect(directory.inventory.manifest.keys).to eq before_keys
        expect(directory.inventory.manifest.values).to eq [["v1/content/file1.xml"]]
        expect(directory.inventory.versions["v1"].state.values).to eq [["file1.xml"]]
      end
    end
  end
end
