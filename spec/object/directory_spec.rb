# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe OCFL::Object::Directory do
  subject(:directory) { described_class.new(object_root:) }

  describe "#valid?" do
    context "when the directory doesn't exist" do
      let(:object_root) { "/non-existing" }

      it { is_expected.not_to be_valid }
    end

    context "when the NAMASTE doesn't exist" do
      around do |example|
        Dir.mktmpdir("ocfl-rspec-") do |dir|
          FileUtils.touch("#{dir}/inventory.json")
          @temp_dir = dir
          example.run
        end
      end

      let(:object_root) { @temp_dir }

      it { is_expected.not_to be_valid }
    end

    context "when the inventory file doesn't exist" do
      around do |example|
        Dir.mktmpdir("ocfl-rspec-") do |dir|
          FileUtils.touch("#{dir}/0=ocfl_object_1.1")
          @temp_dir = dir
          example.run
        end
      end

      let(:object_root) { @temp_dir }
      it { is_expected.not_to be_valid }
    end

    context "when the inventory checksum doesn't exist" do
      around do |example|
        Dir.mktmpdir("ocfl-rspec-") do |dir|
          FileUtils.touch("#{dir}/0=ocfl_object_1.1")
          FileUtils.touch("#{dir}/inventory.json")
          @temp_dir = dir
          example.run
        end
      end

      let(:object_root) { @temp_dir }
      it { is_expected.not_to be_valid }
    end

    context "when the inventory checksum doesn't match" do
      around do |example|
        Dir.mktmpdir("ocfl-rspec-") do |dir|
          FileUtils.touch("#{dir}/0=ocfl_object_1.1")
          FileUtils.touch("#{dir}/inventory.json")
          File.open("#{dir}/inventory.json.sha512", "w") do |f|
            # rubocop:disable Layout/LineLength
            f.write "31598ebd1468eaa3b082afafdc90e500f32502d8824696dcc6674c9ccddb8fecd4bb4f0495a49d8ae83922c332e8ebdf0e34988589dbc3dfa6acaedf9b706870  inventory.json"
            # rubocop:enable Layout/LineLength
          end
          @temp_dir = dir
          example.run
        end
      end

      let(:object_root) { @temp_dir }
      it { is_expected.not_to be_valid }
    end

    context "when the inventory isn't valid" do
      around do |example|
        Dir.mktmpdir("ocfl-rspec-") do |dir|
          FileUtils.touch("#{dir}/0=ocfl_object_1.1")
          FileUtils.touch("#{dir}/inventory.json")
          File.open("#{dir}/inventory.json", "w") do |f|
            f.write '{"manifest":{}}'
          end
          File.open("#{dir}/inventory.json.sha512", "w") do |f|
            # rubocop:disable Layout/LineLength
            f.write "dd95136fa794284f8ffd5eb444b2b08732aa3f4d0d08a5f20b1c03a182294c34501066ac4b02159d38bcb6c8557fc724c636929775212c5194984d68cb1508a1  inventory.json"
            # rubocop:enable Layout/LineLength
          end
          @temp_dir = dir
          example.run
        end
      end
      let(:object_root) { @temp_dir }
      it { is_expected.not_to be_valid }
    end
  end
end
