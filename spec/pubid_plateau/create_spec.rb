module Pubid::Plateau
  RSpec.describe Identifier do
    describe "creating new identifier" do
      # type: "EN", number: 1234, part: 4, version: "1.2.3", date: "1999-01"
      let(:base) { described_class.create(**{ type: type, number: number }.merge(params)) }
      subject { base }
      let(:number) { 1 }
      let(:params) { { annex: 1, edition: 1.2 } }

      context "Handbook" do
        let(:type) { :handbook }

        it "renders handbook identifier" do
          expect(subject.to_s).to eq("PLATEAU Handbook #01-1 第1.2版")
        end
      end

      context "Technical Report" do
        let(:type) { :tr }

        it "renders handbook identifier" do
          expect(subject.to_s).to eq("PLATEAU Technical Report #01_1 第1.2版")
        end
      end
    end
  end
end
