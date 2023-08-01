module Pubid::Itu
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "ITU-T T.4" do
      let(:pubid) { "ITU-T T.4" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::Recommendation) }
    end

    context "ITU-T L.163" do
      let(:original) { "ITU-T L.163" }
      let(:pubid) { "ITU-T L.163" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-R V.574-5" do
      let(:pubid) { "ITU-R V.574-5" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-R REC V.574-5" do
      let(:original) { "ITU-R REC-V.574-5" }
      let(:pubid) { "ITU-R V.574-5" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-R SA.364-6" do
      let(:pubid) { "ITU-R SA.364-6" }

      it_behaves_like "converts pubid to pubid"
    end

    # question
    context "ITU-R SG01.222-200" do
      let(:pubid) { "ITU-R SG01.222-200" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::Question) }
    end

    # handbook
    context "ITU-R 20-200" do
      let(:pubid) { "ITU-R 20-200" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_an_instance_of(Identifier::Base) }
    end

    # resolution
    context "ITU-R R.9-6" do
      let(:pubid) { "ITU-R R.9-6" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::Resolution) }
    end

    context "ITU T-REC-T.4" do
      let(:original) { "ITU T-REC-T.4" }
      let(:pubid) { "ITU-T T.4" }
      let(:pubid_with_type) { "ITU-T REC-T.4" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to pubid with type"
    end

    context "ITU-T REC-T.4" do
      let(:original) { "ITU-T REC-T.4" }
      let(:pubid) { "ITU-T T.4" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T REC T.4" do
      let(:original) { "ITU-T REC T.4" }
      let(:pubid) { "ITU-T T.4" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T T.4 (07/2003)" do
      let(:pubid) { "ITU-T T.4 (07/2003)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-R 52 (2014)" do
      let(:pubid) { "ITU-R 52 (2014)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU T-REC-T.4-200307" do
      let(:original) { "ITU T-REC-T.4-200307" }
      let(:pubid) { "ITU-T T.4 (07/2003)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU T-REC-T.4-200307-I" do
      let(:original) { "ITU T-REC-T.4-200307-I" }
      let(:pubid) { "ITU-T T.4 (07/2003)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T OB.1096" do
      let(:original) { "ITU-T OB.1096" }
      let(:pubid) { "ITU-T OB.1096" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::SpecialPublication) }
    end

    context "ITU-T Operational Bulletin No. 1096" do
      let(:original) { "ITU-T Operational Bulletin No. 1096" }
      let(:pubid) { "ITU-T OB.1096" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::SpecialPublication) }
    end

    context "ITU-T OB.1096 - 15.III.2016" do
      let(:original) { "ITU-T OB.1096 - 15.III.2016" }
      let(:pubid) { "ITU-T OB.1096 (03/2016)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T G.989 Amd 1" do
      let(:pubid) { "ITU-T G.989 Amd 1" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::Amendment) }
    end

    context "ITU-T G.989.2" do
      let(:pubid) { "ITU-T G.989.2" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T G.989 Amd. 1" do
      let(:original) { "ITU-T G.989 Amd. 1" }
      let(:pubid) { "ITU-T G.989 Amd 1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T M.3016.1" do
      let(:pubid) { "ITU-T M.3016.1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-R RR (2020)" do
      let(:pubid) { "ITU-R RR (2020)" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::RegulatoryPublication) }
    end

    context "ITU-T G.780/Y.1351" do
      let(:pubid) { "ITU-T G.780/Y.1351" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject.second_number[:series]).to eq("Y") }
      it { expect(subject.second_number[:number]).to eq("1351") }
    end

    context "ITU-T G.Imp712" do
      let(:pubid) { "ITU-T G.Imp712" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::ImplementersGuide) }
    end

    context "ITU-T X.ImpOSI" do
      let(:pubid) { "ITU-T X.ImpOSI" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::ImplementersGuide) }
    end

    context "ITU-T G.780/Y.1351 (2004) Amend. 1" do
      let(:original) { "ITU-T G.780/Y.1351 (2004) Amend. 1" }
      let(:pubid) { "ITU-T G.780/Y.1351 Amd 1 (2004)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "Supplements" do
      context "ITU-T H Suppl. 1" do
        let(:pubid) { "ITU-T H Suppl. 1" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ITU-T E.156 Suppl. 2" do
        let(:pubid) { "ITU-T E.156 Suppl. 2" }

        it_behaves_like "converts pubid to pubid"

        it { expect(subject.base.number).to eq("156") }
        it { expect(subject).to be_a(Identifier::Supplement) }
      end

      context "ITU-T A Suppl. 2 (12/2022)" do
        let(:pubid) { "ITU-T A Suppl. 2 (12/2022)" }

        it_behaves_like "converts pubid to pubid"

        it { expect(subject.base.number).to eq(nil) }
        it { expect(subject).to be_a(Identifier::Supplement) }
      end
    end

    context "ITU-T Z.100 Annex F2 (06/2021)" do
      let(:pubid) { "ITU-T Z.100 Annex F2 (06/2021)" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::Annex) }
    end

    context "ITU-T G.729 Annex A (11/1996)" do
      let(:pubid) { "ITU-T G.729 Annex A (11/1996)" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::Annex) }
    end

    context "ITU-T G.729 Annex C+ (02/2000)" do
      let(:pubid) { "ITU-T G.729 Annex C+ (02/2000)" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::Annex) }
    end

    context "ITU-T Z.100 (1999) Cor. 1 (10/2001)" do
      let(:pubid) { "ITU-T Z.100 (1999) Cor. 1 (10/2001)" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::Corrigendum) }
    end

    context "ITU-T G.729 Annex E (1998) Cor. 1 (02/2000)" do
      let(:pubid) { "ITU-T G.729 Annex E (1998) Cor. 1 (02/2000)" }

      it_behaves_like "converts pubid to pubid"

      it { expect(subject).to be_a(Identifier::Corrigendum) }
      it { expect(subject.base).to be_a(Identifier::Annex) }
    end

    describe "parse identifiers from examples files" do
      context "parses IEC identifiers from itu-r.txt" do
        let(:examples_file) { "itu-r.txt" }

        it_behaves_like "parse identifiers from file"
      end
    end
  end

end
