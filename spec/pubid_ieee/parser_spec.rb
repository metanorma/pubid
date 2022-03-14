require "parslet/rig/rspec"

RSpec.describe Pubid::Ieee::Parser do
  subject { described_class.new }

  describe "parse identifiers from examples files" do
    shared_examples "parse identifiers from file" do
      it "parse identifiers from file" do
        f = open("spec/fixtures/#{examples_file}")
        f.readlines.each do |pub_id|
          next if pub_id.match?("^#")
          expect(subject).to parse(pub_id.split("#").first.strip.chomp)
        end
      end
    end

    context "parses identifiers from pubid-parsed.txt" do
      let(:examples_file) { "pubid-parsed.txt" }

      it_behaves_like "parse identifiers from file"
    end
  end
end
