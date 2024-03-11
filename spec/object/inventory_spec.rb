# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe OCFL::Object::Inventory do
  subject(:inventory) { described_class.new(file_name:) }
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

  before do
    inventory.load
  end

  around do |example|
    Dir.mktmpdir("ocfl-rspec-") do |dir|
      @file_name = "#{dir}/inventory.json"
      File.write(@file_name, content)
      example.run
    end
  end
  let(:file_name) { @file_name }

  describe "#valid?" do
    context "when it is the wrong schema" do
      let(:content) { '{"manifest":{}}' }
      it { is_expected.not_to be_valid }
    end

    context "when it is the right schema" do
      it { is_expected.to be_valid }
    end
  end

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
