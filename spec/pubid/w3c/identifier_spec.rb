# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::W3c::Identifier do
  describe ".parse" do
    context "with type + slug + date (shape A)" do
      subject { "W3C WD-charmod-19991129" }

      let(:parsed) { described_class.parse(subject) }

      it "builds the concrete typed class" do
        expect(parsed).to be_a(Pubid::W3c::Identifiers::WorkingDraft)
      end

      it "decomposes slug and date" do
        expect(parsed.number).to eq("charmod")
        expect(parsed.date).to eq("19991129")
      end

      it "round-trips through to_s" do
        expect(parsed.to_s).to eq(subject)
      end

      it "drops the publisher token when asked" do
        expect(parsed.to_s(with_publisher: false)).to eq("WD-charmod-19991129")
      end
    end

    context "with a slug that ends in digits before the date" do
      subject { "W3C REC-ATAG10-20000203" }

      let(:parsed) { described_class.parse(subject) }

      it "keeps the digit-ending slug intact and extracts only the date" do
        expect(parsed).to be_a(Pubid::W3c::Identifiers::Recommendation)
        expect(parsed.number).to eq("ATAG10")
        expect(parsed.date).to eq("20000203")
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "with a bare slug (shape B)" do
      subject { "W3C 2dcontext" }

      let(:parsed) { described_class.parse(subject) }

      it "builds a Standard with no date" do
        expect(parsed).to be_a(Pubid::W3c::Identifiers::Standard)
        expect(parsed.number).to eq("2dcontext")
        expect(parsed.date).to be_nil
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "with a bare slug ending in a short digit run" do
      it "does not mistake the trailing digits for a date" do
        %w[W3C\ url-1 W3C\ xpath-datamodel-31 W3C\ 07-WebData].each do |raw|
          id = described_class.parse(raw)
          expect(id).to be_a(Pubid::W3c::Identifiers::Standard)
          expect(id.date).to be_nil
          expect(id.to_s).to eq(raw)
        end
      end
    end

    context "with type + slug, no date (shape C)" do
      subject { "W3C NOTE-xml-names" }

      let(:parsed) { described_class.parse(subject) }

      it "builds the typed class with a nil date" do
        expect(parsed).to be_a(Pubid::W3c::Identifiers::Note)
        expect(parsed.number).to eq("xml-names")
        expect(parsed.date).to be_nil
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "with a legacy 6-digit date" do
      subject { "W3C NOTE-TPRC-970930" }

      let(:parsed) { described_class.parse(subject) }

      it "extracts the 6-digit date" do
        expect(parsed.number).to eq("TPRC")
        expect(parsed.date).to eq("970930")
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "with a legacy 4-digit date" do
      subject { "W3C NOTE-voice-0128" }

      let(:parsed) { described_class.parse(subject) }

      it "extracts the 4-digit date" do
        expect(parsed.number).to eq("voice")
        expect(parsed.date).to eq("0128")
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "with a bare slug that spells a maturity token" do
      subject { "W3C rec" }

      let(:parsed) { described_class.parse(subject) }

      it "treats the lowercase token as a bare Standard slug" do
        expect(parsed).to be_a(Pubid::W3c::Identifiers::Standard)
        expect(parsed.number).to eq("rec")
        expect(parsed.to_s).to eq(subject)
      end

      it "round-trips through its URN without being mistaken for a type" do
        expect(Pubid.parse(parsed.to_urn).to_s).to eq(subject)
      end
    end

    context "with a legacy .html-suffixed slug" do
      subject { "W3C WD-DSIG-label-971024.html" }

      let(:parsed) { described_class.parse(subject) }

      it "round-trips (date stays embedded in the slug)" do
        expect(parsed).to be_a(Pubid::W3c::Identifiers::WorkingDraft)
        expect(parsed.date).to be_nil
        expect(parsed.to_s).to eq(subject)
      end
    end
  end
end
