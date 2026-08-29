# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Csa::Identifiers::Base do
  describe ".parse" do
    context "publisher prefix variants" do
      describe "CSA B149.1:20" do
        subject { "CSA B149.1:20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as a CSA identifier" do
          expect(parsed).to be_a(Pubid::Csa::SingleIdentifier)
        end

        it "parses code" do
          expect(parsed.number.value).to eq("B149.1")
        end

        it "parses year" do
          expect(parsed.year).to eq("2020")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CAN/CSA-A123.1-05" do
        subject { "CAN/CSA-A123.1-05" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CanadianAdopted" do
          expect(parsed).to be_a(Pubid::Csa::Identifiers::CanadianAdopted)
        end

        it "parses code from wrapped identifier" do
          expect(parsed.base.number.value).to eq("A123.1")
        end

        it "parses year with dash format" do
          expect(parsed.base.year).to eq("2005")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CAN3-B78.1-M83" do
        subject { "CAN3-B78.1-M83" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CanadianAdopted" do
          expect(parsed).to be_a(Pubid::Csa::Identifiers::CanadianAdopted)
        end

        it "parses code" do
          expect(parsed.base.number.value).to eq("B78.1")
        end

        it "parses year with M prefix" do
          expect(parsed.base.year).to eq("1983")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "year formats" do
      describe "CSA B149.1:20 (colon format)" do
        subject { "CSA B149.1:20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "converts 2-digit year to 4-digit" do
          expect(parsed.year).to eq("2020")
        end

        it "preserves colon format in rendering" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA C22.1-15 (dash format)" do
        subject { "CSA C22.1-15" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "converts 2-digit year to 4-digit" do
          expect(parsed.year).to eq("2015")
        end

        it "preserves dash format in rendering" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA B149.1:F20 (French prefix)" do
        subject { "CSA B149.1:F20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses French indicator" do
          expect(parsed.french).to be(true)
        end

        it "parses year" do
          expect(parsed.year).to eq("2020")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA C108.1.2-M1981 (metric year with M prefix)" do
        subject { "CSA C108.1.2-M1981" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses 4-digit year" do
          expect(parsed.year).to eq("1981")
        end

        it "preserves M prefix" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "NO. notation" do
      describe "CSA C22.2 NO. 286:23" do
        subject { "CSA C22.2 NO. 286:23" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CecIdentifier" do
          expect(parsed).to be_a(Pubid::Csa::Identifiers::Cec)
        end

        it "parses CEC part" do
          expect(parsed.cec_part.value).to eq("C22.2")
        end

        it "parses NO. number" do
          expect(parsed.no_number.value).to eq("286")
        end

        it "parses year" do
          expect(parsed.year).to eq("2023")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CAN/CSA-C22.2 NO. 60601-1:14" do
        subject { "CAN/CSA-C22.2 NO. 60601-1:14" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CanadianAdopted" do
          expect(parsed).to be_a(Pubid::Csa::Identifiers::CanadianAdopted)
        end

        it "wraps CecIdentifier" do
          expect(parsed.base).to be_a(Pubid::Csa::Identifiers::Cec)
        end

        it "parses CEC part" do
          expect(parsed.base.cec_part.value).to eq("C22.2")
        end

        it "parses NO. number" do
          expect(parsed.base.no_number.value).to eq("60601-1")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "reaffirmation patterns" do
      describe "CSA A123.17-05 (R2019)" do
        subject { "CSA A123.17-05 (R2019)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses code" do
          expect(parsed.number.value).to eq("A123.17")
        end

        it "parses original year" do
          expect(parsed.year).to eq("2005")
        end

        it "parses reaffirmation year" do
          expect(parsed.reaffirmation).to eq("2019")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CAN/CSA-A123.2-03 (R2023)" do
        subject { "CAN/CSA-A123.2-03 (R2023)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses reaffirmation in CanadianAdopted" do
          expect(parsed.reaffirmation).to eq("2023")
        end

        it "parses original year" do
          expect(parsed.base.year).to eq("2003")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA C22.2 NO. 1-04 (R2009)" do
        subject { "CSA C22.2 NO. 1-04 (R2009)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CecIdentifier" do
          expect(parsed).to be_a(Pubid::Csa::Identifiers::Cec)
        end

        it "parses CEC part" do
          expect(parsed.cec_part.value).to eq("C22.2")
        end

        it "parses NO. number" do
          expect(parsed.no_number.value).to eq("1")
        end

        it "parses reaffirmation year" do
          expect(parsed.reaffirmation).to eq("2009")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "decimal codes" do
      describe "CSA Z259.2.4:15" do
        subject { "CSA Z259.2.4:15" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses multi-part decimal code" do
          expect(parsed.number.value).to eq("Z259.2.4")
        end

        it "parses year" do
          expect(parsed.year).to eq("2015")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end
  end
end
