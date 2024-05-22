# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe OCFL::Object::InventoryLoader do
  subject(:data) { described_class.load(file_name) }

  include_context "with temp directory"

  let(:file_name) { "#{temp_dir}/inventory.json" }

  before { File.write(file_name, content) }

  describe "#load" do
    context "when it is the wrong schema" do
      let(:content) { '{"manifest":{}}' }

      it { is_expected.to be_failure }
    end

    context "when it is the right schema" do
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

      it { is_expected.to be_success }
    end
  end
end
