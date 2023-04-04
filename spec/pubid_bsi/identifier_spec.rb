module Pubid::Bsi
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "BS 0" do
      let(:pubid) { "BS 0" }

      it_behaves_like "converts pubid to pubid"
    end

    context "BS 7121-3:2017" do
      let(:pubid) { "BS 7121-3:2017" }

      it_behaves_like "converts pubid to pubid"
    end

    context "PAS 1192-2:2014" do
      let(:pubid) { "PAS 1192-2:2014" }

      it_behaves_like "converts pubid to pubid"
    end

    context "PD 19650-0:2019" do
      let(:pubid) { "PD 19650-0:2019" }

      it_behaves_like "converts pubid to pubid"
    end

    context "Flex 8670:2021-04" do
      let(:original) { "Flex 8670:2021-04" }
      let(:pubid) { "BSI Flex 8670:2021-04" }

      it_behaves_like "converts pubid to pubid"
    end

    context "Flex 8670 v3.0:2021-04" do
      let(:original) { "Flex 8670 v3.0:2021-04" }
      let(:pubid) { "BSI Flex 8670 v3.0:2021-04" }

      it_behaves_like "converts pubid to pubid"
    end

    context "BSI Flex 1889 v1.0:2022-07" do
      let(:pubid) { "BSI Flex 1889 v1.0:2022-07" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 37101:2016" do
      let(:pubid) { "ISO 37101:2016" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC 29151" do
      let(:pubid) { "ISO/IEC 29151" }

      it_behaves_like "converts pubid to pubid"
    end

    context "IEC 62366-1" do
      let(:pubid) { "IEC 62366-1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "IEC 60384-23:2023 ED3" do
      let(:pubid) { "IEC 60384-23:2023 ED3" }

      it_behaves_like "converts pubid to pubid"
    end

    context "IEC 61834-1:1998+AMD1:2001 CSV" do
      let(:pubid) { "IEC 61834-1:1998+AMD1:2001 CSV" }

      it_behaves_like "converts pubid to pubid"
    end

    context "DD 240-1:1997" do
      let(:pubid) { "DD 240-1:1997" }

      it_behaves_like "converts pubid to pubid"
    end

    context "BS 4592-0:2006+A1:2012" do
      let(:pubid) { "BS 4592-0:2006+A1:2012" }

      it_behaves_like "converts pubid to pubid"
    end

    context "PD 5500:2021+A2:2022" do
      let(:pubid) { "PD 5500:2021+A2:2022" }

      it_behaves_like "converts pubid to pubid"
    end

    context "PAS 3002:2018+C1:2018" do
      let(:pubid) { "PAS 3002:2018+C1:2018" }

      it_behaves_like "converts pubid to pubid"
    end

    context "adopted documents" do
      context "PD IEC/TR 80002-3:2014" do
        let(:original) { "PD IEC/TR 80002-3:2014" }
        let(:pubid) { "PD IEC TR 80002-3:2014" }

        it_behaves_like "converts pubid to pubid"

        it { expect(subject.adopted).to be_a(Pubid::Iec::Base) }
        it { expect(subject.adopted.to_s).to eq("IEC TR 80002-3:2014") }
      end

      context "BS ISO/IEC 30134-1:2016" do
        let(:pubid) { "BS ISO/IEC 30134-1:2016" }

        it_behaves_like "converts pubid to pubid"

        it { expect(subject.adopted).to be_a(Pubid::Iec::Base) }
        it { expect(subject.adopted.to_s).to eq("ISO/IEC 30134-1:2016") }
      end

      context "BS ISO/PRF PAS 5643" do
        let(:original) { "BS ISO/PRF PAS 5643" }
        let(:pubid) { "BS ISO/PAS 5643" }

        it_behaves_like "converts pubid to pubid"

        it { expect(subject.adopted).to be_a(Pubid::Iso::Identifier::Base) }
      end

      context "BS ISO/DIS 22000:2017" do
        let(:pubid) { "BS ISO/DIS 22000:2017" }

        it_behaves_like "converts pubid to pubid"
      end

      context "BS ISO/DIS 9004.1:2017" do
        let(:pubid) { "BS ISO/DIS 9004.1:2017" }

        it_behaves_like "converts pubid to pubid"
      end

      context "BS ISO/FDIS 22301:2012" do
        let(:pubid) { "BS ISO/FDIS 22301:2012" }

        it_behaves_like "converts pubid to pubid"
      end

      context "DD CEN/TS 1992-4-2:2009" do
        let(:pubid) { "DD CEN/TS 1992-4-2:2009" }

        it_behaves_like "converts pubid to pubid"
      end

      context "BS EN 15154-5:2019" do
        let(:pubid) { "BS EN 15154-5:2019" }

        it_behaves_like "converts pubid to pubid"
      end

      context "PD CEN/TS 16415:2013" do
        let(:pubid) { "PD CEN/TS 16415:2013" }

        it_behaves_like "converts pubid to pubid"
      end

      context "2-level adoptions" do
        context "BS EN ISO 13485:2012" do
          let(:pubid) { "BS EN ISO 13485:2012" }

          it_behaves_like "converts pubid to pubid"
        end

        context "BS EN ISO 13485:2016+A11:2021" do
          let(:pubid) { "BS EN ISO 13485:2016+A11:2021" }

          it_behaves_like "converts pubid to pubid"
        end

        context "BS EN IEC 62368-1:2020+A11:2020" do
          let(:pubid) { "BS EN IEC 62368-1:2020+A11:2020" }

          it_behaves_like "converts pubid to pubid"
        end

        context "BS EN ISO/IEC 80079-34:2020 ED2" do
          let(:pubid) { "BS EN ISO/IEC 80079-34:2020 ED2" }

          it_behaves_like "converts pubid to pubid"
        end

        context "PD CISPR TR 16-4-5:2006+A2:2021" do
          let(:pubid) { "PD CISPR TR 16-4-5:2006+A2:2021" }

          it_behaves_like "converts pubid to pubid"
        end
      end
    end

    context "expert commentary identifier" do
      context "BS 5250:2021 ExComm" do
        let(:pubid) { "BS 5250:2021 ExComm" }

        it_behaves_like "converts pubid to pubid"
      end

      context "BS 7273-4:2015+A1:2021 ExComm" do
        let(:pubid) { "BS 7273-4:2015+A1:2021 ExComm" }

        it_behaves_like "converts pubid to pubid"
      end

      context "BS EN ISO 13485:2016+A11:2021 ExComm" do
        let(:pubid) { "BS EN ISO 13485:2016+A11:2021 ExComm" }

        it_behaves_like "converts pubid to pubid"
      end

      context "BS EN 61000-3-3:2013+A2:2021 ExComm" do
        let(:pubid) { "BS EN 61000-3-3:2013+A2:2021 ExComm" }

        it_behaves_like "converts pubid to pubid"
      end

      context "BS EN IEC 62115:2020+A11:2020 ExComm" do
        let(:pubid) { "BS EN IEC 62115:2020+A11:2020 ExComm" }

        it_behaves_like "converts pubid to pubid"
      end

      context "BS EN ISO/IEC 80079-34:2020 ExComm" do
        let(:pubid) { "BS EN ISO/IEC 80079-34:2020 ExComm" }

        it_behaves_like "converts pubid to pubid"
      end
    end

    context "PAS 96:2017 - TC" do
      let(:pubid) { "PAS 96:2017 - TC" }

      it_behaves_like "converts pubid to pubid"
    end
  end
end
