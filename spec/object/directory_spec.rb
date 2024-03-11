# frozen_string_literal: true

RSpec.describe OCFL::Object::Directory do
  describe "#valid?" do
    context "when the directory doesn't exist" do
      it "is invalid"
    end

    context "when the NAMASTE doesn't exist" do
      it "is invalid"
    end

    context "when the inventory file doesn't exist" do
      it "is invalid"
    end

    context "when the inventory checksum doesn't exist" do
      it "is invalid"
    end

    context "when the inventory checksum doesn't match" do
      it "is invalid"
    end

    context "when the inventory isn't valid" do
      it "is invalid"
    end
  end
end
