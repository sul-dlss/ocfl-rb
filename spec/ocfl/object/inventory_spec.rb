# frozen_string_literal: true

RSpec.describe OCFL::Object::Inventory do
  subject(:inventory) { described_class.new(data:) }

  include_context "with temp directory"

  let(:data) do
    OCFL::Object::InventoryLoader.load(file_name).value!
  end
  let(:file_name) { "#{temp_dir}/inventory.json" }
  let(:content) do
    <<~JSON
      {
        "digestAlgorithm": "sha512",
        "head": "v1",
        "id": "http://example.org/minimal",
        "manifest": {
          "7545b8...f67": [ "v1/content/file.txt" ]
        },
        "type": "https://ocfl.io/1.1/spec/#inventory",
        "versions": {
          "v1": {
            "created": "2018-10-02T12:00:00Z",
            "message": "One file",
            "state": {
              "7545b8...f67": [ "file.txt" ]
            },
            "user": {
              "address": "mailto:alice@example.org",
              "name": "Alice"
            }
          }
        }
      }
    JSON
  end

  before { File.write(file_name, content) }

  describe "#id" do
    subject { inventory.id }

    it { is_expected.to eq "http://example.org/minimal" }
  end

  describe "#head" do
    subject { inventory.head }

    it { is_expected.to eq "v1" }
  end

  describe "#versions" do
    subject { inventory.versions }

    it { is_expected.to include("v1") }
  end

  describe "#manifest" do
    subject { inventory.manifest }

    it { is_expected.to include("7545b8...f67") }
  end
end
