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
    end
  end
end
