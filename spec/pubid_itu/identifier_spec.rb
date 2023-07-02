module Pubid::Itu
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "ITU-T T.4" do
      let(:pubid) { "ITU-T T.4" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T L.163" do
      let(:pubid) { "ITU-T L.163" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-R V.574-5" do
      let(:pubid) { "ITU-R V.574-5" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-R REC V.574-5" do
      let(:pubid) { "ITU-R REC-V.574-5" }

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
    end

    # handbook
    context "ITU-R 20-200" do
      let(:pubid) { "ITU-R 20-200" }

      it_behaves_like "converts pubid to pubid"
    end

    # resolution
    context "ITU-R R.9-6" do
      let(:pubid) { "ITU-R R.9-6" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T T.4" do
      let(:pubid) { "ITU-T T.4" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU T-REC-T.4" do
      let(:original) { "ITU T-REC-T.4" }
      let(:pubid) { "ITU-T REC-T.4" }
      let(:pubid_without_type) { "ITU-T T.4" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to pubid without type"
    end

    context "ITU-T REC-T.4" do
      let(:pubid) { "ITU-T REC-T.4" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T REC T.4" do
      let(:original) { "ITU-T REC T.4" }
      let(:pubid) { "ITU-T REC-T.4" }

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
      let(:pubid) { "ITU-T REC-T.4 (07/2003)" }

      it_behaves_like "converts pubid to pubid"
    end

    describe "parse identifiers from examples files" do
      context "parses IEC identifiers from itu-r.txt" do
        let(:examples_file) { "itu-r.txt" }

        it_behaves_like "parse identifiers from file"
      end
    end
  end

end
