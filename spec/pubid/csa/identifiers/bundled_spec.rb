# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Csa::Identifiers::Bundled do
  describe ".parse" do
    context "bundled identifiers with plus separator" do
      describe "CSA B149.1:20 + B149.2:20" do
        subject { "CSA B149.1:20 + B149.2:20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Bundled" do
          expect(parsed).to be_a(described_class)
        end

        it "parses base identifier" do
          expect(parsed.base.number.value).to eq("B149.1")
          expect(parsed.base.year).to eq("2020")
        end

        it "parses bundled identifier" do
          expect(parsed.bundled_with.length).to eq(1)
          expect(parsed.bundled_with.first.number.value).to eq("B149.2")
          expect(parsed.bundled_with.first.year).to eq("2020")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA Z245.1:22 + Z245.2:22" do
        subject { "CSA Z245.1:22 + Z245.2:22" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Bundled" do
          expect(parsed).to be_a(described_class)
        end

        it "parses base code" do
          expect(parsed.base.number.value).to eq("Z245.1")
        end

        it "parses bundled code" do
          expect(parsed.bundled_with.first.number.value).to eq("Z245.2")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "bundled identifiers with reaffirmation" do
      describe "CSA A23.1:19 + A23.2:19 (R2024)" do
        subject { "CSA A23.1:19 + A23.2:19 (R2024)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Bundled" do
          expect(parsed).to be_a(described_class)
        end

        it "parses base identifier" do
          expect(parsed.base.number.value).to eq("A23.1")
          expect(parsed.base.year).to eq("2019")
        end

        it "parses bundled identifier" do
          expect(parsed.bundled_with.first.number.value).to eq("A23.2")
          expect(parsed.bundled_with.first.year).to eq("2019")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2024")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "CSA B108.1:23 + B108.2:23 (R2025)" do
        subject { "CSA B108.1:23 + B108.2:23 (R2025)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses base code" do
          expect(parsed.base.number.value).to eq("B108.1")
        end

        it "parses bundled code" do
          expect(parsed.bundled_with.first.number.value).to eq("B108.2")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2025")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "bundled identifiers with dash year format" do
      describe "CSA C22.1-15 + C22.2-15 (R2020)" do
        subject { "CSA C22.1-15 + C22.2-15 (R2020)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Bundled" do
          expect(parsed).to be_a(described_class)
        end

        it "parses base with dash format" do
          expect(parsed.base.number.value).to eq("C22.1")
          expect(parsed.base.year).to eq("2015")
          expect(parsed.base.year_format).to eq("dash")
        end

        it "parses bundled with dash format" do
          expect(parsed.bundled_with.first.number.value).to eq("C22.2")
          expect(parsed.bundled_with.first.year).to eq("2015")
          expect(parsed.bundled_with.first.year_format).to eq("dash")
        end

        it "round-trips with dash format" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "bundled identifiers with French year prefix" do
      describe "CSA B149.1:F20 + B149.2:F20" do
        subject { "CSA B149.1:F20 + B149.2:F20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Bundled" do
          expect(parsed).to be_a(described_class)
        end

        it "parses base as French" do
          expect(parsed.base.french).to be true
        end

        it "parses bundled as French" do
          expect(parsed.bundled_with.first.french).to be true
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "triple bundled identifiers" do
      describe "CSA A1:20 + A2:20 + A3:20" do
        subject { "CSA A1:20 + A2:20 + A3:20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Bundled" do
          expect(parsed).to be_a(described_class)
        end

        it "parses base identifier" do
          expect(parsed.base.number.value).to eq("A1")
        end

        it "parses two bundled identifiers" do
          expect(parsed.bundled_with.length).to eq(2)
          expect(parsed.bundled_with[0].number.value).to eq("A2")
          expect(parsed.bundled_with[1].number.value).to eq("A3")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "bundled identifiers with NO. notation" do
      describe "CSA C22.2 NO. 1:20 + C22.2 NO. 2:20" do
        subject { "CSA C22.2 NO. 1:20 + C22.2 NO. 2:20" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Bundled" do
          expect(parsed).to be_a(described_class)
        end

        it "parses base code (NO. normalized)" do
          expect(parsed.base.number.value).to eq("C22.2-1")
        end

        it "parses bundled code (NO. normalized)" do
          expect(parsed.bundled_with.first.number.value).to eq("C22.2-2")
        end

        it "round-trips in normalized form" do
          expect(parsed.to_s).to eq("CSA C22.2-1:20 + C22.2-2:20")
        end
      end
    end

    context "bundled with CAN/CSA prefix" do
      describe "CAN/CSA-B127.1:99 + B127.2:99 (R2014)" do
        subject { "CAN/CSA-B127.1:99 + B127.2:99 (R2014)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Bundled" do
          expect(parsed).to be_a(described_class)
        end

        it "parses CAN/CSA prefix" do
          expect(parsed.base.publisher_prefix).to eq("CAN/CSA-")
        end

        it "parses base code" do
          expect(parsed.base.number.value).to eq("B127.1")
        end

        it "parses bundled identifier without prefix" do
          expect(parsed.bundled_with.first.number.value).to eq("B127.2")
        end

        it "parses reaffirmation" do
          expect(parsed.reaffirmation).to eq("2014")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "bundled decimal codes" do
      describe "CSA Z259.13:16 + Z259.14:16 (R2025)" do
        subject { "CSA Z259.13:16 + Z259.14:16 (R2025)" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses base decimal code" do
          expect(parsed.base.number.value).to eq("Z259.13")
        end

        it "parses bundled decimal code" do
          expect(parsed.bundled_with.first.number.value).to eq("Z259.14")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "bundled with mixed year formats" do
      describe "CSA A440.2:22 + A440.3:22" do
        subject { "CSA A440.2:22 + A440.3:22" }

        let(:parsed) { Pubid::Csa.parse(subject) }

        it "parses as Bundled" do
          expect(parsed).to be_a(described_class)
        end

        it "maintains year format consistency" do
          expect(parsed.base.year_format).to eq("colon")
          expect(parsed.bundled_with.first.year_format).to eq("colon")
        end

        it "round-trips correctly" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end
  end
end
