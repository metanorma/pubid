module Pubid::Nist
  RSpec.describe Identifier do
    describe "creating new identifier" do
      subject { described_class.create(**{ number: number, series: series }.merge(params)) }
      let(:number) { 123 }
      let(:params) { {} }
      let(:series) { "SP" }

      it "renders default publisher" do
        expect(subject).to eq("NIST SP #{number}")
      end

      context "White Paper series" do
        let(:series) { "CSWP" }
        let(:number) { 999 }
        let(:params) { { edition_year: "2013",
                         edition_month: "01",
                         edition_day: "01",
                         stage: { id: "i", type: "pd" } } }

        it "returns correct short identifier" do
          expect(subject.to_s).to eq("NIST CSWP 999e20130101 ipd")
        end

        it "returns correct long identifier" do
          expect(subject.to_s(:long)).to eq("National Institute of Standards and Technology Cybersecurity White Papers 999 (Initial Public Draft) (January 01, 2013)")
        end
      end

      context "edition with sequence"
    end
  end
end
