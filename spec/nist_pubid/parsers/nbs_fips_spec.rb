require "parslet/rig/rspec"

RSpec.describe Pubid::Nist::Parsers::NbsFips do
  subject { described_class.new }

  context "when edition" do
    it "consumes edition with day" do
      expect(subject.parse(" 11-1-Sep30/1977"))
        .to include(edition_year: "1977", edition_month: "Sep", edition_day: "30")
    end
  end
end
