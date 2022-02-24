require "parslet/rig/rspec"

RSpec.describe NistPubid::Parsers::NistTn do
  subject { described_class.new }
  it "consumes pt1 as part" do
    expect(subject.part).to parse("pt1")
  end

  context "when report number" do
    it "consumes addendum" do
      expect(subject.addendum.parse("-add")).to eq(addendum: "1")
    end
  end
end
