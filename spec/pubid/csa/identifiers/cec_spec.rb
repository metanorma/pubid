# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Csa::Identifiers::Cec do
  subject { described_class }

  describe "parsing CEC identifiers" do
    context "C22.2 NO. patterns" do
      describe "CSA C22.2 NO. 286:23" do
        subject { "CSA C22.2 NO. 286:23" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CecIdentifier" do
          expect(parsed).to be_a(described_class)
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

      describe "CSA C22.2 NO. 0:20" do
        subject { "CSA C22.2 NO. 0:20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CecIdentifier" do
          expect(parsed).to be_a(described_class)
        end

        it "parses NO. number" do
          expect(parsed.no_number.value).to eq("0")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA C22.2 NO. 60601-1-9:22" do
        subject { "CSA C22.2 NO. 60601-1-9:22" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses complex NO. number" do
          expect(parsed.no_number.value).to eq("60601-1-9")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "other C22.x parts" do
      describe "CSA C22.3 NO. 7:20" do
        subject { "CSA C22.3 NO. 7:20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses C22.3 part" do
          expect(parsed.cec_part.value).to eq("C22.3")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA C22.4 NO. 1:18" do
        subject { "CSA C22.4 NO. 1:18" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses C22.4 part" do
          expect(parsed.cec_part.value).to eq("C22.4")
        end
      end

      describe "CSA C22.6 NO. 5:19" do
        subject { "CSA C22.6 NO. 5:19" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses C22.6 part" do
          expect(parsed.cec_part.value).to eq("C22.6")
        end
      end
    end

    context "with dash year format" do
      describe "CSA C22.2 NO. 0.16-M92 (R2001)" do
        subject { "CSA C22.2 NO. 0.16-M92 (R2001)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses dotted NO. number" do
          expect(parsed.no_number.value).to eq("0.16")
        end

        it "parses M prefix year" do
          expect(parsed.year).to eq("1992")
          expect(parsed.year_prefix).to eq("M")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2001")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "with French year prefix" do
      describe "CSA C22.2 NO. 144.1:F20" do
        subject { "CSA C22.2 NO. 144.1:F20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses dotted NO. number" do
          expect(parsed.no_number.value).to eq("144.1")
        end

        it "parses F prefix year" do
          expect(parsed.year_prefix).to eq("F")
          expect(parsed.french).to be true
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "wrapped in CanadianAdopted" do
      describe "CAN/CSA-C22.2 NO. 286:23" do
        subject { "CAN/CSA-C22.2 NO. 286:23" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CanadianAdopted" do
          expect(parsed).to be_a(Pubid::Csa::Identifiers::CanadianAdopted)
        end

        it "wraps CecIdentifier" do
          expect(parsed.base).to be_a(described_class)
        end

        it "preserves CAN/CSA- prefix in rendering" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CAN3-C22.2 NO. 0.16-M92" do
        subject { "CAN3-C22.2 NO. 0.16-M92" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as CanadianAdopted" do
          expect(parsed).to be_a(Pubid::Csa::Identifiers::CanadianAdopted)
        end

        it "wraps CecIdentifier" do
          expect(parsed.base).to be_a(described_class)
        end
      end
    end
  end
end
