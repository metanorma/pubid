RSpec.describe NistPubid::Stage do
  let(:short_stage) { "NIST SP 800-18(IPD)" }
  let(:long_stage) { "Initial Public Draft" }

  it "returns long title for stage" do
    expect(described_class.new("IPD").to_s(:long))
      .to eq(long_stage)
  end
end
