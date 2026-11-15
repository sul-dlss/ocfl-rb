# frozen_string_literal: true

require "fileutils"

RSpec.describe OCFL::Object do
  subject(:object) { described_class.new(root: object_root, identifier:) }

  let(:identifier) { "abc123" }
  let(:object_root) { File.join(base_directory, identifier) }

  before { FileUtils.mkdir_p(object_root) }

  include_context "with temp directory"

  describe "#exists?" do
    context "when the namaste file exists" do
      before { FileUtils.touch("#{object_root}/0=ocfl_object_1.1") }

      it "returns true" do
        expect(object).to exist
      end
    end

    context "when the namaste file does not exist" do
      it "returns false" do
        expect(object).not_to exist
      end
    end
  end

  describe "#valid?" do
    context "when the directory doesn't exist" do
      let(:identifier) { "non-existent" }

      it { is_expected.not_to be_valid }
    end

    context "when the namaste file doesn't exist" do
      before { FileUtils.touch("#{object_root}/inventory.json") }

      it { is_expected.not_to be_valid }
    end

    context "when the inventory file doesn't exist" do
      before { FileUtils.touch("#{object_root}/0=ocfl_object_1.1") }

      it { is_expected.not_to be_valid }
    end

    context "when the inventory checksum doesn't exist" do
      before do
        FileUtils.touch("#{object_root}/0=ocfl_object_1.1")
        FileUtils.touch("#{object_root}/inventory.json")
      end

      it { is_expected.not_to be_valid }
    end

    context "when the inventory checksum doesn't match" do
      before do
        FileUtils.touch("#{object_root}/0=ocfl_object_1.1")
        FileUtils.touch("#{object_root}/inventory.json")
        File.write("#{object_root}/inventory.json.sha512",
                   "31598ebd1468eaa3b082afafdc90e500f32502d8824696dcc6674c9ccddb8fecd4bb4f0495a49d8ae83" \
                   "922c332e8ebdf0e34988589dbc3dfa6acaedf9b706870  inventory.json")
      end

      it { is_expected.not_to be_valid }
    end

    context "when the inventory isn't valid" do
      before do
        FileUtils.touch("#{object_root}/0=ocfl_object_1.1")
        FileUtils.touch("#{object_root}/inventory.json")
        File.write("#{object_root}/inventory.json", '{"manifest":{}}')
        File.write("#{object_root}/inventory.json.sha512",
                   "dd95136fa794284f8ffd5eb444b2b08732aa3f4d0d08a5f20b1c03a182294c34501066ac4b02159d38b" \
                   "cb6c8557fc724c636929775212c5194984d68cb1508a1  inventory.json")
      end

      it { is_expected.not_to be_valid }
    end
  end

  describe "#path" do
    before do
      object.begin_new_version.tap do |version|
        version.copy_file("spec/fixtures/files/file1.txt", destination_path: "file1.txt")
        version.save
      end
      object.begin_new_version.tap do |version|
        version.copy_recursive("sig/")
        version.save
      end
    end

    it "returns the path from the specified version's inventory" do
      expect(object.path(filepath: "ocfl.rbs", version: "v2"))
        .to eq(Pathname.new(object.root) / "v2/content/#{OCFL_RBS_DIGEST}")
    end

    context "when the filepath does not exist" do
      it "raises a FileNotFound exception" do
        expect { object.path(filepath: "ocfl.rbs", version: "v1") }
          .to raise_error(OCFL::Object::FileNotFound, /Path 'ocfl.rbs' not found in v1 inventory/)
      end
    end

    context "when version is nil" do
      it "returns the path from the object's inventory" do
        expect(object.path(filepath: "file1.txt"))
          .to eq(Pathname.new(object.root) / "v1/content/#{FILE1_TXT_DIGEST}")
      end

      context "when the filepath does not exist" do
        it "raises a FileNotFound exception" do
          expect { object.path(filepath: "image.jp2") }
            .to raise_error(OCFL::Object::FileNotFound, /Path 'image.jp2' not found in v2 inventory/)
        end
      end
    end
  end

  describe "#overwrite_current_version" do
    let(:overwrite) { object.overwrite_current_version }

    before do
      object.begin_new_version.tap do |version|
        version.copy_file("spec/fixtures/file1.txt", destination_path: "file1.txt")
        version.save
      end
    end

    context "with a file in the current object" do
      let!(:before_keys) { object.inventory.manifest.keys }

      around do |example|
        FileUtils.touch("spec/file1.txt")
        example.run
      ensure
        FileUtils.rm("spec/file1.txt")
      end

      it "overwrites the file" do
        expect do
          overwrite.copy_file("spec/file1.txt", destination_path: "file1.txt")
          overwrite.save
        end.not_to change(object, :head)
        expect(object).to be_valid
        expect(object.inventory.manifest.keys).not_to include before_keys.first
        expect(object.inventory.manifest.values).to eq [["v1/content/#{EMPTY_FILE_DIGEST}"]]
        expect(object.inventory.versions["v1"].state.values).to eq [["file1.txt"]]
      end
    end
  end

  describe "#begin_new_version" do
    let(:new_version) { object.begin_new_version }

    before do
      object.begin_new_version.tap do |version|
        version.copy_file("spec/file1.xml")
        version.save
      end
    end

    context "with a file in the current directory" do
      let!(:before_keys) { object.inventory.manifest.keys }

      around do |example|
        FileUtils.touch("spec/file1.xml")
        example.run
        FileUtils.rm("spec/file1.xml")
      end

      it "copies in the files from the previous version" do
        expect { new_version.save }.to change(object, :head)
        expect(object).to be_valid
        expect(object.inventory.manifest.keys).to eq before_keys
        expect(object.inventory.manifest.values).to eq [["v1/content/#{EMPTY_FILE_DIGEST}"]]
        expect(object.inventory.versions["v1"].state.values).to eq [["file1.xml"]]
      end
    end
  end

  describe "#head_version" do
    let(:new_version) { object.head_version }

    before do
      object.begin_new_version.tap do |version|
        version.copy_file("spec/file1.xml")
        version.save
      end
    end

    context "with a file in the current object" do
      let!(:before_keys) { object.inventory.manifest.keys }

      around do |example|
        FileUtils.touch("spec/file1.xml")
        example.run
        FileUtils.rm("spec/file1.xml")
      end

      it "opens the head version" do
        expect { new_version.save }.not_to change(object, :head)
        expect(object).to be_valid
        expect(object.inventory.manifest.keys).to eq before_keys
        expect(object.inventory.manifest.values).to eq [["v1/content/#{EMPTY_FILE_DIGEST}"]]
        expect(object.inventory.versions["v1"].state.values).to eq [["file1.xml"]]
      end
    end
  end
end
