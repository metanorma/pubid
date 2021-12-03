RSpec.describe NistPubid::Stage do
  let(:short_stage) { "IPD" }
  let(:long_stage) { "Initial Public Draft " }

  it "returns long title for stage" do
    expect(described_class.new(stage: short_stage).to_s(:long))
      .to eq(long_stage)
  end
end
