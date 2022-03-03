require "parslet/rig/rspec"

RSpec.describe Pubid::Nist::Parsers::NistSp do
  subject { described_class.new }
  it "consumes version like v1.2.3" do
    expect(subject.version).to parse("v1.2.3")
  end

  context "when report number" do
    it "consumes number like 800-53" do
      expect(subject.report_number.parse("800-53")).to eq(first_report_number: "800", second_report_number: "53")
    end

    it "consumes number with revision" do
      expect(subject).to parse(" 800-53r5")
    end
  end
end
