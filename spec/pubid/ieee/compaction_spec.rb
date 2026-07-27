# frozen_string_literal: true

require "spec_helper"

# Serialization compaction (Pubid::Ieee::Compaction): the multi-field
# `typed_stage` object collapses to a single scalar `stage` key (its canonical
# abbreviation), rebuilt from the TYPED_STAGES registry on from_hash; and the
# `draft` string is stored slashless ("D3" not "/D3"). Both are provably
# lossless — the stage collapse only fires when the registry reconstruction is
# byte-identical, and Draft.parse accepts the slashless form. The runtime
# objects (rendering, matching) are untouched — only serialization.
RSpec.describe "IEEE serialization compaction (stage + draft)" do
  {
    "IEEE Std 528-2019" => "Std",
    "IEEE Std 802.16.1-2012" => "Std",
    "IEEE P802.16/D-3-2017-07" => "D2", # D2-D3 committee-draft group
    "IEC/IEEE P2770" => "P", # JointDevelopment
  }.each do |ref, stage|
    context ref do
      let(:id) { Pubid::Ieee::Identifier.parse(ref) }

      it "serializes a scalar `stage` #{stage.inspect}, not an object" do
        h = id.to_hash
        expect(h).not_to have_key("typed_stage")
        expect(h["stage"]).to eq(stage)
      end

      it "round-trips through to_hash/from_hash" do
        h = id.to_hash
        expect(Pubid::Ieee::Identifier.from_hash(h).to_hash).to eq(h)
      end

      it "rebuilds the identical typed_stage object on from_hash" do
        rebuilt = Pubid::Ieee::Identifier.from_hash(id.to_hash)
        expect(rebuilt.root.typed_stage).to eq(id.root.typed_stage)
      end

      it "renders identically after a from_hash round-trip" do
        rebuilt = Pubid::Ieee::Identifier.from_hash(id.to_hash)
        expect(rebuilt.to_s).to eq(id.to_s)
      end
    end
  end

  it "collapses the stage on a nested corrigendum base too" do
    id = Pubid::Ieee::Identifier.parse("IEEE Std 1003.1-2001/Cor 2-2004")
    h = id.to_hash
    expect(h["base"]).not_to have_key("typed_stage")
    expect(h["base"]["stage"]).to eq("Std")
    expect(Pubid::Ieee::Identifier.from_hash(h).to_hash).to eq(h)
  end

  it "emits no stage for a type without a typed_stage (IecIeeeCopublished)" do
    h = Pubid::Ieee::Identifier.parse("IEC/IEEE 60076-2016").to_hash
    expect(h).not_to have_key("stage")
    expect(h).not_to have_key("typed_stage")
  end

  describe "draft slash strip" do
    it "serializes `draft` slashless (\"D3\", not \"/D3\")" do
      h = Pubid::Ieee::Identifier.parse("IEEE P802.16/D-3-2017-07").to_hash
      expect(h["draft"]).to eq("D3")
    end

    it "round-trips and renders identically from the slashless form" do
      id = Pubid::Ieee::Identifier.parse("IEEE P802.16/D-3-2017-07")
      h = id.to_hash
      rebuilt = Pubid::Ieee::Identifier.from_hash(h)
      expect(rebuilt.to_hash).to eq(h)
      expect(rebuilt.to_s).to eq(id.to_s)
    end
  end
end
