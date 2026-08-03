# frozen_string_literal: true

require "spec_helper"

# IEEE revision-notation dialects from the relaton-ieee normtitle feed (REV/Rev
# glued or separated by -, /, _, ., or space, before or after the draft).
#
# NUMBERED revisions ("Rev<digits>") are now PRESERVED — repositioned to the
# canonical "…/D<n>/R-<x>" suffix, which the revision_suffix grammar rule
# captures into the `revision` attribute (nil-residue / numbered-revision
# hand-offs). LETTERED inline revisions ("REVa"/"REVd"/"REVmb") remain
# STRIPPED: repositioning lettered forms regressed 28 normtitles (they often
# carry a trailing date/parenthetical the reorder broke), and no hand-off asks
# for lettered-inline preservation — so a lettered-inline variant collapses onto
# its base standard (revision nil). The lettered *suffix* form "/R-a" IS
# preserved (see nil_residue_spec) — only the *inline* lettered dialect strips.
# (hand-off: ieee-revision-notation-grammar, ieee-numbered-revision.)
RSpec.describe "IEEE revision-notation variants" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # NUMBERED variant => canonical /R- form (revision preserved, same to_hash)
  {
    "IEEE Std P802.16_Rev2/D5" => "IEEE Std P802.16/D5/R-2",
    "IEEE Std P1310.Rev 3/D2" => "IEEE Std P1310/D2/R-3",
  }.each do |variant, canonical|
    context variant.inspect do
      it "parses to the same identifier as its canonical /R- form" do
        expect(klass.parse(variant).to_hash)
          .to eq(klass.parse(canonical).to_hash)
      end

      it "preserves the numbered revision" do
        expect(klass.parse(variant).revision).not_to be_nil
      end

      it "round-trips through to_hash/from_hash" do
        h = klass.parse(variant).to_hash
        expect(klass.from_hash(h).to_hash).to eq(h)
      end
    end
  end

  # LETTERED inline variant => base (revision stripped, collapses onto the base)
  {
    "IEEE Std P802.16.2-REVa/D8" => "IEEE Std P802.16.2/D8",
    "IEEE Std P802.16/REVd/D5" => "IEEE Std P802.16/D5",
    "IEEE Std P802.15.1REVa/D5" => "IEEE Std P802.15.1/D5",
  }.each do |variant, base|
    context variant.inspect do
      it "strips the lettered inline revision (collapses onto its base)" do
        expect(klass.parse(variant).to_hash).to eq(klass.parse(base).to_hash)
        expect(klass.parse(variant).revision).to be_nil
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
    parsed = klass.parse(ref)
    # The "Revision of …" narrative is a relationship, not an inline revision
    # notation: it must be parsed as a revision_of relationship (proving the
    # word "Revision" wasn't mangled into a Rev token) and kept off the bounded
    # to_s.
    expect(parsed.to_s).to eq("IEEE Std 802.16-2004")
    expect(parsed.relationships.first.relationship_type).to eq("revision_of")
    expect(parsed.revision).to be_nil
  end
end
