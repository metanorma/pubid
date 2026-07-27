# frozen_string_literal: true

require "spec_helper"

# The draft + corrigendum combined form (relaton's `…/D-N/CorM-YYYY`, normalized
# to `…/Cor M-YYYY/D N`) parsed to a Corrigendum with a nil `base`, so `to_s` was
# lossy on a fresh parse (" P802.16/D5") and empty after a hash round-trip. The
# builder must reconstruct a real base standard (with its draft) and wrap it.
RSpec.describe "IEEE draft + corrigendum combined form" do
  subject(:ref) { "IEEE Std P802.16-2004/D-5/Cor1-2005" }

  let(:parsed) { Pubid::Ieee::Identifier.parse(ref) }

  it "is a Corrigendum with a non-nil base" do
    expect(parsed).to be_a(Pubid::Ieee::Identifiers::Corrigendum)
    expect(parsed.base).not_to be_nil
  end

  it "renders a non-empty to_s carrying the corrigendum and base draft" do
    expect(parsed.to_s).not_to be_empty
    expect(parsed.to_s).to include("Cor")
    expect(parsed.to_s).to include("802.16")
    expect(parsed.to_s).to include("D5")
    expect(parsed.to_s).not_to start_with(" ")
  end

  it "renders identically after a to_hash/from_hash round-trip" do
    h = parsed.to_hash
    rebuilt = Pubid::Ieee::Identifier.from_hash(h)
    expect(rebuilt.to_s).to eq(parsed.to_s)
    expect(rebuilt.to_s).not_to be_empty
  end

  it "round-trips through to_hash" do
    h = parsed.to_hash
    expect(Pubid::Ieee::Identifier.from_hash(h).to_hash).to eq(h)
  end

  it "exposes the corrigendum number and year" do
    expect(parsed.number).to eq("1")
    expect(parsed.year).to eq("2005")
  end
end
