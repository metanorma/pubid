# frozen_string_literal: true

require "spec_helper"

# ITU's own listings vary the spelling of the supplement ordinal. 74
# relaton-data-itu records failed to parse on these variants alone.
RSpec.describe "ITU supplement spelling variants" do
  describe "no space before the ordinal" do
    context "series-only form ITU-T E Suppl.1 (10/1976)" do
      subject { "ITU-T E Suppl.1 (10/1976)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as a base-less Supplement" do
        expect(parsed).to be_a(Pubid::Itu::Identifiers::Supplement)
        expect(parsed.base).to be_nil
        expect(parsed.series.series).to eq("E")
        expect(parsed.number).to eq("1")
      end

      it "flags the glued ordinal and round-trips it" do
        expect(parsed.number_glued).to be true
        expect(parsed.to_s).to eq(subject)
      end

      it "round-trips through from_hash, rendering included" do
        rebuilt = Pubid::Itu::Identifier.from_hash(parsed.to_hash)
        expect(rebuilt.to_hash).to eq(parsed.to_hash)
        expect(rebuilt.to_s).to eq(subject)
      end
    end

    context "with a recommendation base ITU-T D.211 Suppl.1 (05/2010)" do
      subject { "ITU-T D.211 Suppl.1 (05/2010)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses with the base recommendation" do
        expect(parsed.base.code.number).to eq("211")
        expect(parsed.number).to eq("1")
        expect(parsed.to_s).to eq(subject)
      end
    end

    # The spelling is not part of the document's identity.
    it "compares equal to the spaced spelling" do
      glued  = Pubid::Itu.parse("ITU-T E Suppl.1 (10/1976)")
      spaced = Pubid::Itu.parse("ITU-T E Suppl. 1 (10/1976)")

      expect(glued).to eq(spaced)
      expect(spaced).to eq(glued)
    end
  end

  describe "dotted ordinal" do
    context "ITU-T M Suppl. 1.1 (12/1972)" do
      subject { "ITU-T M Suppl. 1.1 (12/1972)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "keeps the whole dotted ordinal" do
        expect(parsed.number).to eq("1.1")
      end

      it "does not mistake the ordinal for the date" do
        expect(parsed.date.year).to eq("1972")
        expect(parsed.date.month).to eq("12")
      end

      it "round-trips to_s and the hash" do
        expect(parsed.to_s).to eq(subject)
        expect(Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash)
          .to eq(parsed.to_hash)
      end
    end

    [
      "ITU-T M Suppl. 1.5 (12/1972)",
      "ITU-T O Suppl. 1.1 (10/1984)",
      "ITU-T M Suppl. 2.3 (11/1988)",
    ].each do |id|
      it "parses and round-trips #{id}" do
        expect(Pubid::Itu.parse(id).to_s).to eq(id)
      end
    end

    it "keeps distinct dotted ordinals distinct" do
      expect(Pubid::Itu.parse("ITU-T M Suppl. 1.1"))
        .not_to eq(Pubid::Itu.parse("ITU-T M Suppl. 1.2"))
    end
  end

  describe "flag polarity" do
    # The spaced spelling is the common case and must not gain a key in any
    # already-published index row.
    it "does not serialize number_glued for the spaced form" do
      hash = Pubid::Itu.parse("ITU-T E.156 Suppl. 2").to_hash
      expect(hash).not_to have_key("number_glued")
      expect(hash).not_to have_key("slash_joined")
    end
  end
end
