module Pubid::Ieee
  RSpec.describe Identifier do
    subject { described_class.parse(original) }

    let(:original) { pubid }
    let(:full_pubid) { nil }

    def context_description(ex)
      ex.example_group.metadata[:parent_example_group][:description_args].first
    end

    shared_examples "converts pubid to pubid" do
      it "converts pubid to pubid" do |ex|
        # identifier = described_class.parse(
        #   context_description(ex)
        # )
        expect(subject.to_s).to eq(pubid)
      end

      it "converts to full pubid" do
        expect(subject.to_s(:full)).to eq(full_pubid) if full_pubid
      end
    end

    describe "parse specific identifiers" do
      context "IEEE No 142-1956" do
        let(:original) { "IEEE No 142-1956" }
        let(:pubid) { "IEEE Std 142-1956" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 802.15.22.3-2020" do
        let(:pubid) { "IEEE Std 802.15.22.3-2020" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1244-5.2000" do
        let(:original) { "IEEE Std 1244-5.2000" }
        let(:pubid) { "IEEE Std 1244-5-2000" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 581.1978" do
        let(:original) { "IEEE Std 581.1978" }
        let(:pubid) { "IEEE Std 581-1978" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ANSI C37.0781-1972" do
        let(:original) { "ANSI C37.0781-1972" }
        let(:pubid) { "ANSI C37.0781-1972" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1003.0-1995" do
        let(:pubid) { "IEEE Std 1003.0-1995" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ASA C37.1-1950" do
        let(:original) { "ASA C37.1-1950" }
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
        let(:pubid) { "IEEE Std 623-1976 (ANSI Y32.21-1976, NCTA 006.0975)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC 61671-2 Edition 1.0 2016-04" do
        let(:original) { "IEC 61671-2 Edition 1.0 2016-04" }
        let(:pubid) { "IEC 61671-2 Edition 1.0 2016-04" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC/IEEE 60076-16 Edition 2.0 2018-09" do
        let(:original) { "IEC/IEEE 60076-16 Edition 2.0 2018-09" }
        let(:pubid) { "IEC/IEEE 60076-16 Edition 2.0 2018-09" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1003.1, 2004 Edition" do
        let(:original) { "IEEE Std 1003.1, 2004 Edition" }
        let(:pubid) { "IEEE Std 1003.1 2004 Edition" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC 62525-Edition 1.0 - 2007" do
        let(:original) { "IEC 62525-Edition 1.0 - 2007" }
        let(:pubid) { "IEC 62525 Edition 1.0 2007" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE/ISO/IEC P90003, February 2018 (E)" do
        let(:original) { "IEEE/ISO/IEC P90003, February 2018 (E)" }
        let(:pubid) { "IEEE/IEC/ISO P90003, February 2018" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC 15288 First edition 2002-11-01" do
        let(:original) { "ISO/IEC 15288 First edition 2002-11-01" }
        let(:pubid) { "ISO/IEC 15288 Edition 1.0 2002-11-01" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC 61523-3 First edition 2004-09" do
        let(:original) { "IEC 61523-3 First edition 2004-09" }
        let(:pubid) { "IEC 61523-3 Edition 1.0 2004-09" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE 1076.4 IEC 61691-5 First edition 2004-10" do
        let(:original) { "IEEE 1076.4 IEC 61691-5 First edition 2004-10" }
        let(:pubid) { "IEEE Std 1076.4 (IEC 61691-5 Edition 1.0 2004-10)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ANSI PC63.10/D14, April 2020" do
        let(:original) { "ANSI PC63.10/D14, April 2020" }
        let(:pubid) { "ANSI Draft PC63.10/D14, April 2020" }
        let(:full_pubid) { "ANSI Draft PC63.10/D14, April 2020" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1076.1 IEC 61691-6 Edition 1.0 2009-12" do
        let(:original) { "IEEE Std 1076.1 IEC 61691-6 Edition 1.0 2009-12" }
        let(:pubid) { "IEEE Std 1076.1 (IEC 61691-6 Edition 1.0 2009-12)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std PC37.12.1/D2.0" do
        let(:pubid) { "IEEE Draft Std PC37.12.1/D2.0" }
        let(:full_pubid) { "IEEE Draft Std PC37.12.1/D2.0" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE 1250 /D11 May 2010" do
        let(:original) { "IEEE 1250 /D11 May 2010" }
        let(:pubid) { "IEEE 1250/D11, May 2010" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ANSI PC63.12/D12e, January 2015" do
        let(:original) { "ANSI PC63.12/D12e, January 2015" }
        let(:pubid) { "ANSI Draft PC63.12/D12e, January 2015" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P62.44/D15.3" do
        let(:original) { "IEEE P62.44/D15.3" }
        let(:pubid) { "IEEE Draft Std P62.44/D15.3" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE C57.139/D14June 2010" do
        let(:pubid) { "IEEE Draft Std C57.139/D14, June 2010" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P11073-10101/D3r7, September 2018" do
        let(:original) { "IEEE P11073-10101/D3.7, September 2018" }
        let(:pubid) { "IEEE P11073-10101/D3.7, September 2018" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P11073-10420/D4D5, March 2020" do
        let(:original) { "IEEE P11073-10420/D4D5, March 2020" }
        let(:pubid) { "IEEE P11073-10420/D4D5, March 2020" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P1293/D29a1, August 2018" do
        let(:pubid) { "IEEE P1293/D29a1, August 2018" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P1609.2.1/D12D14, June 2020" do
        let(:pubid) { "IEEE Draft Std P1609.2.1/D12D14, June 2020" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P1653.5/D7d1 November, 2019" do
        let(:original) { "IEEE P1653.5/D7.1, November 2019" }
        let(:pubid) { "IEEE Draft Std P1653.5/D7.1, November 2019" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P1017/D062012" do
        let(:pubid) { "IEEE P1017/D062012, June 2012" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std PC37.20.1a/D11" do
        let(:pubid) { "IEEE Draft Std PC37.20.1a/D11" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std PC37.66/D12, Apr 2005" do
        let(:pubid) { "IEEE Draft Std PC37.66/D12, April 2005" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Unapproved Draft Std 11073-10471/D02, Feb 2008" do
        let(:original) { "IEEE Unapproved Draft Std 11073-10471/D02, Feb 2008" }
        let(:pubid) { "IEEE Draft Std 11073-10471/D02, February 2008" }
        let(:full_pubid) { "IEEE Unapproved Draft Std 11073-10471/D02, February 2008" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Active Unapproved Draft Std PC37.59/D11, Jul 2007" do
        let(:original) { "IEEE Active Unapproved Draft Std PC37.59/D11, Jul 2007" }
        let(:pubid) { "IEEE Draft Std PC37.59/D11, July 2007" }
        let(:full_pubid) { "IEEE Active Unapproved Draft Std PC37.59/D11, July 2007" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Approved Draft Std P1076.1/D3.3, Feb 6, 2007" do
        let(:original) { "IEEE Approved Draft Std P1076.1/D3.3, Feb 6, 2007" }
        let(:pubid) { "IEEE Draft Std P1076.1/D3.3, February 6, 2007" }
        let(:full_pubid) { "IEEE Approved Draft Std P1076.1/D3.3, February 6, 2007" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Unapproved Draft Std P11073-20601_D20 May 2008" do
        let(:original) { "IEEE Unapproved Draft Std P11073-20601_D20 May 2008" }
        let(:pubid) { "IEEE Draft Std P11073-20601/D20, May 2008" }
        let(:full_pubid) { "IEEE Unapproved Draft Std P11073-20601/D20, May 2008" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Unapproved Draft Std P1616a/D4, Jan 2010" do
        let(:original) { "IEEE Unapproved Draft Std P1616a/D4, Jan 2010" }
        let(:pubid) { "IEEE Draft Std P1616a/D4, January 2010" }
        let(:full_pubid) { "IEEE Unapproved Draft Std P1616a/D4, January 2010" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Unapproved Draft Std P1619/D17, Jul 07" do
        let(:original) { "IEEE Unapproved Draft Std P1619/D17, Jul 07" }
        let(:pubid) { "IEEE Draft Std P1619/D17, July 2007" }
        let(:full_pubid) { "IEEE Unapproved Draft Std P1619/D17, July 2007" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Unapproved Draft Std PC37.101/D13, Jun 2006" do
        let(:original) { "IEEE Unapproved Draft Std PC37.101/D13, Jun 2006" }
        let(:pubid) { "IEEE Draft Std PC37.101/D13, June 2006" }
        let(:full_pubid) { "IEEE Unapproved Draft Std PC37.101/D13, June 2006" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Unapproved Draft Std PC62.11a/D9E, Sept 2007" do
        let(:original) { "IEEE Unapproved Draft Std PC62.11a/D9E, Sept 2007" }
        let(:pubid) { "IEEE Draft Std PC62.11a/D9E, September 2007" }
        let(:full_pubid) { "IEEE Unapproved Draft Std PC62.11a/D9E, September 2007" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Unapproved Draft Std 802.20/D4.1m, April 2008" do
        let(:original) { "IEEE Unapproved Draft Std 802.20/D4.1m, April 2008" }
        let(:pubid) { "IEEE Draft Std 802.20/D4.1m, April 2008" }
        let(:full_pubid) { "IEEE Unapproved Draft Std 802.20/D4.1m, April 2008" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Unapproved Draft Std P1003.1_D4 , Jan 2008" do
        let(:original) { "IEEE Unapproved Draft Std P1003.1_D4 , Jan 2008" }
        let(:pubid) { "IEEE Draft Std P1003.1/D4, January 2008" }
        let(:full_pubid) { "IEEE Unapproved Draft Std P1003.1/D4, January 2008" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Unapproved Draft Std P11073-20601a/D13, Jan 2010" do
        let(:original) { "IEEE Unapproved Draft Std P11073-20601a/D13, Jan 2010" }
        let(:full_pubid) { "IEEE Unapproved Draft Std P11073-20601a/D13, January 2010" }
        let(:pubid) { "IEEE Draft Std P11073-20601a/D13, January 2010" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1491-2012 (Revision of IEEE Std 1491-2005)" do
        let(:pubid) { "IEEE Std 1491-2012 (Revision of IEEE Std 1491-2005)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ANSI C63.10-2013 - Redline" do
        let(:pubid) { "ANSI C63.10-2013 - Redline" }

        it_behaves_like "converts pubid to pubid"
      end

      context "PC57.158/D6A, August 2016" do
        let(:original) { "PC57.158/D6A, August 2016" }
        let(:pubid) { "IEEE Draft Std PC57.158/D6A, August 2016" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEP62.42.1/D3, October 2014" do
        let(:original) { "IEEP62.42.1/D3, October 2014" }
        let(:pubid) { "IEEE Draft Std P62.42.1/D3, October 2014" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE No. 264-1968" do
        let(:original) { "IEEE No. 264-1968" }
        let(:pubid) { "IEEE Std 264-1968" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1666 IEC61691-7 Edition 1.0 2009-12" do
        let(:original) { "IEEE Std 1666 IEC61691-7 Edition 1.0 2009-12" }
        let(:pubid) { "IEEE Std 1666 (IEC 61691-7 Edition 1.0 2009-12)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE No 323, April 1971" do
        let(:original) { "IEEE No 323, April 1971" }
        let(:pubid) { "IEEE Std 323, April 1971" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P15026-2, April 2011" do
        let(:original) { "IEEE P15026-2, April 2011" }
        let(:pubid) { "IEEE P15026-2, April 2011" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P90003-2014, April 2015" do
        let(:original) { "IEEE P90003-2014, April 2015" }
        let(:pubid) { "IEEE P90003-2014, April 2015" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE/IEC P60076-57-1202, July 2014" do
        let(:original) { "IEEE/IEC P60076-57-1202, July 2014" }
        let(:pubid) { "IEEE/IEC P60076-57-1202, July 2014" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P802.11ajD8.0, August 2017" do
        let(:original) { "IEEE P802.11ajD8.0, August 2017" }
        let(:pubid) { "IEEE Draft Std P802.11aj/D8.0, August 2017" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE P26513_D2, January 2017" do
        let(:original) { "ISO/IEC/IEEE P26513_D2, January 2017" }
        let(:pubid) { "ISO/IEC/IEEE P26513/D2, January 2017" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P2410-D4, July 2019" do
        let(:original) { "IEEE P2410-D4, July 2019" }
        let(:pubid) { "IEEE P2410/D4, July 2019" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ANSI C63.4a-2017 (Amendment to ANSI C63.4-2014)" do
        let(:original) { "ANSI C63.4a-2017 (Amendment to ANSI C63.4-2014)" }
        let(:pubid) { "ANSI C63.4a-2017 (Amendment to ANSI C63.4-2014)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P802.3bg/D2.1, September 2010 (Amendment of IEEE Std 802.3-2008)" do
        let(:original) { "IEEE P802.3bg/D2.1, September 2010 (Amendment of IEEE Std 802.3-2008)" }
        let(:pubid) { "IEEE Draft Std P802.3bg/D2.1, September 2010 (Amendment to IEEE Std 802.3-2008)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 802.15.3f-2017 (Amendment to IEEE Std 802.15.3-2016 as "\
              "amended by IEEE Std 802.15.3d-2017, and IEEE Std 802.15.3e-2017)" do
        let(:pubid) do
          "IEEE Std 802.15.3f-2017 (Amendment to IEEE Std 802.15.3-2016 as amended by IEEE Std 802.15.3d-2017, and IEEE Std 802.15.3e-2017)"
        end

        it_behaves_like "converts pubid to pubid"

      end

      context "IEEE Std 802.15.3d-2017 (Amendment to IEEE Std 802.15.3-2016 as amended by IEEE Std 802.15.3e-2017)" do
        let(:pubid) do
          "IEEE Std 802.15.3d-2017 (Amendment to IEEE Std 802.15.3-2016 as amended by IEEE Std 802.15.3e-2017)"
        end

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 802.15.3f-2017 (Amendment to IEEE Std 802.15.3-2016 as amended by IEEE Std 802.15.3d-2017, and IEEE Std 802.15.3e-2017)" do
        let(:pubid) do
          "IEEE Std 802.15.3f-2017 (Amendment to IEEE Std 802.15.3-2016 as amended by IEEE Std 802.15.3d-2017, and IEEE Std 802.15.3e-2017)"
        end

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 802.11af-2013 (Amendment to IEEE Std 802.11-2012, as amended by IEEE Std 802.11ae-2012,"\
              " IEEE Std 802.11aa-2012, IEEE Std 802.11ad-2012, and IEEE Std 802.11ac-2013)" do
        let(:original) do
          "IEEE Std 802.11af-2013 (Amendment to IEEE Std 802.11-2012, as amended by IEEE Std 802.11ae-2012,"\
            " IEEE Std 802.11aa-2012, IEEE Std 802.11ad-2012, and IEEE Std 802.11ac-2013)"
        end

        let(:pubid) do
          "IEEE Std 802.11af-2013 (Amendment to IEEE Std 802.11-2012 as amended by IEEE Std 802.11ae-2012,"\
            " IEEE Std 802.11aa-2012, IEEE Std 802.11ad-2012, and IEEE Std 802.11ac-2013)"
        end

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1003.1-2001/Cor 2-2004" do
        let(:pubid) { "IEEE Std 1003.1-2001/Cor 2-2004" }

        it_behaves_like "converts pubid to pubid"
      end

      context "P1900.6-2011/Cor1/D3, August 2015" do
        let(:original) { "P1900.6-2011/Cor1/D3, August 2015" }
        let(:pubid) { "IEEE Draft Std P1900.6-2011/Cor 1/D3, August 2015" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P1722-2016-Cor1/D0, June 2016" do
        let(:original) { "IEEE P1722-2016-Cor1/D0, June 2016" }
        let(:pubid) { "IEEE Draft Std P1722-2016/Cor 1/D0, June 2016" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 268-1979 (Supersedes IEEE Std 268-1976)" do
        let(:pubid) { "IEEE Std 268-1979 (Supersedes IEEE Std 268-1976)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 16-1955 (Supersedes C48-1931 and AIEE 16A 1951)" do
        let(:original) { "IEEE Std 16-1955 (Supersedes C48-1931 and AIEE 16A-1951)" }
        let(:pubid) { "IEEE Std 16-1955 (Supersedes IEEE Std C48-1931 and AIEE 16A-1951)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 588-1976 (ANSI C37.86-1975) (Revision of IEEE Std 288-1969 and IEEE Std 328-1971)" do
        let(:pubid) { "IEEE Std 588-1976 (ANSI C37.86-1975) (Revision of IEEE Std 288-1969 and IEEE Std 328-1971)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 268-1976 (Supersedes ASTM E380-1974 IEEE Std 268-1973 IEEE Std 322-1971)" do
        let(:original) { "IEEE Std 268-1976 (Supersedes ASTM E380-1974 IEEE Std 268-1973 IEEE Std 322-1971)" }
        let(:pubid) { "IEEE Std 268-1976 (Supersedes ASTM E380-1974, IEEE Std 268-1973, IEEE Std 322-1971)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std C57.12.10-2013 (Corrigendum to IEEE Std C57.12.10-2010)" do
        let(:original) { "IEEE Std C57.12.10-2013 (Corrigendum to IEEE Std C57.12.10-2010)" }
        let(:pubid) { "IEEE Std C57.12.10-2010/Cor 1-2013" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ASA C37.1-1937 (Reaffirmed 1945)" do
        let(:pubid) { "ASA C37.1-1937 (Reaffirmed 1945)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 792-1995 (Reaffirmation of IEEE Std 792-1988)" do
        let(:original) { "IEEE Std 792-1995 (Reaffirmation of IEEE Std 792-1988)" }
        let(:pubid) { "IEEE Std 792-1988 (Reaffirmed 1995)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ANSI C50.32-1976 and IEEE Std 117-1974 (Reaffirmed 1984) (Revision of IEEE Std 117-1956)" do
        let(:original) { "ANSI C50.32-1976 and IEEE Std 117-1974 (Reaffirmed 1984) (Revision of IEEE Std 117-1956)" }
        let(:pubid) { "ANSI C50.32-1976 (IEEE Std 117-1974) (Reaffirmed 1984) (Revision of IEEE Std 117-1956)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE No 29-1941 / ASA C77.1-1943 (Reaffirmed 1971)" do
        let(:original) { "IEEE No 29-1941 / ASA C77.1-1943 (Reaffirmed 1971)" }
        let(:pubid) { "IEEE Std 29-1941 (ASA C77.1-1943) (Reaffirmed 1971)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ANSI/IEEE Std 802.3p and Std 802.3q" do
        let(:original) { "ANSI/IEEE Std 802.3p and Std 802.3q" }
        let(:pubid) { "ANSI/IEEE 802.3p (IEEE Std 802.3q)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1735-2014 (Incorporates IEEE Std 1735-2014/Cor 1-2015)" do
        let(:pubid) { "IEEE Std 1735-2014 (Incorporates IEEE Std 1735-2014/Cor 1-2015)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 525-2007 (Revision of IEEE Std 525-1992/Incorporates IEEE Std 525-2007/Cor1:2008) - Redline" do
        let(:original) { "IEEE Std 525-2007 (Revision of IEEE Std 525-1992/Incorporates IEEE Std 525-2007/Cor1-2008) - Redline" }
        let(:pubid) { "IEEE Std 525-2007 (Incorporates IEEE Std 525-2007/Cor 1-2008) (Revision of IEEE Std 525-1992) - Redline" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1003.1, 2013 Edition (incorporates IEEE Std 1003.1-2008, and IEEE Std 1003.1-2008/Cor 1-2013)" do
        let(:original) { "IEEE Std 1003.1, 2013 Edition (incorporates IEEE Std 1003.1-2008, and IEEE Std 1003.1-2008/Cor 1-2013)" }
        let(:pubid) { "IEEE Std 1003.1 2013 Edition (Incorporates IEEE Std 1003.1-2008, and IEEE Std 1003.1-2008/Cor 1-2013)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 1012-2016 (Revision of IEEE Std 1012-2012/ Incorporates IEEE Std 1012-2016/Cor1-2017)" do
        let(:original) { "IEEE Std 1012-2016 (Revision of IEEE Std 1012-2012/ Incorporates IEEE Std 1012-2016/Cor1-2017)" }
        let(:pubid) { "IEEE Std 1012-2016 (Incorporates IEEE Std 1012-2016/Cor 1-2017) (Revision of IEEE Std 1012-2012)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "P802-REV/D2.0 (Revision of IEEE Std 802-2001, incorporating IEEE Std 802a-2003, and IEEE Std 802b-2004)" do
        let(:original) { "P802-REV/D2.0 (Revision of IEEE Std 802-2001, incorporating IEEE Std 802a-2003, and IEEE Std 802b-2004)" }
        let(:pubid) { "IEEE Draft Std P802-REV/D2.0 (Incorporates IEEE Std 802a-2003, and IEEE Std 802b-2004) (Revision of IEEE Std 802-2001)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ANSI/IEEE C37.010b-1985 (Supplement to ANSI/IEEE C37.010-1979)" do
        let(:original) { "ANSI/IEEE C37.010b-1985 (Supplement to ANSI/IEEE C37.010-1979)" }
        let(:pubid) { "ANSI/IEEE C37.010b-1985 (Supplement to ANSI/IEEE C37.010-1979)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "NACE/IEEE P1835_D2, July 2014" do
        let(:original) { "NACE/IEEE P1835_D2, July 2014" }
        let(:pubid) { "NACE/IEEE Draft P1835/D2, July 2014" }

        it_behaves_like "converts pubid to pubid"
      end

      context "NACE SP0XXX-2011/IEEE P1835_D1a, 2011" do
        let(:original) { "NACE SP0XXX-2011/IEEE P1835_D1a, 2011" }
        let(:pubid) { "NACE SP0XXX-2011 (IEEE Draft Std P1835/D1a 2011)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "NACE SP0215-2015/IEEE Std 1839-2014" do
        let(:original) { "NACE SP0215-2015/IEEE Std 1839-2014" }
        let(:pubid) { "NACE SP0215-2015 (IEEE Std 1839-2014)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC/IEEE 60214-2:2019" do
        let(:pubid) { "IEC/IEEE 60214-2:2019" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC/IEEE 62271-37-082:2012(E) (Revision of IEEE Std C37.082-1982) - Redline" do
        let(:pubid) { "IEC/IEEE 62271-37-082:2012(E) (Revision of IEEE Std C37.082-1982) - Redline" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC 15288:2008(E) IEEE Std 15288-2008 (Revision of IEEE Std 15288-2004)" do
        let(:original) { "ISO/IEC 15288:2008(E) IEEE Std 15288-2008 (Revision of IEEE Std 15288-2004)" }
        let(:pubid) { "ISO/IEC 15288:2008(E) (IEEE 15288-2008) (Revision of IEEE Std 15288-2004)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE/ISO/IEC 8802-3:2021/Amd8-2021" do
        let(:original) { "IEEE/ISO/IEC 8802-3:2021/Amd8-2021" }
        let(:pubid) { "IEEE/IEC/ISO 8802-3:2021/Amd 8:2021" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std C37.111-2013 (IEC 60255-24 Edition 2.0 2013-04)" do
        let(:pubid) { "IEEE Std C37.111-2013 (IEC 60255-24 Edition 2.0 2013-04)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC 61691-6 Edition 1.0 2009-12" do
        let(:pubid) { "IEC 61691-6 Edition 1.0 2009-12" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 802.3cp-2021 (Amendment to IEEE 802.3-2018)" do
        let(:pubid) { "IEEE Std 802.3cp-2021 (Amendment to IEEE Std 802.3-2018)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 802.1s-2002 (Amendment to IEEE Std 802.1Q, 1998 Edition)" do
        let(:original) { "IEEE Std 802.1s-2002 (Amendment to IEEE Std 802.1Q, 1998 Edition)" }
        let(:pubid) { "IEEE Std 802.1s-2002 (Amendment to IEEE Std 802.1Q 1998 Edition)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC 61671:2012(E) (IEEE Std 1671-2010)" do
        let(:pubid) { "IEC 61671:2012(E) (IEEE Std 1671-2010)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC/IEEE 62582-1:2011 Edition 1.0 2011-08" do
        let(:pubid) { "IEC/IEEE 62582-1:2011 Edition 1.0 2011-08" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC 62529:2012(E) (IEEE Std 1641-2010" do
        let(:original) { "IEC 62529:2012(E) (IEEE Std 1641-2010" }
        let(:pubid) { "IEC 62529:2012(E) (IEEE Std 1641-2010)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC 62526:2007(E) IEEE 1450.1-2005(E)" do
        let(:original) { "IEC 62526:2007(E) IEEE 1450.1-2005(E)" }
        let(:pubid) { "IEC 62526:2007(E) (IEEE 1450.1-2005)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 11073-10101-2019 (Revision of ISO/IEEE 11073-10101:2004)" do
        let(:pubid) { "IEEE Std 11073-10101-2019 (Revision of ISO/IEEE 11073-10101:2004)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 802.3-2012 (Revision to IEEE Std 802.3-2008)" do
        let(:pubid) { "IEEE Std 802.3-2012 (Revision of IEEE Std 802.3-2008)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE STD 525-2007 (Revision of IEEE Std 525-1992/Incorporates IEEE Std 525-2007/Cor1:2008)" do
        let(:original) { "IEEE STD 525-2007 (Revision of IEEE Std 525-1992/Incorporates IEEE Std 525-2007/Cor1:2008)" }
        let(:pubid) { "IEEE Std 525-2007 (Incorporates IEEE Std 525-2007/Cor 1-2008) (Revision of IEEE Std 525-1992)" }

        it_behaves_like "converts pubid to pubid"
      end

      # parses lack of space between "Std" and standard number
      context "IEEE Std 1800-2009 (Revision of IEEE Std1800-2005) - Redline" do
        let(:pubid) { "IEEE Std 1800-2009 (Revision of IEEE Std 1800-2005) - Redline" }

        it_behaves_like "converts pubid to pubid"
      end


      context "ISO/IEC/IEEE CD P23026:2013" do
        let(:pubid) { "ISO/IEC/IEEE CD P23026:2013" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P1642 D8, November 2011" do
        let(:original) { "IEEE P1642 D8, November 2011" }
        let(:pubid) { "IEEE P1642/D8, November 2011" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 24748-3:2012" do
        let(:original) { "IEEE Std 24748-3:2012" }
        let(:pubid) { "IEEE 24748-3:2012" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC/IEEE P62271-37-013:2015 D13.4" do
        let(:original) { "IEC/IEEE P62271-37-013:2015 D13.4" }
        let(:pubid) { "IEC/IEEE P62271-37-013:2015/D13.4" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE P24765/D3:2017" do
        let(:original) { "ISO/IEC/IEEE P24765/D3:2017" }
        let(:pubid) { "ISO/IEC/IEEE P24765:2017/D3" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC FDIS P15289, April 2014" do
        let(:original) { "ISO/IEC FDIS P15289, April 2014(E)" }
        let(:pubid) { "ISO/IEC FDIS P15289, April 2014" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE P26514/FDIS, August 2021" do
        let(:original) { "ISO/IEC/IEEE P26514/FDIS, August 2021" }
        let(:pubid) { "ISO/IEC/IEEE FDIS P26514, August 2021" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE P15288-DIS-1403" do
        let(:original) { "ISO/IEC/IEEE P15288-DIS-1403" }
        let(:pubid) { "ISO/IEC/IEEE DIS P15288-1403" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE/ISO/IEC P29119-2-DIS, December 2011" do
        let(:original) { "IEEE/ISO/IEC P29119-2-DIS, December 2011" }
        let(:pubid) { "IEEE/IEC/ISO DIS P29119-2, December 2011" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEC/IEEE P60214-2, FDIS 2018" do
        let(:original) { "IEC/IEEE P60214-2, FDIS 2018" }
        let(:pubid) { "IEC/IEEE FDIS P60214-2-2018(E)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE 8802-A:2015(E)" do
        let(:pubid) { "ISO/IEC/IEEE 8802-A:2015(E)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC DIS P26511.2, May 2017" do
        let(:original) { "ISO/IEC DIS P26511.2, May 2017" }
        let(:pubid) { "ISO/IEC DIS P26511-2, May 2017" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE CD P26513/D1, August 2015" do
        let(:pubid) { "ISO/IEC/IEEE CD P26513/D1, August 2015" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE 1672-2006/Cor 1-2008 (Corrigendum to IEEE Std 1672-2006)" do
        let(:original) { "IEEE 1672-2006/Cor 1-2008 (Corrigendum to IEEE Std 1672-2006)" }
        let(:pubid) { "IEEE 1672-2006/Cor 1:2008" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE 8802-22.2:2015/Amd.2:2017(E)" do
        let(:original) { "ISO/IEC/IEEE 8802-22.2:2015/Amd.2:2017(E)" }
        let(:pubid) { "ISO/IEC/IEEE 8802-22:2015/Amd 2:2017(E)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE P16085/CD, February 2018" do
        let(:original) { "IEEE P16085/CD, February 2018" }
        let(:pubid) { "IEEE/CD P16085, February 2018" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE/ISO/IEC 8802-1Q-2020/Amd31-2021" do
        let(:original) { "IEEE/ISO/IEC 8802-1Q-2020/Amd31-2021" }
        let(:pubid) { "IEEE/IEC/ISO 8802-1Q-2020/Amd 31:2021" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE 8802-3:2017/Cor.1:2018(E)" do
        let(:original) { "ISO/IEC/IEEE 8802-3:2017/Cor.1:2018(E)" }
        let(:pubid) { "ISO/IEC/IEEE 8802-3:2017/Cor 1:2018(E)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 8802-2-1994/Amd3" do
        let(:pubid) { "IEEE Std 8802-2-1994/Amd3" }

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE 278-1967" do
        let(:original) { "IEEE 278-1967" }
        let(:pubid) { "IEEE Std 278-1967" }

        it "parses last part as a year" do
          expect(subject.year).to eq("-1967")
        end

        it_behaves_like "converts pubid to pubid"
      end

      context "IEEE Std 802.3ba-2010 (Amendment to IEEE Standard 802.3-2008)" do
        let(:original) { "IEEE Std 802.3ba-2010 (Amendment to IEEE Standard 802.3-2008)" }
        let(:pubid) { "IEEE Std 802.3ba-2010 (Amendment to IEEE Std 802.3-2008)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE P15026-4/DIS, February 2020" do
        let(:original) { "ISO/IEC/IEEE P15026-4/DIS, February 2020" }
        let(:pubid) { "ISO/IEC/IEEE DIS P15026-4, February 2020" }

        it_behaves_like "converts pubid to pubid"

        it { expect(subject.iso_identifier.typed_stage).to eq(:dis) }
      end

      context "ISO/IEC/IEEE P29119-1/CD, June 2020" do
        let(:original) { "ISO/IEC/IEEE P29119-1/CD, June 2020" }
        let(:pubid) { "ISO/IEC/IEEE CD P29119-1, June 2020" }

        it_behaves_like "converts pubid to pubid"
      end
    end

    describe "parse identifiers from examples files" do
      shared_examples "parse identifiers from file" do
        it "parse identifiers from file" do
          f = open("spec/fixtures/#{examples_file}")
          f.readlines.each do |pub_id|
            next if pub_id.match?("^#")

            pub_id = pub_id.split("#").first.strip.chomp
            expect do
              described_class.parse(pub_id)
            rescue Exception => failure
              raise Pubid::Ieee::Errors::ParseError,
                    "couldn't parse #{pub_id}\n#{failure.message}"
            end.not_to raise_error
          end
        end
      end

      context "parses identifiers from pubid-parsed.txt" do
        let(:examples_file) { "pubid-parsed.txt" }

        it_behaves_like "parse identifiers from file"
      end
    end
  end
end
