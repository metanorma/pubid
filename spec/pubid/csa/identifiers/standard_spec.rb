# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Csa::Identifiers::Standard do
  describe ".parse" do
    context "basic standards with colon year format" do
      describe "CSA B149.1:20" do
        subject { "CSA B149.1:20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Standard" do
          expect(parsed).to be_a(described_class)
        end

        it "parses code" do
          expect(parsed.number.value).to eq("B149.1")
        end

        it "parses year as 2020" do
          expect(parsed.year).to eq("2020")
        end

        it "uses colon format" do
          expect(parsed.year_format).to eq("colon")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA B149.3:25" do
        subject { "CSA B149.3:25" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Standard" do
          expect(parsed).to be_a(described_class)
        end

        it "parses code" do
          expect(parsed.number.value).to eq("B149.3")
        end

        it "parses 2-digit year as 2025" do
          expect(parsed.year).to eq("2025")
        end

        it "round-trips with 2-digit year" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA Z462:24" do
        subject { "CSA Z462:24" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Standard" do
          expect(parsed).to be_a(described_class)
        end

        it "parses single letter code" do
          expect(parsed.number.value).to eq("Z462")
        end

        it "parses year" do
          expect(parsed.year).to eq("2024")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "standards with dash year format" do
      describe "CSA C22.1-15" do
        subject { "CSA C22.1-15" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Standard" do
          expect(parsed).to be_a(described_class)
        end

        it "parses code" do
          expect(parsed.number.value).to eq("C22.1")
        end

        it "parses year as 2015" do
          expect(parsed.year).to eq("2015")
        end

        it "uses dash format" do
          expect(parsed.year_format).to eq("dash")
        end

        it "round-trips with dash format" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA C22.1-18" do
        subject { "CSA C22.1-18" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses code" do
          expect(parsed.number.value).to eq("C22.1")
        end

        it "parses year" do
          expect(parsed.year).to eq("2018")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "standards with reaffirmation" do
      describe "CSA A123.17-05 (R2019)" do
        subject { "CSA A123.17-05 (R2019)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Standard" do
          expect(parsed).to be_a(described_class)
        end

        it "parses code" do
          expect(parsed.number.value).to eq("A123.17")
        end

        it "parses designation year" do
          expect(parsed.year).to eq("2005")
        end

        it "parses reaffirmation year" do
          expect(parsed.reaffirmation).to eq("2019")
        end

        it "round-trips correctly" do
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

        it "parses year" do
          expect(parsed.year).to eq("2004")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2009")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "standards with NO. notation" do
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

      describe "CSA C22.2 NO. 144.1-16 (R2020)" do
        subject { "CSA C22.2 NO. 144.1-16 (R2020)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CecIdentifier" do
          expect(parsed).to be_a(Pubid::Csa::Identifiers::Cec)
        end

        it "parses CEC part" do
          expect(parsed.cec_part.value).to eq("C22.2")
        end

        it "parses NO. number" do
          expect(parsed.no_number.value).to eq("144.1")
        end

        it "parses year" do
          expect(parsed.year).to eq("2016")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2020")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "HB suffix patterns (Session 225 fix)" do
      describe "CSA C22.1HB-18" do
        subject { "CSA C22.1HB-18" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Standard" do
          expect(parsed).to be_a(described_class)
        end

        it "parses code with HB suffix" do
          expect(parsed.number.value).to eq("C22.1HB")
        end

        it "parses year" do
          expect(parsed.year).to eq("2018")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA 15189HB:25" do
        subject { "CSA 15189HB:25" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Standard" do
          expect(parsed).to be_a(described_class)
        end

        it "parses pure numeric code with HB suffix" do
          expect(parsed.number.value).to eq("15189HB")
        end

        it "parses year" do
          expect(parsed.year).to eq("2025")
        end

        it "uses colon format" do
          expect(parsed.year_format).to eq("colon")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA B149HB:15" do
        subject { "CSA B149HB:15" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses code with HB" do
          expect(parsed.number.value).to eq("B149HB")
        end

        it "parses year" do
          expect(parsed.year).to eq("2015")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "French year prefix" do
      describe "CSA B149.1:F20" do
        subject { "CSA B149.1:F20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Standard" do
          expect(parsed).to be_a(described_class)
        end

        it "parses code" do
          expect(parsed.number.value).to eq("B149.1")
        end

        it "parses year" do
          expect(parsed.year).to eq("2020")
        end

        it "detects French" do
          expect(parsed.french).to be true
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "complex decimal codes" do
      describe "CSA Z259.2.4:15 (R2020)" do
        subject { "CSA Z259.2.4:15 (R2020)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses multi-part code" do
          expect(parsed.number.value).to eq("Z259.2.4")
        end

        it "parses year" do
          expect(parsed.year).to eq("2015")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2020")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "partial reference (no year)" do
      describe "CSA Z299.1" do
        subject { "CSA Z299.1" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Standard" do
          expect(parsed).to be_a(described_class)
        end

        it "parses code" do
          expect(parsed.number.value).to eq("Z299.1")
        end

        it "leaves year nil" do
          expect(parsed.year).to be_nil
        end

        it "round-trips correctly (no trailing year)" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA B149.1" do
        subject { "CSA B149.1" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses code" do
          expect(parsed.number.value).to eq("B149.1")
        end

        it "leaves year nil" do
          expect(parsed.year).to be_nil
        end

        it "round-trips correctly (no trailing year)" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end
  end
end
