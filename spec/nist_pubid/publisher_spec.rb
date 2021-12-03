RSpec.describe NistPubid::Publisher do
  let(:short_publisher) { 'NIST' }
  let(:long_publisher) { 'National Institute of Standards and Technology' }

  it 'returns long title for publisher' do
    expect(described_class.new(publisher: short_publisher).to_s(:long))
      .to eq(long_publisher)
  end
end
