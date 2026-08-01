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

  # ref => class it should parse to (all non-802/2030 forms → ™)
  {
    "National Electrical Safety Code, C2-2012" => Pubid::Ieee::Identifiers::Nesc::Standard,
    "2012 NESC Handbook" => Pubid::Ieee::Identifiers::Nesc::Handbook,
    "2017 NESC Redline" => Pubid::Ieee::Identifiers::Nesc::Redline,
    "ISO/IEC/IEEE P26511/D8-2018" => Pubid::Ieee::Identifiers::JointDevelopment,
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

  # Nesc::Draft is not reachable through the top-level parser today (the string
  # routes to the generic Standard), so exercise it by direct construction.
  context "Nesc::Draft (direct construction)" do
    let(:id) do
      Pubid::Ieee::Identifiers::Nesc::Draft.new.tap do |d|
        d.year = Pubid::Components::Date.new(year: 2016)
        d.month = "January"
        d.draft = true
      end
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
  # compose with it.
  context "JointDevelopment format: param still honoured with trademark:" do
    let(:id) { klass.parse("ISO/IEC/IEEE P26511/D8-2018") }

    it "renders ISO format and appends the symbol" do
      iso = id.to_s(format: :iso)
      expect(iso).to eq("ISO/IEC/IEEE 26511:2018")
      expect(id.to_s(format: :iso, trademark: true)).to eq("#{iso}™")
    end
  end
end
