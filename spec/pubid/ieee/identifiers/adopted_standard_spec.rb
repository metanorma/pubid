require "spec_helper"
require_relative "../../../../lib/pubid"

RSpec.describe Pubid::Ieee::Identifiers::AdoptedStandard do
  describe ".parse" do
    context "single adoption in parentheses" do
      it "parses AIEE with AESC adoption" do
        id = Pubid::Ieee.parse("AIEE No 14-1925 (AESC C22-1925)")
        expect(id).to be_a(described_class)

        expect(id.ieee_identifier).to be_a(Pubid::Ieee::Aiee::Identifier)
        expect(id.ieee_identifier.to_s).to eq("AIEE No 14-1925")

        expect(id.adopted_identifiers.first).to be_a(Pubid::Ieee::Identifier)
        expect(id.adopted_identifiers.first.publisher).to eq("AESC")
        expect(id.adopted_identifiers.first.to_s).to eq("AESC C22-1925")

        # Dash separator is now correctly preserved
        expect(id.to_s).to eq("AIEE No 14-1925 (AESC C22-1925)")
      end
    end

    context "IEC edition with IEEE adoption" do
      # TODO: This is very weird but preserving behavior for now:
      # "Published in alignment with IEEE Std 1801™-2013" is not "Adopted" but
      # is "IEEE adopted by IEC"...
      it "parses IEC with edition and IEEE Std in parentheses" do
        id = Pubid::Ieee.parse("IEC 61523-4 Edition 1.0 2015-03 (IEEE Std 1801-2013)")
        expect(id).to be_a(described_class)
        expect(id.ieee_identifier.to_s).to eq("IEC 61523-4 Edition 1.0 2015-03")
        expect(id.adopted_identifiers.first.to_s).to eq("IEEE Std 1801-2013")
        # Dash separator is now correctly preserved
        expect(id.to_s).to eq("IEC 61523-4 Edition 1.0 2015-03 (IEEE Std 1801-2013)")
      end

      it "parses IEEE with IEC edition in parentheses" do
        id = Pubid::Ieee.parse("IEEE Std C37.111-2013 (IEC 60255-24 Edition 2.0 2013-04)")
        expect(id).to be_a(described_class)

        expect(id.ieee_identifier).to be_a(Pubid::Ieee::Identifier)
        expect(id.ieee_identifier.to_s).to eq("IEEE Std C37.111-2013")

        expect(id.adopted_identifiers.first).to be_a(Pubid::Iec::Identifiers::InternationalStandard)
        expect(id.adopted_identifiers.first.to_s).to eq("IEC 60255-24:2013-04 ED2.0")

        expect(id.to_s).to eq("IEEE Std C37.111-2013 (IEC 60255-24:2013-04 ED2.0)")
      end
    end
  end

  # Regression: from_hash(to_hash).to_hash must equal to_hash. `#publisher`
  # is a *derived* method (ieee_identifier.publisher), so lutaml omits it on
  # the parse path (unset) but re-serializes the derived value after from_hash
  # materializes the attribute default — an asymmetric top-level "publisher"
  # key. See handoff ieee-adopted-standard-roundtrip; same class of bug as
  # JointDevelopment.
  describe "round-trip serialization" do
    let(:klass) { Pubid::Ieee::Identifier }

    [
      "AIEE No 511-1956 (IEEE Std 275)",
      "IEEE Std 275-1956 (AIEE No 511-1956)",
      "AIEE No 14-1925 (AESC C22-1925)",
    ].each do |input|
      context "for #{input.inspect}" do
        let(:parsed) { klass.parse(input) }
        let(:hash) { parsed.to_hash }

        it "parses as an AdoptedStandard" do
          expect(parsed).to be_a(described_class)
        end

        it "does not serialize a top-level publisher (it is derived)" do
          expect(hash).not_to have_key("publisher")
        end

        it "round-trips through from_hash" do
          expect(klass.from_hash(hash).to_hash).to eq(hash)
        end

        it "still renders and derives publisher at runtime" do
          expect(parsed.to_s).to eq(input)
          expect(parsed.publisher).not_to be_nil
        end
      end
    end
  end

  # Regression: a cross-flavor adopted identifier (ANSI/IEC/…) is stored in
  # `adopted_identifiers`, whose attribute type was the IEEE-only `Identifier`.
  # `polymorphic: true` permits IEEE *subtypes* but not a `Pubid::Ansi::…` or
  # `Pubid::Iec::…` object, so `to_hash` raised `IncorrectModelError` and the
  # relaton index-v2 build skipped the doc. Widening the attribute type to the
  # cross-flavor base `::Pubid::Identifier` lets these serialize and round-trip.
  # See handoff ieee-adopted-standard-cross-flavor-type.
  describe "cross-flavor adopted identifier serialization" do
    let(:klass) { Pubid::Ieee::Identifier }

    {
      "IEEE Std 144-1971 (ANSI C37.24-1971)" =>
        Pubid::Ansi::Identifiers::Standard,
      "IEEE Std C37.111-2013 (IEC 60255-24 Edition 2.0 2013-04)" =>
        Pubid::Iec::Identifiers::InternationalStandard,
    }.each do |input, adopted_class|
      context "for #{input.inspect}" do
        let(:parsed) { klass.parse(input) }

        it "parses as an AdoptedStandard with a cross-flavor adopted id" do
          expect(parsed).to be_a(described_class)
          expect(parsed.adopted_identifiers.first).to be_a(adopted_class)
        end

        it "serializes to_hash without raising" do
          expect { parsed.to_hash }.not_to raise_error
        end

        it "round-trips through from_hash" do
          hash = parsed.to_hash
          expect(klass.from_hash(hash).to_hash).to eq(hash)
        end
      end
    end
  end
end
