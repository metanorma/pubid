module Pubid::Ccsds
  RSpec.describe Identifier do
    describe "creating new identifier" do
      subject { described_class.create(**{ number: number, type: type, edition: edition }.merge(params)) }
      let(:number) { 123 }
      let(:type) { "B" }
      let(:edition) { 1 }
      let(:params) { {} }

      it "renders default publisher" do
        expect(subject.to_s).to eq("CCSDS #{number}.0-B-1")
      end

      context "with part" do
        let(:params) { { part: 1 } }

        it "renders identifier with part" do
          expect(subject.to_s).to eq("CCSDS #{number}.1-B-1")
        end
      end

      context "with series" do
        let(:params) { { series: "A" } }

        it "renders identifier with series" do
          expect(subject.to_s).to eq("CCSDS A#{number}.0-B-1")
        end
      end

      context "when retired" do
        let(:params) { { retired: true } }

        it "renders retired identifier" do
          expect(subject.to_s).to eq("CCSDS #{number}.0-B-1-S")
        end
      end
    end
  end
end
