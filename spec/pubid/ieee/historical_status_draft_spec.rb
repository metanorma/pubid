# frozen_string_literal: true

require "spec_helper"

# Historical status-word draft designations from relaton-data-ieee:
# "IEEE  Active Std P…/D-…" and "IEEE Unapproved Std P…/D-…". The
# ieee_approved_draft_identifier rule handled only "Approved"; widen the status
# word to also accept "Unapproved" and "Active" (the crawler's double space is
# already collapsed by whitespace normalization). Best-effort: the status word
# is dropped, yielding a round-tripping Std draft. Only the numeric-date rows
# round-trip; the text-month rows (bucket 2, "…-Sept") remain crawl junk.
# (hand-off: ieee-numberless-standard-parse roadmap, bucket 3.)
RSpec.describe "IEEE historical status-word drafts" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # ref => bare root.number
  {
    "IEEE  Active Std P12207.0/D-2-2007-07" => "12207",
    "IEEE  Active Std P802.11k/D-8.0-2007-05" => "802",
    "IEEE  Active Std PC37.59/D-11-2007-07" => "C37",
  }.each do |ref, number|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "exposes a non-empty root.number" do
        expect(id.root.number).to eq(number)
      end

      it "round-trips through to_hash/from_hash (the relaton index gate)" do
        h = id.to_hash
        expect(klass.from_hash(h).to_hash).to eq(h)
      end
    end
  end
end
