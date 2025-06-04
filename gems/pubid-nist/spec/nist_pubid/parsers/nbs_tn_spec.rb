require "parslet/rig/rspec"

RSpec.describe Pubid::Nist::Parsers::Tn do
  subject { described_class.new }
  it "consumes pt1 as part" do
    expect(subject.part).to parse("pt1")
  end

  it "consumes addendum" do
    expect(subject.addendum).to parse("-add")
  end
end
