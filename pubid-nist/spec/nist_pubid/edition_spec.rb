RSpec.describe Pubid::Nist::Edition do

  subject { Pubid::Nist::Identifier.parse(short_pubid).edition }

  context "when NBS FIPS 107-Mar1985" do
    let(:short_pubid) { "NBS FIPS 107-Mar1985" }

    it { expect(subject.to_s).to eq("198503") }
    it { expect(subject.year).to eq(1985) }
    it { expect(subject.month).to eq(3) }
  end

  context "when NIST SP(IPD) 800-53e5" do
    let(:short_pubid) { "NIST SP(IPD) 800-53e5" }

    it { expect(subject.to_s).to eq("5") }
  end

  context "parse NIST SP 304a-2017" do
    let(:short_pubid) { "NIST SP 304a-2017" }

    it { expect(subject.to_s).to eq("2017") }
    it { expect(subject.year).to eq(2017) }
  end

  context "NIST IR 8115" do
    let(:short_pubid) { "NIST IR 8115" }

    it { expect(subject).to be_nil }
  end

  context "NIST FIPS PUB 140-3" do
    let(:original_pubid) { "FIPS PUB 140-3" }
    let(:short_pubid) { "FIPS 140-3" }

    it { expect(subject).to be_nil }
  end

  context "NIST SP 260-162e2006" do
    let(:short_pubid) { "NIST SP 260-162e2006" }

    it { expect(subject.to_s).to eq("2006") }
    it { expect(subject.year).to eq(2006) }
  end

  context "NBS FIPS 11-1-Sep30/1977" do
    let(:short_pubid) { "NBS.FIPS.11-1-Sep30/1977" }

    it { expect(subject.to_s).to eq("19770930") }
    it { expect(subject.year).to eq(1977) }
    it { expect(subject.month).to eq(9) }
    it { expect(subject.day).to eq(30) }
  end

  context "NIST HB 105-1-1990" do
    let(:short_pubid) { "NIST HB 105-1-1990" }

    it { expect(subject).to be_nil }
  end

  context "NIST HB 44-1989" do
    let(:short_pubid) { "NIST HB 44-1989" }

    it { expect(subject.to_s).to eq("1989") }
    it { expect(subject.year).to eq(1989) }
    it { expect(subject.month).to be_nil }
    it { expect(subject.day).to be_nil }
    it { expect(subject.number).to be_nil }
  end

  context "NIST IR 5672-2018" do
    let(:short_pubid) { "NIST IR 5672-2018" }

    it { expect(subject.to_s).to eq("2018") }
    it { expect(subject.year).to eq(2018) }
    it { expect(subject.month).to be_nil }
    it { expect(subject.day).to be_nil }
    it { expect(subject.number).to be_nil }
  end

  context "NIST IR 85-3273-10" do
    let(:short_pubid) { "NIST IR 85-3273-10" }

    it { expect(subject).to be_nil }
  end

  context "NBS IR 80-2030" do
    let(:short_pubid) { "NBS IR 80-2030" }

    it { expect(subject).to be_nil }
  end

  context "NIST HB 135-2020" do
    let(:short_pubid) { "NIST HB 135-2020" }

    it { expect(subject.to_s).to eq("2020") }
    it { expect(subject.year).to eq(2020) }
    it { expect(subject.month).to be_nil }
    it { expect(subject.day).to be_nil }
  end
end
