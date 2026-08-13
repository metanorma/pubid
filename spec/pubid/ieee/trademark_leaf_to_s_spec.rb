# frozen_string_literal: true

require "spec_helper"

# Every IEEE identifier leaf must accept the public `to_s(trademark:)` keyword
# without raising — relaton calls `pubid.to_s(trademark: true)` on *every* IEEE
# id to emit its trademark-scoped docidentifier, and a raising leaf silently
# drops the whole document from the crawl. Several leaf classes (NESC,
# JointDevelopment, IRE) overrode `to_s` with a signature that rejected
# `trademark:`. (hand-off: ieee-to-s-trademark-kwarg.)
RSpec.describe "IEEE leaf to_s(trademark:) compatibility" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # These leaves render a document *name*, or end with their own code, so the
  # mark sits at the end of the string *and* at the code boundary — the two
  # coincide. Leaves whose number is followed by suffixes (JointDevelopment,
  # Nesc::Standard) are covered by trademark_position_spec.rb instead.
  #
  # ref => class it should parse to (all non-802/8802/2030 forms → ™)
  {
    "2012 NESC Handbook" => Pubid::Ieee::Identifiers::Nesc::Handbook,
    "2017 NESC Redline" => Pubid::Ieee::Identifiers::Nesc::Redline,
    "12 IRE 20.S2" => Pubid::Ieee::Ire::Identifier,
  }.each do |ref, expected_class|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "parses to #{expected_class}" do
        expect(id).to be_a(expected_class)
      end

      it "accepts trademark: true and appends the ™ symbol" do
        expect { id.to_s(trademark: true) }.not_to raise_error
        expect(id.to_s(trademark: true)).to eq("#{id}™")
      end

      it "leaves plain to_s unchanged (default off)" do
        expect(id.to_s).not_to end_with("™")
        expect(id.to_s).not_to end_with("®")
      end
    end
  end

  # The spelled-out draft string is not reachable through the top-level parser
  # today (it routes to the generic Standard), so exercise Nesc::Draft by direct
  # construction. Draft-ness is carried by the class itself (and `#draft?`) —
  # the old `:boolean` `draft` attribute was dropped when NESC was reparented,
  # because the base declares `draft` as the `:string` draft designator.
  context "Nesc::Draft (direct construction)" do
    let(:id) do
      Pubid::Ieee::Identifiers::Nesc::Draft.new.tap do |d|
        d.year = "2016"
        d.month = "January"
      end
    end

    it "reports draft-ness without a draft attribute" do
      expect(id).to be_draft
      expect(id.draft).to be_nil
    end

    it "accepts trademark: true and appends the ™ symbol" do
      expect { id.to_s(trademark: true) }.not_to raise_error
      expect(id.to_s(trademark: true)).to eq("#{id}™")
    end

    it "leaves plain to_s unchanged" do
      expect(id.to_s).not_to end_with("™")
    end
  end

  # JointDevelopment keeps its dual-format `format:` param — trademark: must
  # compose with it, in both formats, at the code boundary.
  context "JointDevelopment format: param still honoured with trademark:" do
    let(:id) { klass.parse("ISO/IEC/IEEE P26511/D8-2018") }

    it "parses to JointDevelopment" do
      expect(id).to be_a(Pubid::Ieee::Identifiers::JointDevelopment)
    end

    it "renders the mark at the code boundary in IEEE format" do
      expect(id.to_s).to eq("ISO/IEC/IEEE P26511/D8-2018")
      expect(id.to_s(trademark: true)).to eq("ISO/IEC/IEEE P26511™/D8-2018")
    end

    it "renders the mark at the code boundary in ISO format" do
      expect(id.to_s(format: :iso)).to eq("ISO/IEC/IEEE 26511:2018")
      expect(id.to_s(format: :iso, trademark: true))
        .to eq("ISO/IEC/IEEE 26511™:2018")
    end
  end
end
