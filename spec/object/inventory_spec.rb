# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe OCFL::Object::Inventory do
  subject(:inventory) { described_class.new(file_name:) }

  around do |example|
    Dir.mktmpdir("ocfl-rspec-") do |dir|
      @file_name = "#{dir}/inventory.json"
      File.open(@file_name, "w") do |f|
        f.write content
      end
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
      let(:content) { '{"id":"123","type":"https://ocfl.io/1.1/spec/#inventory","digestAlgorithm":"md5","head":"v1","versions":{}}' }
      it { is_expected.to be_valid }
    end
  end

  describe "#id" do
    let(:content) { '{"id":"123","type":"https://ocfl.io/1.1/spec/#inventory","digestAlgorithm":"md5","head":"v1","versions":{}}' }
    subject { inventory.id }
    before do
      inventory.load
    end

    it { is_expected.to eq "123" }
  end

  describe "#head" do
    let(:content) { '{"id":"123","type":"https://ocfl.io/1.1/spec/#inventory","digestAlgorithm":"md5","head":"v1","versions":{}}' }
    subject { inventory.head }
    before do
      inventory.load
    end

    it { is_expected.to eq "v1" }
  end

  describe "#versions" do
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
    subject { inventory.versions }
    before do
      inventory.load
    end

    it { is_expected.to include("v1") }
  end
end
