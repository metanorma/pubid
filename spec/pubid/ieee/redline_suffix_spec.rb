# frozen_string_literal: true

require "spec_helper"

# A redline is a DISTINCT document from its base standard, but pubid used to
# silently drop the trailing "Redline" suffix (the space form was stripped in
# preprocessing; the " - Redline" dash form failed to parse). Now both spellings
# are parsed into a `redline: true` flag the renderer restores, so a redline id
# no longer collides with its base in the relaton index.
# (hand-off: ieee-redline-suffix-parsing.)
RSpec.describe "IEEE redline suffix" do
  subject(:klass) { Pubid::Ieee::Identifier }

  [
    "IEEE Std 802.16-2012 Redline",
    "ANSI C63.10-2013 Redline",
    "IEEE Std 802.16-2012 - Redline",
    "IEEE Std 1018-2013 (Revision of IEEE Std 1018-2004) - Redline",
  ].each do |ref|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "parses without raising" do
        expect { id }.not_to raise_error
      end

      it "sets the redline flag" do
        expect(id.to_hash["redline"]).to be(true)
      end

      it "restores the Redline suffix in to_s" do
        expect(id.to_s).to match(/Redline\z/)
      end

      it "round-trips through to_hash/from_hash" do
        h = id.to_hash
        expect(klass.from_hash(h).to_hash).to eq(h)
      end
    end
  end

  it "renders distinctly from its base standard (no collision)" do
    base = klass.parse("IEEE Std 802.16-2012")
    redline = klass.parse("IEEE Std 802.16-2012 Redline")
    expect(redline.to_s).not_to eq(base.to_s)
    expect(redline.to_hash).not_to eq(base.to_hash)
  end
end
