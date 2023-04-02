module Pubid::Cen
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "EN 1177:2008" do
      let(:pubid) { "EN 1177:2008" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CEN/TS 14972" do
      let(:pubid) { "CEN/TS 14972" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CLC/TR 62125:2008" do
      let(:pubid) { "CLC/TR 62125:2008" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CEN/CLC/TR 17602-80-12:2021" do
      let(:pubid) { "CEN/CLC/TR 17602-80-12:2021" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CEN/CLC Guide 25:2023" do
      let(:pubid) { "CEN/CLC Guide 25:2023" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CEN/CLC/TR 17602-80-12:2021" do
      let(:pubid) { "CEN/CLC/TR 17602-80-12:2021" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CEN-CLC Guide 32:2016" do
      let(:original) { "CEN-CLC Guide 32:2016" }
      let(:pubid) { "CEN/CLC Guide 32:2016" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CLC GUIDE 1:2022" do
      let(:original) { "CLC GUIDE 1:2022" }
      let(:pubid) { "CLC Guide 1:2022" }

      it_behaves_like "converts pubid to pubid"
    end

    context "prEN 12464-1:2019" do
      let(:pubid) { "prEN 12464-1:2019" }

      it_behaves_like "converts pubid to pubid"
    end

    context "FprEN 16114:2011" do
      let(:pubid) { "FprEN 16114:2011" }

      it_behaves_like "converts pubid to pubid"
    end

    context "EN 60335-1:2012/A2:2019" do
      let(:pubid) { "EN 60335-1:2012/A2:2019" }

      it_behaves_like "converts pubid to pubid"
    end

    context "EN 196-3:2005+A1:2008" do
      let(:pubid) { "EN 196-3:2005+A1:2008" }

      it_behaves_like "converts pubid to pubid"
    end

    context "EN 196-3:2005+AС1:2008" do
      let(:pubid) { "EN 196-3:2005+AC1:2008" }

      it_behaves_like "converts pubid to pubid"
    end

    context "EN 10077-1:2006+AC:2009+AC2:2009" do
      let(:pubid) { "EN 10077-1:2006+AC:2009+AC2:2009" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CWA 95000:2019" do
      let(:pubid) { "CWA 95000:2019" }

      it_behaves_like "converts pubid to pubid"
    end

    context "HD 1000:1988" do
      let(:pubid) { "HD 1000:1988" }

      it_behaves_like "converts pubid to pubid"
    end

    context "adoptions" do
      context "EN ISO 14090:2019" do
        let(:pubid) { "EN ISO 14090:2019" }

        it_behaves_like "converts pubid to pubid"
      end

      context "EN IEC 62368-1:2020" do
        let(:pubid) { "EN IEC 62368-1:2020" }

        it_behaves_like "converts pubid to pubid"
      end

      context "EN IEC 62368-1:2020+A11:2020" do
        let(:pubid) { "EN IEC 62368-1:2020+A11:2020" }

        it_behaves_like "converts pubid to pubid"
      end

      context "EN ISO 13485:2016/AC:2016" do
        let(:pubid) { "EN ISO 13485:2016/AC:2016" }

        it_behaves_like "converts pubid to pubid"
      end

      context "EN ISO 10077-1:2006+AC:2009+AC2:2009" do
        let(:pubid) { "EN ISO 10077-1:2006+AC:2009+AC2:2009" }

        it_behaves_like "converts pubid to pubid"
      end
    end
  end
end
