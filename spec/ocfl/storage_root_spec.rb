# frozen_string_literal: true

RSpec.describe OCFL::StorageRoot do
  subject(:storage_root) { described_class.new(base_directory:) }

  include_context "with temp directory"

  describe "#base_directory" do
    it "returns the user-supplied base directory" do
      expect(storage_root.base_directory).to eq(base_directory)
    end
  end

  describe "#layout" do
    it "hard-codes a druid-tree layout" do
      expect(storage_root.layout).to be_a(OCFL::Layouts::DruidTree)
    end
  end

  describe "#exists?" do
    context "when directory is present" do
      it "returns true" do
        expect(storage_root).to exist
      end
    end

    context "when directory is missing" do
      before { FileUtils.rm_rf(base_directory) }

      it "returns false" do
        expect(storage_root).not_to exist
      end
    end
  end

  describe "#valid?" do
    context "when namaste file is present" do
      it "returns true" do
        expect(storage_root).to be_valid
      end
    end

    context "when namaste file is missing" do
      before { FileUtils.rm_f("#{base_directory}/0=ocfl_1.1") }

      it "returns false" do
        expect(storage_root).not_to be_valid
      end
    end
  end

  describe "#save" do
    context "when directory and namaste present" do
      it "returns nil" do
        expect(storage_root.save).to be_nil
      end
    end

    context "when directory is missing" do
      before do
        FileUtils.rm_rf(base_directory)
        allow(FileUtils).to receive(:mkdir_p).and_call_original
        allow(FileUtils).to receive(:cp).and_call_original
        allow(storage_root.layout).to receive(:save).and_call_original
      end

      it "creates the directory and returns true" do
        expect(storage_root.save).to be true
        expect(FileUtils).to have_received(:mkdir_p).with(Pathname.new(base_directory)).once
        expect(FileUtils).to have_received(:mkdir_p)
          .with(Pathname.new(base_directory) / "extensions" / "0010-differential-n-tuple-omit-prefix-storage-layout")
          .once
        expect(FileUtils).to have_received(:cp).once
        expect(storage_root.layout).to have_received(:save).once
      end
    end

    # layout.save
    context "when namaste file is missing" do
      before do
        FileUtils.rm_f("#{base_directory}/0=ocfl_1.1")
        allow(FileUtils).to receive(:touch).and_call_original
        allow(FileUtils).to receive(:cp).and_call_original
        allow(storage_root.layout).to receive(:save).and_call_original
      end

      it "creates the namaste file and returns true" do
        expect(storage_root.save).to be true
        expect(FileUtils).to have_received(:touch).once
        expect(FileUtils).to have_received(:cp).once
        expect(storage_root.layout).to have_received(:save).once
      end
    end
  end

  describe "#object" do
    subject(:object) { storage_root.object(identifier) }

    let(:identifier) { "bc123df4567" }

    it "returns an OCFL::Object instance with the expected root directory" do
      expect(object).to be_an(OCFL::Object)
      expect(object.root.to_path).to eq("#{base_directory}/bc/123/df/4567")
    end
  end
end
