# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Ieee::Components::Draft do
  # `Draft.parse` must be an exact inverse of `Draft#to_s`: the identifier stores
  # the draft as the rendered string (`draft_obj.to_s`, e.g. "/D3"), and after
  # `from_hash` the object is rebuilt via `Draft.parse(that_string)`. If the two
  # disagree, `to_hash` no longer round-trips (relaton drops such ids from its
  # index). Historically `Draft.parse` used a `^D(\d+)` regex that missed the
  # leading "/D", producing a doubled "/D/D3".
  describe "round-trips its own rendering (parse(to_s).to_s == to_s)" do
    %w[
      /D3
      /D10
      /D3.4
      /D.19
      /D6.0
      /D12e
      /Dx.1
      /DD7.2
      /DIS
      /DIS2
      /ED4
    ].each do |rendered|
      it "reproduces #{rendered}" do
        expect(described_class.parse(rendered).to_s).to eq(rendered)
      end
    end

    # Date-carrying drafts (from the text-date grammar, e.g. PSI drafts) must also
    # round-trip, and must keep `version` clean (the SI/PSI renderer reads
    # `draft_obj.version` directly).
    {
      "/D2, Oct 2015" => "2",
      "/D2 Oct 2015" => "2",
      "/D7 Jul 2019" => "7",
      # The year-only date joins with its comma (the grammar's
      # comma-year draft tail), matching the dated-draft canonicals.
      "/D7, 2019" => "7",
    }.each do |rendered, clean_version|
      it "reproduces #{rendered.inspect} and keeps a clean version" do
        parsed = described_class.parse(rendered)
        expect(parsed.to_s).to eq(rendered)
        expect(parsed.version).to eq(clean_version)
      end
    end
  end

  describe "D= designator restoration (pubid#582)" do
    # The published index rows carry "draft" => "D=<designator>"; the
    # restore must rebuild the same component the in-context parse
    # built, so from_hash(parse(x).to_hash) == parse(x).
    {
      "D=CD1"  => "CD1",
      "D=FDIS" => "FDIS",
      "D=FCD"  => "FCD",
      "D=CDV1" => "CDV1",
    }.each do |wire, stage|
      it "restores #{wire.inspect} verbatim as the stage token" do
        draft = described_class.parse(wire)
        expect(draft.iso_stage).to eq(stage)
        expect(draft.iso_iteration).to be_nil
        expect(draft.version).to be_nil
      end
    end

    it "keeps the D-echo alias normalization" do
      draft = described_class.parse("D=DDIS3")
      expect(draft.iso_stage).to eq("DIS")
      expect(draft.iso_iteration).to eq("3")
      expect(draft.to_s).to eq("/D=DIS.3")
    end

    it "round-trips the published rows through from_hash" do
      {
        "IEEE Std P12207_CD1" => "IEEE P12207/D=CD1",
        "IEEE Unapproved Std P15288/D-FDIS-2007" => "IEEE Unapproved P15288/D=FDIS, 2007",
        "IEEE Unapproved Std P16326/D-FCD-2007" => "IEEE Unapproved P16326/D=FCD, 2007",
      }.each do |printed, canonical|
        id = Pubid.parse(printed)
        restored = Pubid::Ieee::Identifier.from_hash(id.to_hash)
        expect(restored).to eq(id)
        expect(restored.to_s).to eq(canonical)
      end
    end
  end
end
