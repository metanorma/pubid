# frozen_string_literal: true

require "spec_helper"
require "pubid/jcgm"

RSpec.describe Pubid::Jcgm do
  describe ".parse" do
    context "standard guides" do
      describe "JCGM 100:2008" do
        subject { "JCGM 100:2008" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as Guide" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Guide)
        end

        it "parses publisher" do
          expect(parsed.publisher.to_s).to eq("JCGM")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("100")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2008")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "JCGM 100:2008(E)" do
        subject { "JCGM 100:2008(E)" }

        let(:parsed) { described_class.parse(subject) }

        it "parses language" do
          expect(parsed.languages.size).to eq(1)
          expect(parsed.languages.first.code).to eq("en")
          expect(parsed.languages.first.original_code).to eq("E")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "JCGM 200:2012(E/F)" do
        subject { "JCGM 200:2012(E/F)" }

        let(:parsed) { described_class.parse(subject) }

        it "parses multiple languages" do
          expect(parsed.languages.size).to eq(2)
          expect(parsed.languages.map(&:code)).to eq(["en", "fr"])
          expect(parsed.languages.map(&:original_code)).to eq(["E", "F"])
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "standard guides with language codes" do
      describe "JCGM 200:2007(F)" do
        subject { "JCGM 200:2007(F)" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as Guide" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Guide)
        end

        it "parses publisher" do
          expect(parsed.publisher.to_s).to eq("JCGM")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("200")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2007")
        end

        it "parses language" do
          expect(parsed.languages.size).to eq(1)
          expect(parsed.languages.first.code).to eq("fr")
          expect(parsed.languages.first.original_code).to eq("F")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "JCGM 200:2008(F)" do
        subject { "JCGM 200:2008(F)" }

        let(:parsed) { described_class.parse(subject) }

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "GUM guides" do
      describe "JCGM GUM-6:2020" do
        subject { "JCGM GUM-6:2020" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as GumGuide" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::GumGuide)
        end

        it "parses publisher" do
          expect(parsed.publisher.to_s).to eq("JCGM")
        end

        it "parses GUM number" do
          expect(parsed.number.value).to eq("6")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2020")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "JCGM GUM-1:2022-11-28" do
        subject { "JCGM GUM-1:2022-11-28" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as GumGuide" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::GumGuide)
        end

        it "parses GUM number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses full date" do
          expect(parsed.date.year).to eq("2022")
          expect(parsed.date.month).to eq("11")
          expect(parsed.date.day).to eq("28")
        end

        it "renders full date correctly" do
          expect(parsed.date.to_s).to eq("2022-11-28")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "committee meetings" do
      describe "JCGM 17th Meeting (2012)" do
        subject { "JCGM 17th Meeting (2012)" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as Meeting" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Meeting)
        end

        it "parses publisher" do
          expect(parsed.publisher.to_s).to eq("JCGM")
        end

        it "parses the meeting number as a clean integer value" do
          expect(parsed.number.value).to eq("17")
        end

        it "parses the year" do
          expect(parsed.date.year).to eq("2012")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      # Exercise the naive last-digit ordinal rule (1->st, 2->nd, 3->rd,
      # else th; NO 11/12/13 teens exception) — matches the real records.
      {
        "JCGM 11st Meeting (2006)" => %w[11 2006],
        "JCGM 12nd Meeting (2007)" => %w[12 2007],
        "JCGM 13rd Meeting (2008)" => %w[13 2008],
        "JCGM 15th Meeting (2009)" => %w[15 2009],
        "JCGM 21st Meeting (2017)" => %w[21 2017],
        "JCGM 22nd Meeting (2018)" => %w[22 2018],
        "JCGM 23rd Meeting (2020)" => %w[23 2020],
      }.each do |id_str, (number, year)|
        describe id_str do
          subject { id_str }

          let(:parsed) { described_class.parse(subject) }

          it "parses as Meeting with number #{number} and year #{year}" do
            expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Meeting)
            expect(parsed.number.value).to eq(number)
            expect(parsed.date.year).to eq(year)
          end

          it "round-trips" do
            expect(parsed.to_s).to eq(subject)
          end
        end
      end
    end

    context "amendments" do
      describe "JCGM 100:2008/Amd 1" do
        subject { "JCGM 100:2008/Amd 1" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as Amendment" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Amendment)
        end

        it "parses base identifier" do
          expect(parsed.base).to be_a(Pubid::Jcgm::Identifiers::Guide)
          expect(parsed.base.number.value).to eq("100")
          expect(parsed.base.date.year).to eq("2008")
        end

        it "parses the amendment number" do
          expect(parsed.number.value).to eq("1")
        end

        it "has no amendment date" do
          expect(parsed.date).to be_nil
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "JCGM 100:2008/Amd 1:2025-07-25" do
        subject { "JCGM 100:2008/Amd 1:2025-07-25" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as Amendment" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Amendment)
        end

        it "parses base identifier" do
          expect(parsed.base).to be_a(Pubid::Jcgm::Identifiers::Guide)
        end

        it "parses the amendment number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses amendment full date" do
          expect(parsed.date.year).to eq("2025")
          expect(parsed.date.month).to eq("07")
          expect(parsed.date.day).to eq("25")
          expect(parsed.date.to_s).to eq("2025-07-25")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "named guides (dateless vocabulary tokens)" do
      {
        "JCGM GUM" => "GUM",
        "JCGM VIM-3" => "VIM-3",
      }.each do |id_str, number|
        describe id_str do
          subject { id_str }

          let(:parsed) { described_class.parse(subject) }

          it "parses as a plain Guide with the token as its number" do
            expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Guide)
            expect(parsed.number.value).to eq(number)
          end

          it "has no date" do
            expect(parsed.date).to be_nil
          end

          it "parses publisher" do
            expect(parsed.publisher.to_s).to eq("JCGM")
          end

          it "round-trips" do
            expect(parsed.to_s).to eq(subject)
          end
        end
      end
    end

    context "corrigendum" do
      describe "JCGM 200:2008 Corrigendum" do
        subject { "JCGM 200:2008 Corrigendum" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as Corrigendum" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Corrigendum)
        end

        it "parses the base identifier as a Guide 200:2008" do
          expect(parsed.base).to be_a(Pubid::Jcgm::Identifiers::Guide)
          expect(parsed.base.number.value).to eq("200")
          expect(parsed.base.date.year).to eq("2008")
        end

        it "carries no number (word form)" do
          expect(parsed.number).to be_nil
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "JCGM 101:2008/Cor 1:2009" do
        subject { "JCGM 101:2008/Cor 1:2009" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as Corrigendum" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Corrigendum)
        end

        it "parses the base identifier as Guide 101:2008" do
          expect(parsed.base).to be_a(Pubid::Jcgm::Identifiers::Guide)
          expect(parsed.base.number.value).to eq("101")
          expect(parsed.base.date.year).to eq("2008")
        end

        it "carries the corrigendum number" do
          expect(parsed.number).to be_a(Pubid::Components::Code)
          expect(parsed.number.value).to eq("1")
        end

        it "carries the corrigendum date" do
          expect(parsed.date.year).to eq("2009")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "produces a URN distinguishing the corrigendum" do
          expect(parsed.to_urn).to eq("urn:jcgm:101:2008:corrigendum:1:2009")
        end
      end

      describe "JCGM 101:2008/Cor 1 (dateless)" do
        subject { "JCGM 101:2008/Cor 1" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as Corrigendum" do
          expect(parsed).to be_a(Pubid::Jcgm::Identifiers::Corrigendum)
        end

        it "carries the number but no date" do
          expect(parsed.number.value).to eq("1")
          expect(parsed.date).to be_nil
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end
  end
end
