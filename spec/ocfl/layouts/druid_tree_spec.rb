# frozen_string_literal: true

RSpec.describe OCFL::Layouts::DruidTree do
  subject(:layout) { described_class }

  describe ".path_to" do
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
end
