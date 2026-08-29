# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Csa::Identifiers::Combined do
  describe ".parse" do
    context "dual combined with slash separator" do
      describe "CSA A23.1:24/CSA A23.2:24" do
        subject { "CSA A23.1:24/CSA A23.2:24" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Combined" do
          expect(parsed).to be_a(described_class)
        end

        it "parses first identifier" do
          expect(parsed.identifiers[0].number.value).to eq("A23.1")
          expect(parsed.identifiers[0].year).to eq("2024")
        end

        it "parses second identifier" do
          expect(parsed.identifiers[1].number.value).to eq("A23.2")
          expect(parsed.identifiers[1].year).to eq("2024")
        end

        it "uses slash separator" do
          expect(parsed.separator).to eq("/")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA A23.1:19/CSA A23.2:19" do
        subject { "CSA A23.1:19/CSA A23.2:19" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses first code" do
          expect(parsed.identifiers[0].number.value).to eq("A23.1")
        end

        it "parses second code" do
          expect(parsed.identifiers[1].number.value).to eq("A23.2")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "combined with continuation (no prefix on second)" do
      describe "CSA A123.1-05/A123.5-05 (R2015)" do
        subject { "CSA A123.1-05/A123.5-05 (R2015)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Combined" do
          expect(parsed).to be_a(described_class)
        end

        it "parses first identifier" do
          expect(parsed.identifiers[0].number.value).to eq("A123.1")
          expect(parsed.identifiers[0].year).to eq("2005")
          expect(parsed.identifiers[0].year_format).to eq("dash")
        end

        it "parses second identifier without prefix" do
          expect(parsed.identifiers[1].number.value).to eq("A123.5")
          expect(parsed.identifiers[1].year).to eq("2005")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2015")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA B128.1:06/B128.2:06 (R2021)" do
        subject { "CSA B128.1:06/B128.2:06 (R2021)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses first identifier" do
          expect(parsed.identifiers[0].number.value).to eq("B128.1")
          expect(parsed.identifiers[0].year).to eq("2006")
        end

        it "parses second identifier" do
          expect(parsed.identifiers[1].number.value).to eq("B128.2")
          expect(parsed.identifiers[1].year).to eq("2006")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2021")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "triple combined identifiers" do
      describe "CSA B44:19/B44.1:19/B44.2:19" do
        subject { "CSA B44:19/B44.1:19/B44.2:19" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Combined" do
          expect(parsed).to be_a(described_class)
        end

        it "parses first identifier" do
          expect(parsed.identifiers[0].number.value).to eq("B44")
          expect(parsed.identifiers[0].year).to eq("2019")
        end

        it "parses second identifier" do
          expect(parsed.identifiers[1].number.value).to eq("B44.1")
          expect(parsed.identifiers[1].year).to eq("2019")
        end

        it "parses third identifier" do
          expect(parsed.identifiers[2].number.value).to eq("B44.2")
          expect(parsed.identifiers[2].year).to eq("2019")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "combined with CAN/CSA prefix" do
      describe "CAN/CSA-B138.1-17/CAN/CSA-B138.2-17 (R2022)" do
        subject { "CAN/CSA-B138.1-17/CAN/CSA-B138.2-17 (R2022)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Combined" do
          expect(parsed).to be_a(described_class)
        end

        it "parses first with CAN/CSA prefix" do
          expect(parsed.identifiers[0].publisher_prefix).to eq("CAN/CSA-")
          expect(parsed.identifiers[0].number.value).to eq("B138.1")
          expect(parsed.identifiers[0].year).to eq("2017")
        end

        it "parses second with CAN/CSA prefix" do
          expect(parsed.identifiers[1].publisher_prefix).to eq("CAN/CSA-")
          expect(parsed.identifiers[1].number.value).to eq("B138.2")
          expect(parsed.identifiers[1].year).to eq("2017")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2022")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "combined with SERIES" do
      describe "CSA N285.0:23/CSA N285.6 SERIES:23" do
        subject { "CSA N285.0:23/CSA N285.6 SERIES:23" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Combined" do
          expect(parsed).to be_a(described_class)
        end

        it "parses first as Standard" do
          expect(parsed.identifiers[0]).to be_a(Pubid::Csa::Identifiers::Standard)
          expect(parsed.identifiers[0].number.value).to eq("N285.0")
        end

        it "parses second as Series" do
          expect(parsed.identifiers[1]).to be_a(Pubid::Csa::Identifiers::Series)
          expect(parsed.identifiers[1].number.value).to eq("N285.6")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "combined with colon year format" do
      describe "CSA Z245.11:25/Z245.12:25" do
        subject { "CSA Z245.11:25/Z245.12:25" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses first identifier" do
          expect(parsed.identifiers[0].number.value).to eq("Z245.11")
          expect(parsed.identifiers[0].year).to eq("2025")
          expect(parsed.identifiers[0].year_format).to eq("colon")
        end

        it "parses second identifier" do
          expect(parsed.identifiers[1].number.value).to eq("Z245.12")
          expect(parsed.identifiers[1].year_format).to eq("colon")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "combined with dash year format" do
      describe "CSA C22.10-10/C22.10-18" do
        subject { "CSA C22.10-10/C22.10-18" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses first with dash format" do
          expect(parsed.identifiers[0].number.value).to eq("C22.10")
          expect(parsed.identifiers[0].year).to eq("2010")
          expect(parsed.identifiers[0].year_format).to eq("dash")
        end

        it "parses second with dash format" do
          expect(parsed.identifiers[1].number.value).to eq("C22.10")
          expect(parsed.identifiers[1].year).to eq("2018")
          expect(parsed.identifiers[1].year_format).to eq("dash")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "combined with decimal codes" do
      describe "CSA A440.2:22/CSA A440.3:22" do
        subject { "CSA A440.2:22/CSA A440.3:22" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses first decimal code" do
          expect(parsed.identifiers[0].number.value).to eq("A440.2")
        end

        it "parses second decimal code" do
          expect(parsed.identifiers[1].number.value).to eq("A440.3")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "combined continuation without CSA" do
      describe "CSA B140.1:22/B140.4:22" do
        subject { "CSA B140.1:22/B140.4:22" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Combined" do
          expect(parsed).to be_a(described_class)
        end

        it "first has publisher" do
          expect(parsed.identifiers[0].has_publisher).to be true
        end

        it "second is continuation (no publisher prefix in rendering)" do
          expect(parsed.identifiers[1].has_publisher).to be_falsey
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "combined with French year prefix" do
      describe "CSA B149.1:F20/B149.2:F20" do
        subject { "CSA B149.1:F20/B149.2:F20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses first as French" do
          expect(parsed.identifiers[0].french).to be true
          expect(parsed.identifiers[0].year).to eq("2020")
        end

        it "parses second as French" do
          expect(parsed.identifiers[1].french).to be true
          expect(parsed.identifiers[1].year).to eq("2020")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "combined with mixed year formats" do
      describe "CSA A231.1:19/CSA A231.2:19 (R2024)" do
        subject { "CSA A231.1:19/CSA A231.2:19 (R2024)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses both identifiers" do
          expect(parsed.identifiers[0].number.value).to eq("A231.1")
          expect(parsed.identifiers[1].number.value).to eq("A231.2")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2024")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end
  end
end
