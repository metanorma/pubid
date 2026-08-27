require "spec_helper"

RSpec.describe Pubid::Nist::Parser do
  describe "parsing through module interface" do
    context "LCIRC series" do
      it "parses basic LCIRC" do
        expect { Pubid::Nist.parse("NBS LCIRC 1000") }.not_to raise_error
        expect { Pubid::Nist.parse("NBS LCIRC 525") }.not_to raise_error
      end

      it "parses LCIRC with revision year" do
        expect do
          Pubid::Nist.parse("NBS LCIRC 1019r1963")
        end.not_to raise_error
        expect do
          Pubid::Nist.parse("NBS LCIRC 1035r1985")
        end.not_to raise_error
      end
    end

    context "CSM volume-number format" do
      it "parses v#n# format" do
        expect { Pubid::Nist.parse("NBS CSM v6n1") }.not_to raise_error
        expect { Pubid::Nist.parse("NBS CSM v7n12") }.not_to raise_error
        expect { Pubid::Nist.parse("NBS CSM v9n9") }.not_to raise_error
      end
    end

    context "supplement with revision" do
      it "parses supprev notation" do
        expect do
          Pubid::Nist.parse("NBS CIRC 154supprev")
        end.not_to raise_error
      end

      it "parses supplement with date" do
        expect do
          Pubid::Nist.parse("NBS CIRC 25suppJan1924")
        end.not_to raise_error
        expect do
          Pubid::Nist.parse("NBS CIRC 25suppJune1924")
        end.not_to raise_error
      end

      it "parses supplement with edition" do
        expect { Pubid::Nist.parse("NBS CIRC 24e4supp") }.not_to raise_error
      end
    end

    context "edition with revision and date" do
      it "parses edition with revision and month-year" do
        expect do
          Pubid::Nist.parse("NBS CIRC 13e2revJune1908")
        end.not_to raise_error
        expect do
          Pubid::Nist.parse("NBS CIRC 13e2revJuly1908")
        end.not_to raise_error
      end

      it "parses edition with revision year only" do
        expect do
          Pubid::Nist.parse("NBS CIRC 13e2rev1908")
        end.not_to raise_error
      end

      it "parses edition with supplement" do
        expect { Pubid::Nist.parse("NBS CIRC 24e4supp") }.not_to raise_error
      end
    end

    context "modern NIST identifiers" do
      it "parses NIST SP with parts" do
        expect { Pubid::Nist.parse("NIST SP 800-53") }.not_to raise_error
        expect { Pubid::Nist.parse("NIST SP 500-175") }.not_to raise_error
      end

      it "parses NIST SP with revision" do
        expect { Pubid::Nist.parse("NIST SP 800-53r5") }.not_to raise_error
      end

      it "parses NIST FIPS" do
        expect { Pubid::Nist.parse("NIST FIPS 140-3") }.not_to raise_error
      end
    end

    context "letter suffix followed by revision" do
      it "parses LCIRC with letter suffix and 4-digit revision year" do
        expect { Pubid::Nist.parse("NBS LCIRC 256Ar1930") }.not_to raise_error
        expect { Pubid::Nist.parse("NBS LC 256Ar1930") }.not_to raise_error
      end

      it "parses IR with letter suffix and short revision" do
        expect { Pubid::Nist.parse("NIST IR 8278Ar1 ipd") }.not_to raise_error
      end

      it "round-trips the rendered identifier" do
        id = Pubid::Nist::Identifier.parse("NBS LCIRC 256Ar1930")
        expect(id.to_s).to eq("NBS LC 256Ar1930")
      end

      it "does not regress on plain number + 4-digit revision" do
        expect { Pubid::Nist.parse("NBS LCIRC 256r1930") }.not_to raise_error
      end

      it "does not regress on dash-separated letter suffix + revision" do
        expect { Pubid::Nist.parse("NIST SP 800-56Ar2") }.not_to raise_error
      end
    end

    context "NBS historical identifiers" do
      it "parses NBS CIRC" do
        expect { Pubid::Nist.parse("NBS CIRC 13") }.not_to raise_error
      end

      it "parses NBS BMS" do
        expect { Pubid::Nist.parse("NBS BMS 131") }.not_to raise_error
      end
    end
  end
end
