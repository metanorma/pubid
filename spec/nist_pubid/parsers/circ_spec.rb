require "parslet/rig/rspec"

RSpec.describe Pubid::Nist::Parsers::Circ do
  subject { described_class.new }

  context "when supplement" do
    it "consumes supplement without supplement number" do
      expect(subject.supplement.parse("sup")).to eq(supplement: [])
    end
  end
end
