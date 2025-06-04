module Pubid::Etsi
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "ETSI EN 300 058-3 V1.2.4 (1998-06)" do
      let(:pubid) { "ETSI EN 300 058-3 V1.2.4 (1998-06)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ETSI ETR 298 ed.1 (1996-09)" do
      let(:pubid) { "ETSI ETR 298 ed.1 (1996-09)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ETSI GS ZSM 012 V1.1.1 (2022-12)" do
      let(:pubid) { "ETSI GS ZSM 012 V1.1.1 (2022-12)" }

      it_behaves_like "converts pubid to pubid"
    end

    # "GSM 02.01" is a number
    context "ETSI GTS GSM 02.01 V5.5.0 (1999-08)" do
      let(:original) { "ETSI GTS GSM 02.01 V5.5.0 (1999-08)" }
      let(:pubid) { "ETSI GTS 02.01 V5.5.0 (1999-08)" }

      it_behaves_like "converts pubid to pubid"
    end

    # "02.06" - number and "-DCS" is a part
    context "ETSI GTS 02.06-DCS V3.0.0 (1995-01)" do
      let(:pubid) { "ETSI GTS 02.06-DCS V3.0.0 (1995-01)" }

      it_behaves_like "converts pubid to pubid"
    end

    # "-EVE" as part of a number
    context "ETSI GR NFV-EVE 022 V5.1.1 (2022-12)" do
      let(:pubid) { "ETSI GR NFV-EVE 022 V5.1.1 (2022-12)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ETSI GR mWT 028 V1.1.1 (2023-04)" do
      let(:pubid) { "ETSI GR mWT 028 V1.1.1 (2023-04)" }

      it_behaves_like "converts pubid to pubid"
    end

    # part and subpart
    context "ETSI GS ECI 001-5-2 V1.1.1 (2017-07)" do
      let(:pubid) { "ETSI GS ECI 001-5-2 V1.1.1 (2017-07)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ETSI ETR 310/C1 ed.1 (1996-10)" do
      let(:pubid) { "ETSI ETR 310/C1 ed.1 (1996-10)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ETSI ETS 300 097-1/A1 ed.1 (1994-11)" do
      let(:pubid) { "ETSI ETS 300 097-1/A1 ed.1 (1994-11)" }

      it_behaves_like "converts pubid to pubid"
    end

    describe "parse identifiers from examples files" do
      context "parses ETSI identifiers from pubids.txt" do
        let(:examples_file) { "pubids.txt" }

        it_behaves_like "parse identifiers from file"
      end
    end
  end
end
