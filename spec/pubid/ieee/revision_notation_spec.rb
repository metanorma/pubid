# frozen_string_literal: true

require "spec_helper"

# IEEE revision-notation dialects from the relaton-ieee normtitle feed. pubid
# already accepts the canonical "…/D<n>/R-<x>" form; these variants (REV/Rev
# glued or separated by -, /, _, ., or space, before or after the draft) mean
# the same revision and are normalized to it before parsing.
# (hand-off: ieee-revision-notation-grammar.)
RSpec.describe "IEEE revision-notation variants" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # variant => canonical equivalent (must parse to the same to_hash)
  {
    "IEEE Std P802.16.2-REVa/D8" => "IEEE Std P802.16.2/D8/R-a",
    "IEEE Std P802.16/REVd/D5" => "IEEE Std P802.16/D5/R-d",
    "IEEE Std P802.15.1REVa/D5" => "IEEE Std P802.15.1/D5/R-a",
    "IEEE Std P802.16_Rev2/D5" => "IEEE Std P802.16/D5/R-2",
    "IEEE Std P1310.Rev 3/D2" => "IEEE Std P1310/D2/R-3",
  }.each do |variant, canonical|
    context variant.inspect do
      it "parses to the same identifier as its canonical /R- form" do
        expect(klass.parse(variant).to_hash)
          .to eq(klass.parse(canonical).to_hash)
      end

      it "round-trips through to_hash/from_hash" do
        h = klass.parse(variant).to_hash
        expect(klass.from_hash(h).to_hash).to eq(h)
      end
    end
  end

  it "does not mangle the word 'Revision' in a parenthetical" do
    ref = "IEEE Std 802.16-2004 (Revision of IEEE Std 802.16-2001)"
    expect { klass.parse(ref) }.not_to raise_error
    expect(klass.parse(ref).to_s).to include("Revision")
  end
end
