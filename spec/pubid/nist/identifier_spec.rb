require "spec_helper"
require_relative "../../../lib/pubid"

RSpec.describe "Pubid::Nist identifier parsing" do
  describe ".parse" do
    context "LCIRC series" do
      it "parses and renders basic LCIRC" do
        id = Pubid::Nist.parse("NBS LCIRC 1000")
        expect(id.to_s).to eq("NBS LC 1000")
      end

      it "parses and renders LCIRC with revision year" do
        id = Pubid::Nist.parse("NBS LCIRC 1019r1963")
        expect(id.to_s).to eq("NBS LC 1019r1963")
      end
    end

    context "CSM volume-number format" do
      it "parses and renders v#n# format" do
        id = Pubid::Nist.parse("NBS CSM v6n1")
        expect(id.to_s).to eq("NBS CSM v6n1")
      end

      it "parses and renders different volume-number combinations" do
        expect(Pubid::Nist.parse("NBS CSM v7n12").to_s).to eq("NBS CSM v7n12")
        expect(Pubid::Nist.parse("NBS CSM v9n9").to_s).to eq("NBS CSM v9n9")
      end
    end

    context "supplement with revision" do
      it "parses and renders supprev notation" do
        id = Pubid::Nist.parse("NBS CIRC 154supprev")
        expect(id.to_s).to eq("NBS CIRC 154suprev")
      end

      it "parses and renders supplement with date" do
        id = Pubid::Nist.parse("NBS CIRC 25suppJan1924")
        expect(id.to_s).to eq("NBS CIRC 25supJan1924")
      end

      it "parses and renders supplement with edition" do
        id = Pubid::Nist.parse("NBS CIRC 24e4supp")
        expect(id.to_s).to eq("NBS CIRC 24e4sup")
      end
    end

    context "edition with revision and date" do
      it "parses and renders edition with revision and month-year" do
        id = Pubid::Nist.parse("NBS CIRC 13e2revJune1908")
        # Canonical format uses DOT separator, not "rev"
        expect(id.to_s).to eq("NBS CIRC 13e2.June1908")
      end

      it "parses and renders edition with revision year only" do
        id = Pubid::Nist.parse("NBS CIRC 13e2rev1908")
        # Canonical format uses DOT separator
        expect(id.to_s).to eq("NBS CIRC 13e2.1908")
      end

      it "uses dot separator not 'rev' prefix for canonical rendering" do
        id = Pubid::Nist.parse("NBS CIRC 13e2revJune1908")
        expect(id.to_s).to include("e2.")
        expect(id.to_s).not_to include("rev")
      end
    end

    context "modern NIST identifiers" do
      it "parses NIST SP identifiers" do
        id = Pubid::Nist.parse("NIST SP 800-53")
        expect(id.to_s).to eq("NIST SP 800-53")
      end

      it "parses NIST SP with revision" do
        id = Pubid::Nist.parse("NIST SP 800-53r5")
        expect(id.to_s).to eq("NIST SP 800-53r5")
      end
    end

    context "NBS historical identifiers" do
      it "parses NBS CIRC identifiers" do
        expect(Pubid::Nist.parse("NBS CIRC 13").to_s).to eq("NBS CIRC 13")
      end

      it "parses NBS BMS identifiers" do
        expect(Pubid::Nist.parse("NBS BMS 131").to_s).to eq("NBS BMS 131")
      end

      it "parses NBS RPT identifiers" do
        expect(Pubid::Nist.parse("NBS RPT 1000").to_s).to eq("NBS RPT 1000")
      end
    end

    context "FIPS identifiers" do
      it "parses basic FIPS" do
        expect(Pubid::Nist.parse("NIST FIPS 140-3").to_s).to eq("NIST FIPS 140-3")
      end
    end

    context "complex identifier patterns" do
      it "preserves exact rendering for round-trip" do
        test_cases = [
          { input: "NIST SP 800-53r5", expected: "NIST SP 800-53r5" },
          { input: "NBS LCIRC 1019r1963", expected: "NBS LC 1019r1963" },
          { input: "NBS CSM v6n1", expected: "NBS CSM v6n1" },
          { input: "NBS CIRC 154supprev", expected: "NBS CIRC 154suprev" },
          # Canonical format uses DOT separator, not "rev"
          { input: "NBS CIRC 13e2revJune1908",
            expected: "NBS CIRC 13e2.June1908" },
        ]

        test_cases.each do |test_case|
          expect(Pubid::Nist.parse(test_case[:input]).to_s).to eq(test_case[:expected])
        end
      end
    end
  end
end
