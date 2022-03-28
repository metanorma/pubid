require "parslet/rig/rspec"

RSpec.describe Pubid::Ieee::Parser do
  subject { described_class.new }

  it "parses draft date" do
    expect(subject.draft_date).to parse(", Feb 6, 2007")
  end

  it "parses part" do
    expect(subject.part_subpart_year).to parse("-20601a", trace: true)
  end

  it "don't parse identifier with extra space" do
    expect(subject.parameters).not_to parse(" C22-1925", trace: true)
  end

  it "parses previous amendments" do
    expect(subject.previous_amendments).to parse(" as"\
      " amended by IEEE Std 802.15.3d-2017, and IEEE Std 802.15.3e-2017", trace: true)
  end

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
