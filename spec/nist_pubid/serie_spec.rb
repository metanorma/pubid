RSpec.describe NistPubid::Serie do
  let(:short_serie) { 'NIST SP' }
  let(:long_serie) { 'Special Publication' }

  it 'returns long title for serie' do
    expect(described_class.new(serie: short_serie).to_s(:long))
      .to eq(long_serie)
  end
end
