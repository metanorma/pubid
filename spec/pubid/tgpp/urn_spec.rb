# frozen_string_literal: true

require "spec_helper"

RSpec.describe "3GPP URN generation" do
  describe "#to_urn" do
    it "generates a urn:3gpp: URN for a technical specification" do
      urn = Pubid::Tgpp.parse("TS 23.207:REL-4/2.0.0").to_urn
      expect(urn).to eq("urn:3gpp:ts:23.207:REL-4:2.0.0")
    end

    it "includes suffix and parts in the code chunk" do
      urn = Pubid::Tgpp.parse("TS 29.198-04-1:REL-5/5.0.0").to_urn
      expect(urn).to eq("urn:3gpp:ts:29.198-04-1:REL-5:5.0.0")
    end

    # A partial identifier drops the TRAILING empty segments, so the URN of a
    # bare reference is not malformed. An INTERIOR empty segment is kept, so
    # the release-less form keeps the URN it has always emitted.
    it "drops both trailing segments for a bare reference" do
      expect(Pubid::Tgpp.parse("TS 23.207").to_urn)
        .to eq("urn:3gpp:ts:23.207")
    end

    it "drops the trailing version segment when only the release is present" do
      expect(Pubid::Tgpp.parse("TS 23.207:REL-4").to_urn)
        .to eq("urn:3gpp:ts:23.207:REL-4")
    end

    it "keeps the interior empty segment when only the version is present" do
      expect(Pubid::Tgpp.parse("TS 29.215/2.0.0").to_urn)
        .to eq("urn:3gpp:ts:29.215::2.0.0")
    end
  end
end
