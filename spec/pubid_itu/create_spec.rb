module Pubid::Itu
  RSpec.describe Identifier do
    describe "creating new identifier" do
      subject { described_class.create(**{ number: number, sector: sector, series: series }.merge(params)) }
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
        let(:params) { { series: "G", number: 780, second_number: { series: "Y", number: 1351 } } }

        it "renders dual-numbered identifier" do
          expect(subject.to_s).to eq("ITU-T G.780/Y.1351")
        end
      end
    end
  end
end
