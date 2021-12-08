RSpec.describe NistPubid::Stage do
  let(:short_stage) { "NIST SP 800-18(IPD)" }
  let(:long_stage) { "Initial Public Draft" }

  it "returns long title for stage" do
    expect(described_class.parse(short_stage).to_s(:long))
      .to eq(long_stage)
  end

  it "keeps original code" do
    expect(described_class.parse(short_stage).original_code).to eq("(IPD)")
  end
end
