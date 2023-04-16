RSpec.describe Pubid::Nist::Identifier do
  describe "#merge" do
    it "merges two documents" do
      expect(described_class.parse("NIST SP 260-162r1").merge(
        described_class.parse("NIST SP 260-162 2006ed.")
      ).to_s(:short)).to eq("NIST SP 260-162e2006r1")
    end

    context "NBS CIRC 74e1937" do
      it do
        expect(described_class.parse("NBS CIRC 74e1937").merge(
          described_class.parse("NBS.CIRC.74-1937")
        ).to_s(:short)).to eq("NBS CIRC 74e1937")
      end
    end

    context "NBS HB 44-1988" do
      it do
        expect(described_class.parse("NIST HB 44-1988").merge(
          described_class.parse("NBS.HB.44-1988")
        ).to_s(:short)).to eq("NBS HB 44e1988")
      end
    end

    context "NIST FIPS 100-1" do
      it do
        expect(described_class.parse("NIST FIPS 100-1").merge(
          described_class.parse("NBS.FIPS.100-1")
        ).to_s(:short)).to eq("NBS FIPS 100-1")
      end
    end

    context "NIST FIPS 130-1988" do
      it do
        expect(described_class.parse("NIST FIPS 130-1988").merge(
          described_class.parse("NBS.FIPS.130-1988")
        ).to_s(:short)).to eq("NBS FIPS 130-1988")
      end
    end

    context "NIST HB 105-1-1990" do
      it do
        expect(described_class.parse("NIST HB 105-1-1990").merge(
          described_class.parse("NBS.HB.105-1r1990")
        ).to_s(:short)).to eq("NIST HB 105-1r1990")
      end
    end

    context "NIST FIPS 100-1-1991" do
      it do
        expect(described_class.parse("NIST FIPS 100-1-1991").merge(
          described_class.parse("NBS.FIPS.100-1-1991")
        ).to_s(:short)).to eq("NIST FIPS PUB 100-1e1991")
      end
    end

    context "NBS FIPS 11-1-Sep1977" do
      it do
        expect(described_class.parse("NBS FIPS 11-1-Sep1977").merge(
          described_class.parse("NBS.FIPS.11-1-Sep1977")
        ).to_s(:short)).to eq("NBS FIPS 11-1e197709")
      end
    end

    context "NBS FIPS 16-1-1977" do
      it do
        expect(described_class.parse("NBS FIPS 16-1-1977").merge(
          described_class.parse("NBS.FIPS.16-1-1977")
        ).to_s(:short)).to eq("NBS FIPS 16-1e1977")
      end
    end

    context "NBS FIPS 68-2-Aug1987" do
      it do
        expect(described_class.parse("NBS FIPS 68-2-Aug1987").merge(
          described_class.parse("NBS.FIPS.68-2-Aug1987")
        ).to_s(:short)).to eq("NBS FIPS 68-2e198708")
      end
    end

    context "NBS FIPS 107-Mar1985" do
      it do
        expect(described_class.parse("NBS FIPS 107-Mar1985").merge(
          described_class.parse("NBS.FIPS.107-Mar1985")
        ).to_s(:short)).to eq("NBS FIPS 107e198503")
      end
    end

    context "NIST HB 133e4-2002" do
      it do
        expect(described_class.parse("NIST HB 133e4-2002").merge(
          described_class.parse("NIST.HB.133e4")
        ).to_s(:short)).to eq("NIST HB 133e4")
      end
    end

    context "NIST SP 260-126 rev 2013" do
      it do
        expect(described_class.parse("NIST SP 260-126 rev 2013").merge(
          described_class.parse("NIST.SP.260-126rev2013")
        ).to_s(:short)).to eq("NIST SP 260-126r2013")
      end
    end

    context "NIST FIPS 150-Aug1988" do
      it do
        expect(described_class.parse("NIST FIPS 150-Aug1988").merge(
          described_class.parse("NIST.FIPS.150-Aug1988")
        ).to_s(:short)).to eq("NIST FIPS PUB 150e198808")
      end
    end

    context "NBS FIPS 107-Feb1985" do
      it do
        expect(described_class.parse("NBS FIPS 107-Feb1985").merge(
          described_class.parse("NBS.FIPS.107-Feb1985")
        ).to_s(:short)).to eq("NBS FIPS 107e198502")
      end
    end

    context "NIST FIPS 54-1-Jan17" do
      it do
        expect(described_class.parse("NIST FIPS 54-1-Jan17").merge(
          described_class.parse("NIST.FIPS.54-1-Jan17/1991")
        ).to_s(:short)).to eq("NIST FIPS PUB 54-1e19910117")
      end
    end
  end
end
