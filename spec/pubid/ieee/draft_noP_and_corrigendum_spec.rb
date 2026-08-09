# frozen_string_literal: true

require "spec_helper"

# `ieee_draft_p_identifier` ("IEEE [<status>] Draft P<n>/D<n>") had two gaps
# skipped ~11 relaton-data-ieee index-v2 drafts:
#   Gap 1 — the number had to be P-prefixed (str("P") was mandatory), so a
#           status-word draft with a bare number failed, inconsistent with
#           ieee_approved_draft_identifier (str("P").maybe).
#   Gap 2 — no corrigendum in the sequence, so a trailing "/Cor. N" failed.
RSpec.describe "IEEE draft-P optional-P and trailing corrigendum" do
  # Gap 1: status-word draft with a bare (non-P) number.
  bare_number_forms = [
    "IEEE Unapproved Draft 802.1ah/D4.2, Mar 2008",
    "IEEE Unapproved Draft 802.20/D3.1m, Dec 2007",
    "IEEE Unapproved Draft C57.15/D8.6, Jun 2009",
    "IEEE Unapproved Draft 11073-10471/D02, Feb 2008",
  ]

  # Gap 2: trailing corrigendum after the draft (with or without a date).
  corrigendum_forms = [
    "IEEE Unapproved Draft P802.1ak/D1.0, Dec 2007/Cor. 1",
    "IEEE Unapproved Draft P802.1ak/D2.0/Cor. 1",
    "IEEE Unapproved Draft P802.3/D2.0, Mar 2007/Cor. 2",
  ]

  # Hits both gaps: bare number AND trailing corrigendum.
  both_gaps_ref = "IEEE Unapproved Draft C37.04/DB2, Apr 2009/Cor. 1"

  describe "Gap 1 — bare (non-P) number parses" do
    bare_number_forms.each do |ref|
      it "parses #{ref.inspect}" do
        expect { Pubid::Ieee::Identifier.parse(ref) }.not_to raise_error
      end

      it "round-trips the hash and keeps root.number for #{ref.inspect}" do
        id = Pubid::Ieee::Identifier.parse(ref)
        hash = id.to_hash
        expect(Pubid::Ieee::Identifier.from_hash(hash).to_hash).to eq(hash)
        expect(id.root.number.to_s).not_to be_empty
      end
    end
  end

  describe "Gap 2 — trailing corrigendum parses and is retained" do
    corrigendum_forms.each do |ref|
      it "parses #{ref.inspect} as a Corrigendum" do
        id = Pubid::Ieee::Identifier.parse(ref)
        expect(id).to be_a(Pubid::Ieee::Identifiers::Corrigendum)
      end

      it "round-trips the hash and keeps root.number for #{ref.inspect}" do
        id = Pubid::Ieee::Identifier.parse(ref)
        hash = id.to_hash
        expect(Pubid::Ieee::Identifier.from_hash(hash).to_hash).to eq(hash)
        expect(id.root.number.to_s).not_to be_empty
      end
    end
  end

  describe "both gaps at once" do
    [both_gaps_ref].each do |ref|
      it "parses #{ref.inspect} as a Corrigendum and round-trips" do
        id = Pubid::Ieee::Identifier.parse(ref)
        expect(id).to be_a(Pubid::Ieee::Identifiers::Corrigendum)
        hash = id.to_hash
        expect(Pubid::Ieee::Identifier.from_hash(hash).to_hash).to eq(hash)
        expect(id.root.number.to_s).not_to be_empty
      end
    end
  end

  describe "does not disturb the existing P-form" do
    p_form = "IEEE Unapproved Draft P802.1ah/D4.2, Mar 2008"

    [p_form].each do |ref|
      it "still parses the status + P draft #{ref.inspect}" do
        expect { Pubid::Ieee::Identifier.parse(ref) }.not_to raise_error
      end
    end
  end
end
