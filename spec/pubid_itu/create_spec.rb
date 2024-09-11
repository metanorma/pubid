module Pubid::Itu
  RSpec.describe Identifier do
    describe "creating new identifier" do
      subject do
        described_class.create(**{ number: number, sector: sector,
                                   series: series }.merge(params))
      end
      let(:number) { 123 }
      let(:sector) { "R" }
      let(:series) { "V" }
      let(:params) { {} }

      it "renders identifier" do
        expect(subject.to_s).to eq("ITU-R V.#{number}")
      end

      context "with part" do
        let(:params) { { part: 1 } }

        it "renders identifier with part and year" do
          expect(subject.to_s).to eq("ITU-R V.#{number}-1")
        end

        context "with subpart" do
          let(:params) { { part: "1-2" } }

          it "renders identifier with part and year" do
            expect(subject.to_s).to eq("ITU-R V.#{number}-1-2")
          end
        end
      end

      context "dual-numbered identifier" do
        let(:sector) { "T" }
        let(:params) do
          { series: "G", number: 780,
            second_number: { series: "Y", number: 1351 } }
        end

        it "renders dual-numbered identifier" do
          expect(subject.to_s).to eq("ITU-T G.780/Y.1351")
        end
      end

      context "supplement" do
        context "series supplement" do
          let(:sector) { "T" }
          let(:params) do
            { number: 1, type: :supplement,
              base: Identifier.create(sector: "T", series: "H") }
          end

          it "renders series supplement" do
            expect(subject.to_s).to eq("ITU-T H Suppl. 1")
          end
        end

        context "document's supplement" do
          let(:sector) { "T" }
          let(:params) do
            { number: 1, type: :supplement,
              base: Identifier.create(sector: "T", series: "H", number: 1) }
          end

          it "renders series supplement" do
            expect(subject.to_s).to eq("ITU-T H.1 Suppl. 1")
          end
        end
      end

      context "identifier with language" do
        let(:params) { { language: "en" } }

        it "renders identifier with language" do
          expect(subject.to_s).to eq("ITU-R V.123-E")
        end
      end

      context "Contributions" do
        let(:series) { "SG07" }
        let(:number) { 1000 }
        let(:params) { { type: :contribution } }

        it "renders contribution identifier" do
          expect(subject.to_s).to eq("SG07-C1000")
        end
      end

      context "Special Publication" do
        let(:sector) { "T" }
        let(:series) { "OB" }
        let(:params) { { date: { month: 0o1, year: 2024 } } }
        # let(:params) { { number: 1, type: :supplement, base: Identifier.create(sector: "T", series: "H", number: 1) } }

        # Annex to ITU-T OB.1283 (01/2024)
        it "renders identifier" do
          expect(subject.to_s).to eq("ITU-T OB No. #{number} (01/2024)")
        end
      end

      context "Annex to Special Publication" do
        let(:series) { nil }
        let(:number) { nil }
        let(:params) do
          { type: :annex,
            base: Identifier.create(sector: "T", series: "OB", number: 1) }
        end

        it "renders annex to identifier" do
          expect(subject.to_s).to eq("Annex to ITU-T OB.1")
        end
      end
    end
  end
end
