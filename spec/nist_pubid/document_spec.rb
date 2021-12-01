# frozen_string_literal: true

# PubID examples (TODO: add to tests)
# NIST SP 800-40r3
# NIST SP 800-45ver2
# NIST SP 800-53r4/Upd 3:2015
# NIST SP IPD 800-53r5
# NIST SP 800-53Ar4/Upd 1:2014
# NIST SP 800-60v1r1
# NIST SP 800-57pt1r4
# NIST SP 800-73-4/Upd 1:2016
# NIST SP 2PD 800-188
# NIST SP 2PD 1800-13B
# NIST SP PreD 1800-19B
# NIST IR 8011v3
# NIST IR 8204/Upd 1:2019
# NIST IR 8115(spa)
# NIST HB 130e2019
# NIST SP 1041r1/Upd 1:2012
# NIST NCSTAR 1-1Cv1
# NIST SP 800-38A has an Addendum

RSpec.describe NistPubid::Document do
  let(:short_pubid) { 'NIST SP 800-53r5' }
  let(:long_pubid) { 'National Institute of Standards and Technology Special Publication 800-53, Revision 5' }
  let(:abbrev_pubid) { 'Natl. Inst. Stand. Technol. Spec. Publ. 800-53, Revision 5' }
  let(:mr_pubid) { 'NIST.SP.800-53r5' }

  it 'parses NIST PubID using parameters' do
    expect(described_class.new(publisher: :nist, series: 'SP', docnumber: '800-53', revision: 5).to_s(:mr))
      .to eq(mr_pubid)
  end

  it 'parses MR NIST PubID' do
    expect(described_class.parse(mr_pubid).to_s(:long)).to eq(long_pubid)
  end

  describe 'generate NIST PubID string outputs' do
    subject { described_class.parse(short_pubid) }

    it 'converts into long Full PubID' do
      expect(subject.to_s(:long)).to eq(long_pubid)
    end

    it 'converts into Abbreviated PubID' do
      expect(subject.to_s(:abbrev)).to eq(abbrev_pubid)
    end

    it 'converts into Short PubID' do
      expect(subject.to_s(:short)).to eq(short_pubid)
    end

    it 'converts into Machine-readable PubID' do
      expect(subject.to_s(:mr)).to eq(mr_pubid)
    end
  end

  describe 'access to PubID object' do
    it 'returns revision' do
      expect(described_class.parse(short_pubid).revision).to eq('5')
    end

    it 'can update revistion' do
      pub_id = described_class.parse(short_pubid)
      pub_id.revision = 6
      expect(pub_id.to_s(:mr)).to eq('NIST.SP.800-53r6')
    end
  end
end
