module Pubid
  RSpec.describe Registry do
    describe "#parse" do
      subject { described_class.parse(pubid) }

      context "when ISO identifier provided" do
        let(:pubid) { "ISO/IEC 13213" }

        it "returns ISO instance" do
          expect(subject).to be_a Pubid::Iso::Identifier::Base
        end
      end

      context "when IEEE identifier provided" do
        let(:pubid) { "IEEE/ANSI Std 484-1987" }

        it "returns IEEE instance" do
          expect(subject).to be_a Pubid::Ieee::Identifier::Base
        end
      end

      context "when NIST identifier provided" do
        let(:pubid) { "NIST SP 800-38A Add. 1" }

        it "returns NIST instance" do
          expect(subject).to be_a Pubid::Nist::Identifier
        end
      end

      context "when IEC identifier provided" do
        let(:pubid) { "IEC SRD 62913-1:2019" }

        it "returns IEC instance" do
          expect(subject).to be_a Pubid::Iec::Base
        end
      end

      context "when CEN identifier provided" do
        let(:pubid) { "CLC/TR 62125:2008" }

        it "returns CEN instance" do
          expect(subject).to be_a Pubid::Cen::Identifier::Base
        end
      end

      context "when BSI identifier provided" do
        let(:pubid) { "BS 4592-0:2006+A1:2012" }

        it "returns BSI instance" do
          expect(subject).to be_a Pubid::Bsi::Identifier::Base
        end
      end

      context "when CCSDS identifier provided" do
        let(:pubid) { "CCSDS 100.0-G-1-S" }

        it "returns CCSDS instance" do
          expect(subject).to be_a Pubid::Ccsds::Identifier::Base
        end
      end

      context "when ITU identifier provided" do
        let(:pubid) { "ITU-T E.156 Suppl. 2" }

        it "returns ITU instance" do
          expect(subject).to be_a Pubid::Itu::Identifier::Base
        end
      end

      context "when JIS identifier provided" do
        let(:pubid) { "JIS C 61000-3-2" }

        it "returns JIS instance" do
          expect(subject).to be_a Pubid::Jis::Identifier::Base
        end
      end

      context "when unparseable identifier provided" do
        let(:pubid) { "UNPARSEABLE_IDENTIFIER" }

        it "returns JIS instance" do
          expect { subject }.to raise_error(Pubid::Core::Errors::ParseError)
        end
      end
    end
  end
end
