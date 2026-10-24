# frozen_string_literal: true

require "spec_helper"

# The owner's 2026-10-24 ruling: a P-project row with a /D designator is a
# draft, not a printed Std — its canonical face carries the word Draft, and
# the render must re-parse to the same identifier (the corpus round-trip
# gate). The D= designator face (pubid#203/#477) also applies to the
# designation route, whatever publisher slot captured it.
RSpec.describe "IEEE joint draft faces" do
  let(:ieee) { (Pubid.eager_load_flavors!; Pubid::Registry.get("ieee")) }

  describe "the two-party draft face" do
    it "renders the Draft word and round-trips" do
      id = ieee.parse("IEEE/IEC P60079-30-1/D5, Jan, 2022")
      expect(id).to be_a(Pubid::Ieee::Identifiers::ProjectDraftIdentifier)
      face = id.to_s
      expect(face).to eq("IEEE/IEC Draft P60079-30-1/D5, Jan, 2022")
      expect(ieee.parse(face)).to eq(id)
    end
  end

  describe "the lettered edition-draft designator" do
    it "renders /ED4 verbatim and round-trips" do
      id = ieee.parse("IEEE/IEC P63195-2 ED4, March 2021")
      face = id.to_s
      expect(face).to eq("IEEE/IEC Draft P63195-2/ED4, Mar, 2021")
      expect(ieee.parse(face)).to eq(id)
    end
  end

  describe "the partner co-publisher draft face" do
    it "keeps the copublisher on the Draft face" do
      id = ieee.parse("IEEE/NACE P2638/D2.4, January 2020")
      face = id.to_s
      expect(face).to eq("IEEE/NACE Draft P2638/D2.4, Jan, 2020")
      expect(ieee.parse(face)).to eq(id)
      expect(id.copublisher).to eq(["NACE"])
    end
  end

  describe "the D= designation route" do
    it "elects the IEEE D= face for a bare-IEEE project row" do
      id = ieee.parse("IEEE P24748-4/D=FDIS")
      expect(id).to be_a(Pubid::Ieee::Identifiers::JointDevelopment)
      expect(id.lead_party).to eq("IEEE")
      expect(id.ieee_draft).to eq("D=FDIS")
      expect(id.to_s).to eq("IEEE P24748-4/D=FDIS")
    end
  end

  describe "the three-segment draft designator" do
    it "does not double the D on a degraded capture" do
      id = ieee.parse("IEEE Draft Std P1666/D2.1.1")
      face = id.to_s
      expect(face).to eq("IEEE Draft P1666/D2.1.1")
      expect(face).not_to include("/D/D")
      expect(ieee.parse(face)).to eq(id)
    end
  end

  describe "the copublisher capture normalization" do
    it "expands a slash-joined joint token into bare orgs" do
      id = ieee.parse("IEEE/IEC/ISO P80005-1/FDIS_March 2012")
      expect(id.copublisher).to eq(%w[IEC ISO])
      face = id.to_s
      expect(face).to eq("IEEE/IEC/ISO Draft P80005-1/FDIS_March, 2012")
      expect(ieee.parse(face)).to eq(id)
    end
  end
end
