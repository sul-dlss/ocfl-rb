# frozen_string_literal: true

RSpec.describe OCFL::Layouts::DruidTree do
  subject(:layout) { described_class.new(base_directory:) }

  include_context "with temp directory"

  describe "#path_to" do
    subject(:path) { layout.path_to(identifier) }

    context "with a well-formed druid" do
      let(:identifier) { "bc123df4567" }

      it "returns a druid-tree path" do
        expect(path.to_path).to eq("bc/123/df/4567")
      end
    end

    context "with a malformed druid" do
      let(:identifier) { "345aa987ii" }

      it "raises a runtime error" do
        expect { path.to_path }.to raise_error(RuntimeError, "druid '#{identifier}' is invalid")
      end
    end
  end

  describe "#save" do
    before do
      layout.save
    end

    it "writes a layout file to the storage root" do
      expect(File.read(base_directory / "ocfl_layout.json")).to eq(layout.send(:to_layout_json))
    end

    it "writes extension config to the extension subdirectory" do
      expect(File.read(base_directory / "extensions" / layout.send(:extension_name) / "config.json"))
        .to eq(layout.send(:to_config_json))
    end
  end
end
