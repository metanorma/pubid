# frozen_string_literal: true

require "spec_helper"

# ITU spells 158 relaton-data-itu corrigenda "Technical Cor. N". That is a
# different printed identifier from a plain "Cor. N", so the qualifier is
# preserved on the identifier rather than normalized away.
RSpec.describe "ITU Technical Corrigendum" do
  describe "on an ordinary dotted base" do
    subject { "ITU-T H.222.0 (1995) Technical Cor. 1 (02/1998)" }

    let(:parsed) { Pubid::Itu.parse(subject) }

    it "parses as a Corrigendum" do
      expect(parsed).to be_a(Pubid::Itu::Identifiers::Corrigendum)
    end

    it "flags the technical qualifier" do
      expect(parsed.technical).to be true
    end

    it "keeps the base document" do
      expect(parsed.base.code.number).to eq("222")
      expect(parsed.base.code.subseries).to eq("0")
      expect(parsed.base.date.year).to eq("1995")
    end

    it "round-trips to_s" do
      expect(parsed.to_s).to eq(subject)
    end

    it "round-trips through from_hash" do
      expect(Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash)
        .to eq(parsed.to_hash)
    end

    it "survives from_hash rendering" do
      expect(Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_s).to eq(subject)
    end
  end

  describe "distinctness from a plain corrigendum" do
    let(:technical) { Pubid::Itu.parse("ITU-T H.262 (1995) Technical Cor. 1") }
    let(:plain)     { Pubid::Itu.parse("ITU-T H.262 (1995) Cor. 1") }

    it "does not compare equal, in either direction" do
      expect(technical).not_to eq(plain)
      expect(plain).not_to eq(technical)
    end

    it "renders differently" do
      expect(technical.to_s).not_to eq(plain.to_s)
    end
  end

  # The marker is bound to the Cor. branch alone. Offered at the head of the
  # shared supplement_type rule it was accepted before ANY token and then
  # dropped by the builder, so "Technical Err. 1" silently rendered as
  # "Err. 1" — a different document.
  describe "the qualifier is only accepted on a corrigendum" do
    [
      "ITU-T H.222.0 (1995) Technical Err. 1",
      "ITU-T H.222.0 (1995) Technical Amd. 1",
      "ITU-T H.222.0 (1995) Technical Suppl. 1",
      "ITU-T H.222.0 (1995) Technical Add. 1",
    ].each do |id|
      it "rejects #{id} rather than silently dropping the qualifier" do
        expect do
          Pubid::Itu.parse(id)
        end.to raise_error(RuntimeError, /Failed to parse/)
      end
    end
  end

  describe "a plain corrigendum is unchanged" do
    subject { "ITU-T Z.100 (1999) Cor. 1 (10/2001)" }

    let(:parsed) { Pubid::Itu.parse(subject) }

    it "does not set the flag" do
      expect(parsed.technical).to be false
    end

    # Flag polarity: the common case must stay out of the serialized row, or
    # every already-published index row would gain a key.
    it "does not serialize a technical key" do
      expect(parsed.to_hash).not_to have_key("technical")
    end

    it "round-trips to_s" do
      expect(parsed.to_s).to eq(subject)
    end
  end

  describe "slash-joined onto an amendment" do
    subject { "ITU-T X.680 (1994) Amd. 1/Technical Cor. 1 (12/1997)" }

    let(:parsed) { Pubid::Itu.parse(subject) }

    it "is a Corrigendum whose base is the Amendment" do
      expect(parsed).to be_a(Pubid::Itu::Identifiers::Corrigendum)
      expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Amendment)
      expect(parsed.base.number).to eq("1")
    end

    it "flags both the slash join and the technical qualifier" do
      expect(parsed.slash_joined).to be true
      expect(parsed.technical).to be true
    end

    it "keeps the amended document under the amendment" do
      expect(parsed.base.base.code.number).to eq("680")
      expect(parsed.root.number.to_s).to eq("680")
    end

    it "round-trips to_s and the hash" do
      expect(parsed.to_s).to eq(subject)
      expect(Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash)
        .to eq(parsed.to_hash)
    end

    [
      "ITU-T X.237 (1995) Amd. 1/Technical Cor. 1 (06/1999)",
      "ITU-T X.730 (1992) Amd. 1/Technical Cor. 1 (10/1996)",
      "ITU-T X.731 (1992) Amd. 1/Technical Cor. 1 (10/1996)",
    ].each do |id|
      it "parses and round-trips #{id}" do
        expect(Pubid::Itu.parse(id).to_s).to eq(id)
      end
    end
  end
end
