# frozen_string_literal: true

RSpec.describe OCFL::Object::Version do
  let(:version) do
    described_class.new(name: "v2", created: Time.parse("1992-09-22").iso8601,
                        state: {
                          "573c...992e5" => ["file1.txt"],
                          "2d85...71458" => ["file2.xml"]
                        })
  end
  describe "#file_names" do
    subject { version.file_names }

    it { is_expected.to eq ["file1.txt", "file2.xml"] }
  end
end
