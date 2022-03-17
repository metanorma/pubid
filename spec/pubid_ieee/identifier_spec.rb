RSpec.describe Pubid::Ieee::Identifier do
  subject { described_class.parse(original) }

  let(:original) { pubid }

  shared_examples "converts pubid to pubid" do
    it "converts pubid to pubid" do
      expect(subject.to_s).to eq(pubid)
    end
  end

  context "IEEE No 142-1956" do
    let(:original) { "IEEE No 142-1956" }
    let(:pubid) { "IEEE 142-1956" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE Std 802.15.22.3-2020" do
    let(:pubid) { "IEEE Std 802.15.22.3-2020" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE Std 1244-5.2000" do
    let(:original) { "IEEE Std 1244-5.2000" }
    let(:pubid) { "IEEE Std 1244.5-2000" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE Std 581.1978" do
    let(:original) { "IEEE Std 581.1978" }
    let(:pubid) { "IEEE Std 581-1978" }

    it_behaves_like "converts pubid to pubid"
  end

  context "ANSI C37.0781-1972" do
    let(:pubid) { "ANSI C37.0781-1972" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE Std 1003.0-1995" do
    let(:pubid) { "IEEE Std 1003.0-1995" }

    it_behaves_like "converts pubid to pubid"
  end

  context "ASA C37.1-1950" do
    let(:pubid) { "ASA C37.1-1950" }

    it_behaves_like "converts pubid to pubid"
  end

  context "ANSI/ IEEE C37.23-1969" do
    let(:original) { "ANSI/ IEEE C37.23-1969" }
    let(:pubid) { "ANSI/IEEE C37.23-1969" }

    it_behaves_like "converts pubid to pubid"
  end

  context "AIEE No 91-1962 (ASA Y32.14-1962)" do
    let(:original) { "AIEE No 91-1962 (ASA Y32.14-1962)" }
    let(:pubid) { "AIEE 91-1962 (ASA Y32.14-1962)" }

    it_behaves_like "converts pubid to pubid"
  end

  context "ANSI C37.61-1973 and IEEE Std 321-1973" do
    let(:original) { "ANSI C37.61-1973 and IEEE Std 321-1973" }
    let(:pubid) { "ANSI C37.61-1973 (IEEE Std 321-1973)" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE Std 623-1976 (ANSI Y32.21-1976, NCTA 006-0975)" do
    let(:pubid) { "IEEE Std 623-1976 (ANSI Y32.21-1976, NCTA 006-0975)" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEC 61671-2 Edition 1.0 2016-04" do
    let(:original) { "IEC 61671-2 Edition 1.0 2016-04" }
    let(:pubid) { "IEC 61671.2 Edition 1.0 2016-04" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEC/IEEE 60076-16 Edition 2.0 2018-09" do
    let(:original) { "IEC/IEEE 60076-16 Edition 2.0 2018-09" }
    let(:pubid) { "IEC/IEEE 60076.16 Edition 2.0 2018-09" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE Std 1003.1, 2004 Edition" do
    let(:original) { "IEEE Std 1003.1, 2004 Edition" }
    let(:pubid) { "IEEE Std 1003.1 Edition 2004" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEC 62525-Edition 1.0 - 2007" do
    let(:original) { "IEC 62525-Edition 1.0 - 2007" }
    let(:pubid) { "IEC 62525 Edition 1.0 2007" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE/ISO/IEC P90003, February 2018 (E)" do
    let(:original) { "IEEE/ISO/IEC P90003, February 2018 (E)" }
    let(:pubid) { "IEEE/ISO/IEC P90003 Edition 2018-02" }

    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC 15288 First edition 2002-11-01" do
    let(:original) { "ISO/IEC 15288 First edition 2002-11-01" }
    let(:pubid) { "ISO/IEC 15288 Edition 1.0 2002-11-01" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEC 61523-3 First edition 2004-09" do
    let(:original) { "IEC 61523-3 First edition 2004-09" }
    let(:pubid) { "IEC 61523.3 Edition 1.0 2004-09" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE 1076.4 IEC 61691-5 First edition 2004-10" do
    let(:original) { "IEEE 1076.4 IEC 61691-5 First edition 2004-10" }
    let(:pubid) { "IEEE 1076.4 (IEC 61691.5 Edition 1.0 2004-10)" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE Std 1076.1 IEC 61691-6 Edition 1.0 2009-12" do
    let(:original) { "IEEE Std 1076.1 IEC 61691-6 Edition 1.0 2009-12" }
    let(:pubid) { "IEEE Std 1076.1 (IEC 61691.6 Edition 1.0 2009-12)" }

    it_behaves_like "converts pubid to pubid"
  end
end
