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
    "BIPM SI Brochure Appendix 3" => "pubid:bipm:si-brochure",
    "BIPM SI Brochure Concise" => "pubid:bipm:si-brochure",
    "SI MEP S1" => "pubid:bipm:mep",
    "Rapport BIPM-2019/05" => "pubid:bipm:mep",
    "BIPM SI MEP S1 Appendix 2 Part 1.1" => "pubid:bipm:mep",
    "BIPM SI MEP KUPRTM Appendix 2 Annex 2 Part 1" => "pubid:bipm:mep",
    "BIPM Rapport BIPM-2019/05 Appendix 2 Part 1" => "pubid:bipm:mep",
    "CCL-GD-MeP-1" => "pubid:bipm:guide",
    "BIPM CCL-GD-MeP-1 Appendix 2 Part 2.2" => "pubid:bipm:guide",
    "BIPM CCEM-GD-RSI-1 Appendix 2 Part 4.2" => "pubid:bipm:guide",
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

  # The relaton index key. Where it would merely duplicate another key it is
  # NOT stored twice: a Metrologia article's `volume` is derived from `number`
  # (the IANA `registry` / IETF `series` pattern). `variant` / `edition` and
  # `mep_code` / `report_code` DO stay, because each pair shares one class and
  # the renderer needs to know which of the two a value is — `9e v3.01
  # (2019/2024, E)` vs `Concise`, `SI MEP S1` vs `Rapport BIPM-2019/05`.
  #
  # Unlike the IEEE `CodeNumber` mixin the derivation is one-way — `Builder` is
  # the constructor of record and nothing rebuilds `number` after `from_hash`;
  # see the note on `build_metrologia` in lib/pubid/bipm/builder.rb.
  describe "the index key `number` serializes for every family" do
    keys = {
      "Metrologia 51 1 128" => "51",
      "BIPM SI Brochure 9e v3.01 (2019/2024, E)" => "9e",
      "BIPM SI Brochure Appendix 3" => "Appendix 3",
      "SI MEP S1" => "S1",
      "Rapport BIPM-2019/05" => "BIPM-2019/05",
      "BIPM SI MEP KUPRTM Appendix 2 Annex 2 Part 1" => "KUPRTM",
      "CCL-GD-MeP-1" => "1",
      "CCTF REC 2 (2012)" => "2",
      "CGPM 17th Meeting (1983)" => "17",
    }

    keys.each do |ref, number|
      it "#{ref} stores number #{number.inspect} and restores it" do
        hash = Pubid::Bipm.parse(ref).to_hash
        expect(hash["number"]).to eq(number)
        expect(Pubid::Bipm::Identifier.from_hash(hash).number).to eq(number)
      end
    end

    # 6,204 of the 6,206 published rows that carry a derived `number` are
    # Metrologia articles, so storing `volume` beside it would duplicate one
    # value across essentially the whole index.
    it "never stores a Metrologia volume beside the number" do
      hash = Pubid::Bipm.parse("Metrologia 55 1A 06007").to_hash
      expect(hash).not_to have_key("volume")
      expect(hash.keys)
        .to contain_exactly("_type", "number", "issue", "article")
    end

    it "still exposes the volume as an Integer, derived from the number" do
      id = Pubid::Bipm.parse("Metrologia 55 1A 06007")
      expect(id.volume).to eq(55)
      expect(Pubid::Bipm::Identifier.from_hash(id.to_hash).volume).to eq(55)
      expect(Pubid::Bipm.parse("Metrologia").volume).to be_nil
    end

    it "drops the key for the number-less committee declaration" do
      expect(Pubid::Bipm.parse("CGPM DECL (1889)").to_hash)
        .not_to have_key("number")
    end

    it "drops the key for the journal-level Metrologia record" do
      expect(Pubid::Bipm.parse("Metrologia").to_hash).not_to have_key("number")
    end
  end
end
