# frozen_string_literal: true

require "spec_helper"

# The small residue of relaton-data-ieee normtitles pubid used to return nil /
# ParseFailed for (hand-offs: ieee-numbered-revision, ieee-nil-residue). Three
# families:
#   1. numbered/lettered revisions — IEEE's native inline "Rev<n>" and relaton's
#      synthetic "/R-<x>" suffix, composing with a draft (incl. the empty-draft
#      "/D-/R-<x>" = revision-only form);
#   2. an edition suffix "/E-<n>" (relaton's spelling of "<n>th Ed");
#   3. the "ANS" (American Nuclear Society) third co-publisher.
RSpec.describe "IEEE nil-residue forms" do
  subject(:klass) { Pubid::Ieee::Identifier }

  def parses(str)
    klass.parse(str)
  rescue Parslet::ParseFailed
    nil
  end

  describe "numbered / lettered revisions" do
    # ref => revision id that must survive (revision preserved, not merged
    # into the base). Native inline spellings from the IEEE feed.
    {
      "IEEE P802.16Rev2/D3" => "2",
      "IEEE P802.16_Rev2/D3" => "2",
      "IEEE P1310.Rev 3/D2" => "3",
      "IEEE P1722-rev1" => "1",
      "IEEE P802.16Rev2/D9a" => "2",
      "IEEE PC37.30.2/D043 Rev 18" => "18",
    }.each do |ref, rev|
      context ref.inspect do
        let(:id) { parses(ref) }

        it "parses (non-nil)" do
          expect(id).not_to be_nil
        end

        it "preserves the revision #{rev.inspect}" do
          expect(id.revision).to eq(rev)
        end

        it "does not collide with its revisionless base" do
          base = ref.sub(/[-._ ]?[Rr]ev ?\d+/, "")
          expect(id.to_s).not_to eq(klass.parse(base).to_s)
        end

        it "round-trips through to_hash/from_hash" do
          h = id.to_hash
          expect(klass.from_hash(h).to_hash).to eq(h)
        end
      end
    end

    # relaton's synthetic "/R-<x>" suffix, composing with a draft — incl. the
    # empty-draft "/D-/R-<x>" (revision-only) form.
    {
      "IEEE P802.15.4/D-09/R-i-2011-04" => "i",
      "ANSI/IEEE PC63.7/D-/R-17-2014" => "17",
    }.each do |ref, rev|
      context ref.inspect do
        let(:id) { parses(ref) }

        it "parses (non-nil)" do
          expect(id).not_to be_nil
        end

        it "preserves the revision #{rev.inspect}" do
          expect(id.revision).to eq(rev)
        end

        it "round-trips through to_hash/from_hash" do
          h = id.to_hash
          expect(klass.from_hash(h).to_hash).to eq(h)
        end
      end
    end
  end

  describe "edition suffix /E-<n>" do
    {
      "ISO/IEC/IEEE P29148/E-1-2011" => "1",
      "IEC/IEEE P63195/E-1-2018" => "1",
      "ISO/IEC/IEEE FDIS P15289/E-3-2016" => "3",
    }.each do |ref, ed|
      context ref.inspect do
        let(:id) { parses(ref) }

        it "parses (non-nil)" do
          expect(id).not_to be_nil
        end

        it "carries edition #{ed.inspect}" do
          expect(id.edition.to_s).to include(ed)
        end

        it "round-trips through to_hash/from_hash" do
          h = id.to_hash
          expect(klass.from_hash(h).to_hash).to eq(h)
        end
      end
    end
  end

  describe "ANS third co-publisher" do
    let(:id) { parses("ANSI/IEEE/ANS 7.4-3-2-1982") }

    it "parses (non-nil)" do
      expect(id).not_to be_nil
    end

    it "recognises ANS as a co-publisher" do
      expect(id.copublisher).to include("ANS")
    end

    it "round-trips through to_hash/from_hash" do
      h = id.to_hash
      expect(klass.from_hash(h).to_hash).to eq(h)
    end
  end
end
