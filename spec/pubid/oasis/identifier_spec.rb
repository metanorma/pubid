# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Oasis::Identifier do
  describe ".parse" do
    context "with a fully-decomposable slug (spec + version + stage + part)" do
      subject { "OASIS OSLC-CoreShapes-3.0-PS01-Pt8" }

      let(:parsed) { described_class.parse(subject) }

      it "builds the Standard type" do
        expect(parsed).to be_a(Pubid::Oasis::Identifiers::Standard)
      end

      it "preserves the verbatim slug in original" do
        expect(parsed.original).to eq("OSLC-CoreShapes-3.0-PS01-Pt8")
      end

      it "decomposes the component fields" do
        expect(parsed.number).to eq("OSLC-CoreShapes")
        expect(parsed.version).to eq("3.0")
        expect(parsed.stage).to eq("PS01")
        expect(parsed.part).to eq("Pt8")
      end

      # The specification name is stored as `number`, the key relaton-index
      # sorts and binary-searches on; `spec` is a derived reader over it.
      it "stores the specification name as the index key" do
        expect(parsed.root.number.to_s).to eq("OSLC-CoreShapes")
      end

      it "round-trips through to_s" do
        expect(parsed.to_s).to eq(subject)
      end

      it "drops the publisher token when asked" do
        expect(parsed.to_s(with_publisher: false))
          .to eq("OSLC-CoreShapes-3.0-PS01-Pt8")
      end
    end

    context "with a bare spec name (no version/stage/part)" do
      subject { "OASIS amqp-core" }

      let(:parsed) { described_class.parse(subject) }

      it "keeps everything in number/original and leaves the rest nil" do
        expect(parsed.original).to eq("amqp-core")
        expect(parsed.number).to eq("amqp-core")
        expect(parsed.version).to be_nil
        expect(parsed.stage).to be_nil
        expect(parsed.part).to be_nil
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "with a part-before-stage order variant" do
      subject { "OASIS OSLC-AM-3.0-Part1-PS01" }

      let(:parsed) { described_class.parse(subject) }

      it "decomposes order-independently" do
        expect(parsed.number).to eq("OSLC-AM")
        expect(parsed.version).to eq("3.0")
        expect(parsed.part).to eq("Part1")
        expect(parsed.stage).to eq("PS01")
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "with a trailing free-text label" do
      subject { "OASIS AkomaNtosoCore-v1.0-Pt2-Specifications" }

      let(:parsed) { described_class.parse(subject) }

      it "captures the label after the classified fragments" do
        expect(parsed.number).to eq("AkomaNtosoCore")
        expect(parsed.version).to eq("v1.0")
        expect(parsed.part).to eq("Pt2")
        expect(parsed.label).to eq("Specifications")
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "with a malformed slug (stray ] and embedded space)" do
      it "still round-trips verbatim via original" do
        [
          "OASIS CTAS-v3.0]-PS01",
          "OASIS ECF v4.01",
          "OASIS OpenC2-MQTT-v1.0] -CS01",
        ].each do |ref|
          parsed = described_class.parse(ref)
          expect(parsed).to be_a(Pubid::Oasis::Identifiers::Standard)
          expect(parsed.to_s).to eq(ref)
        end
      end
    end

    it "rejects overly long input (ReDoS guard)" do
      expect { described_class.parse("OASIS #{'a' * Pubid::MAX_INPUT_LENGTH}") }
        .to raise_error(ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE)
    end
  end
end
