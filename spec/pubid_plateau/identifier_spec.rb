module Pubid::Plateau
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "Handbook" do
      let(:pubid) { "PLATEAU Handbook #00 第1.0版" }

      it_behaves_like "converts pubid to pubid"

      context "with annex" do
        let(:pubid) { "PLATEAU Handbook #03-1 第1.0版" }

        it_behaves_like "converts pubid to pubid"
      end

      context "PLATEAU Handbook #11 第1.0版（民間活用編）" do
        let(:original) { "PLATEAU Handbook #11 第1.0版（民間活用編）" }
        let(:pubid) { "PLATEAU Handbook #06 第1.0版" }

        it_behaves_like "converts pubid to pubid"
      end
    end

    context "Technical Report" do
      let(:pubid) { "PLATEAU Technical Report #01" }

      it_behaves_like "converts pubid to pubid"

      context "with annex" do
        let(:pubid) { "PLATEAU Technical Report #46_1" }

        it_behaves_like "converts pubid to pubid"
      end
    end

    describe "parse identifiers from examples files" do
      context "parses PLATEAU identifiers from pubids.txt" do
        let(:examples_file) { "pubids.txt" }

        it_behaves_like "parse identifiers from file"
      end
    end
  end
end
