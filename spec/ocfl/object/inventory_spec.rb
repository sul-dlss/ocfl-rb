# frozen_string_literal: true

RSpec.describe OCFL::Object::Inventory do
  subject(:inventory) { described_class.new(data:) }

  include_context "with temp directory"

  let(:data) do
    OCFL::Object::InventoryLoader.load(file_name).value!
  end
  let(:file_name) { "#{base_directory}/inventory.json" }
  let(:content) do
    <<~JSON
      {
        "digestAlgorithm": "sha512",
        "head": "v3",
        "id": "http://example.org/minimal",
        "manifest": {
          "123456...fed": [ "v1/content/other.txt" ],
          "7545b8...f67": [ "v1/content/file.txt" ],
          "8656c9...178": [ "v2/content/file.txt" ],
          "9767d0...289": [ "v3/content/file.txt" ]
        },
        "type": "https://ocfl.io/1.1/spec/#inventory",
        "versions": {
          "v1": {
            "created": "2018-10-02T12:00:00Z",
            "message": "Two files",
            "state": {
              "7545b8...f67": [ "file.txt" ],
              "123456...fed": [ "other.txt" ]
            },
            "user": {
              "address": "mailto:alice@example.org",
              "name": "Alice"
            }
          },
          "v2": {
            "created": "2020-01-02T12:00:00Z",
            "message": "Updated file.txt",
            "state": {
              "8656c9...178": [ "file.txt" ],
              "123456...fed": [ "other.txt" ]
            },
            "user": {
              "address": "mailto:alice@example.org",
              "name": "Alice"
            }
          },
          "v3": {
            "created": "2023-04-12T12:00:00Z",
            "message": "Finally finished file.txt",
            "state": {
              "9767d0...289": [ "file.txt" ],
              "123456...fed": [ "other.txt" ]
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

    it { is_expected.to eq "v3" }
  end

  describe "#versions" do
    subject { inventory.versions }

    it { is_expected.to include("v1") }
    it { is_expected.to include("v2") }
    it { is_expected.to include("v3") }
  end

  describe "#manifest" do
    subject { inventory.manifest }

    it { is_expected.to include("7545b8...f67") }
    it { is_expected.to include("8656c9...178") }
    it { is_expected.to include("9767d0...289") }
    it { is_expected.to include("123456...fed") }
  end

  describe "#path" do
    subject { inventory.path("file.txt") }

    it { is_expected.to eq("v3/content/file.txt") }

    context "when path is for file not in state of head version" do
      subject { inventory.path("other.txt") }

      it { is_expected.to eq("v1/content/other.txt") }
    end

    context "when path is not found in the manifest" do
      subject { inventory.path("ghosts.txt") }

      it { is_expected.to be_nil }
    end
  end
end
