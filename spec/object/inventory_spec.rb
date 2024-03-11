# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe OCFL::Object::Inventory do
  subject(:directory) { described_class.new(file_name:) }

  describe "#valid?" do
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

    context "when it is the wrong schema" do
      let(:content) { '{"manifest":{}}' }
      it { is_expected.not_to be_valid }
    end

    context "when it is the right schema" do
      let(:content) { '{"id":"123","type":"https://ocfl.io/1.1/spec/#inventory","digestAlgorithm":"md5","head":"v001"}' }
      it { is_expected.to be_valid }
    end
  end
end