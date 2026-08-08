# frozen_string_literal: true

require "spec_helper"

# Round-trip invariant for index serialization: a parsed BIPM identifier must
# survive to_hash → from_hash unchanged (the contract the Relaton index relies
# on) and its canonical hash must be idempotent.
RSpec.describe "Pubid::Bipm serialization" do
  cases = {
    "CCTF REC 2 (2012)" => "pubid:bipm:committee-document",
    "CCTF REC 2 (2012, E)" => "pubid:bipm:committee-document",
    "CGPM DECL (1889)" => "pubid:bipm:committee-document",
    "JCRB ACT 10-1 (2003)" => "pubid:bipm:committee-document",
    "CCL Recommendation 1 (2001)" => "pubid:bipm:committee-document",
    "Recommandation 1 du CCL (2001)" => "pubid:bipm:committee-document",
    "CGPM 17th Meeting (1983)" => "pubid:bipm:meeting",
    "CCAUV 10<sup>e</sup> réunion (2015)" => "pubid:bipm:meeting",
    "Metrologia 51 1 128" => "pubid:bipm:metrologia-article",
    "Metrologia 1" => "pubid:bipm:metrologia-article",
    "BIPM SI Brochure 9e v3.01 (2019/2024, E)" => "pubid:bipm:si-brochure",
    "SI Brochure Appendix 3" => "pubid:bipm:si-brochure",
    "SI Brochure Concise" => "pubid:bipm:si-brochure",
    "SI MEP S1" => "pubid:bipm:mep",
    "SI MEP KUPRTM" => "pubid:bipm:mep",
    "Rapport BIPM-2019/05" => "pubid:bipm:mep",
    "CCL-GD-MeP-1" => "pubid:bipm:guide",
    "CCEM-GD-RSI-1" => "pubid:bipm:guide",
  }

  cases.each do |ref, type_tag|
    context ref do
      let(:identifier) { Pubid::Bipm.parse(ref) }
      let(:hash) { identifier.to_hash }

      it "produces a non-empty hash carrying the polymorphic _type" do
        expect(hash).not_to be_empty
        expect(hash["_type"]).to eq(type_tag)
      end

      it "round-trips through from_hash" do
        restored = Pubid::Bipm::Identifier.from_hash(hash)
        expect(restored.to_s).to eq(identifier.to_s)
      end

      it "has an idempotent canonical hash" do
        expect(Pubid::Bipm::Identifier.from_hash(hash).to_hash).to eq(hash)
      end
    end
  end

  it "omits the default 'form' (short) from the canonical hash" do
    expect(Pubid::Bipm.parse("CCTF REC 2 (2012)").to_hash)
      .not_to have_key("form")
  end

  it "keeps 'form' when long" do
    expect(Pubid::Bipm.parse("CCL Recommendation 1 (2001)").to_hash["form"])
      .to eq("long")
  end
end
