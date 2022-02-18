require "parslet/rig/rspec"

RSpec.describe NistPubid::Parsers::NbsHb do
  subject { described_class.new }

  context "when report number with edition" do
    it "skips edition year" do
      expect(subject.report_number.parse("44e2-1955")).to eq(first_report_number: "44", edition: "2")
    end

    it "parses 105-1-1990" do
      expect(subject.report_number.parse("105-1-1990")).to eq(first_report_number: "105",
                                                              second_report_number: "1",
                                                              edition_year: "1990")
    end
  end
end
