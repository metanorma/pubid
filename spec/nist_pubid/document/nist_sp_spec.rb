RSpec.describe NistPubid::Document do
  subject { described_class.parse(original_pubid) }

  let(:mr_pubid) { short_pubid.gsub(" ", ".") }
  let(:original_pubid) { short_pubid }
  let(:long_pubid) { nil }
  let(:abbrev_pubid) { nil }

  context "NIST SP 1011-I-2.0" do
    let(:original_pubid) { "NIST SP 1011-I-2.0" }
    let(:short_pubid) { "NIST SP 1011v1ver2.0" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 1011-II-1.0" do
    let(:original_pubid) { "NIST SP 1011-II-1.0" }
    let(:short_pubid) { "NIST SP 1011v2ver1.0" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-73-3p1" do
    let(:original_pubid) { "NIST SP 800-73-3p1" }
    let(:short_pubid) { "NIST SP 800-73pt1r3" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 500-268v1.1" do
    let(:original_pubid) { "NIST SP 500-268v1.1" }
    let(:short_pubid) { "NIST SP 500-268ver1.1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 500-281-v1.0" do
    let(:original_pubid) { "NIST SP 500-281-v1.0" }
    let(:short_pubid) { "NIST SP 500-281ver1.0" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-90r" do
    let(:original_pubid) { "NIST SP 800-90r" }
    let(:short_pubid) { "NIST SP 800-90r1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-57pt1r4" do
    let(:short_pubid) { "NIST SP 800-57pt1r4" }
    let(:long_pubid) do
      "National Institute of Standards and Technology Special Publication"\
          " 800-57 Part 1, Revision 4"
    end
    let(:abbrev_pubid) do
      "Natl. Inst. Stand. Technol. Spec. Publ. 800-57 Pt. 1, Rev. 4"
    end

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-53r4/Upd3-2015" do
    let(:original_pubid) { "NIST SP 800-53r4/Upd3-2015" }
    let(:short_pubid) { "NIST SP 800-53r4/Upd3-2015" }
    let(:long_pubid) do
      "National Institute of Standards and Technology Special Publication "\
          "800-53, Revision 4 Update 3-2015"
    end
    let(:abbrev_pubid) do
      "Natl. Inst. Stand. Technol. Spec. Publ. 800-53, Rev. 4 Upd. 3-2015"
    end
    let(:mr_pubid) { "NIST.SP.800-53r4.u3-2015" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-38a-add" do
    let(:original_pubid) { "NIST SP 800-38a-add" }
    let(:short_pubid) { "NIST SP 800-38A Add." }
    let(:long_pubid) do
      "Addendum to National Institute of Standards and Technology Special"\
          " Publication 800-38A"
    end
    let(:abbrev_pubid) do
      "Add. to Natl. Inst. Stand. Technol. Spec. Publ. 800-38A"
    end
    let(:mr_pubid) { "NIST.SP.800-38A.add-1" }

    it_behaves_like "converts pubid to different formats"

    it "converts MR PubID into long Full PubID" do
      expect(described_class.parse(mr_pubid).to_s(:long)).to eq(long_pubid)
    end
  end

  context "NIST SP(IPD) 800-53r5" do
    let(:short_pubid) { "NIST SP(IPD) 800-53r5" }
    let(:long_pubid) do
      "National Institute of Standards and Technology Special Publication "\
          "Initial Public Draft 800-53, Revision 5"
    end
    let(:abbrev_pubid) do
      "Natl. Inst. Stand. Technol. Spec. Publ. Initial Public Draft 800-53,"\
          " Rev. 5"
    end
    let(:mr_pubid) { "NIST.SP.IPD.800-53r5" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP(IPD) 800-53e5" do
    let(:short_pubid) { "NIST SP(IPD) 800-53e5" }
    let(:long_pubid) do
      "National Institute of Standards and Technology Special Publication "\
          "Initial Public Draft 800-53 Edition 5"
    end
    let(:abbrev_pubid) do
      "Natl. Inst. Stand. Technol. Spec. Publ. Initial Public Draft 800-53 "\
          "Ed. 5"
    end
    let(:mr_pubid) { "NIST.SP.IPD.800-53e5" }

    it_behaves_like "converts pubid to different formats"
  end

  context "parse NIST SP 1190GB-1" do
    let(:original_pubid) { "NIST SP 1190GBe1" }
    let(:short_pubid) { "NIST SP 1190GBe1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "parse NIST SP 304a-2017" do
    let(:original_pubid) { "NIST SP 304a-2017" }
    let(:short_pubid) { "NIST SP 304Ae2017" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 330-2019" do
    let(:original_pubid) { "NIST SP 330-2019" }
    let(:short_pubid) { "NIST SP 330e2019" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 777-1990" do
    let(:original_pubid) { "NIST SP 777-1990" }
    let(:short_pubid) { "NIST SP 777e1990" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 782-1995-96" do
    let(:original_pubid) { "NIST SP 782-1995-96" }
    let(:short_pubid) { "NIST SP 782e1995" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 250-1039" do
    let(:original_pubid) { "NIST SP 250-1039" }
    let(:short_pubid) { "NIST SP 250-1039" }

    it_behaves_like "converts pubid to different formats"
  end

  context "parse NIST SP 500-202p2" do
    let(:original_pubid) { "NIST SP 500-202p2" }
    let(:short_pubid) { "NIST SP 500-202pt2" }

    it_behaves_like "converts pubid to different formats"
  end

  context "parse NIST SP 800-22r1a" do
    let(:original_pubid) { "NIST SP 800-22r1a" }
    let(:short_pubid) { "NIST SP 800-22r1a" }

    it_behaves_like "converts pubid to different formats"
  end

  context "parse NIST SP 800-60ver2v2" do
    let(:original_pubid) { "NIST SP 800-60ver2v2" }
    let(:short_pubid) { "NIST SP 800-60v2ver2" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-63v1.0.2" do
    let(:original_pubid) { "NIST SP 800-63v1.0.2" }
    let(:short_pubid) { "NIST SP 800-63ver1.0.2" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 305supp26" do
    let(:original_pubid) { "NIST SP 305supp26" }
    let(:short_pubid) { "NIST SP 305sup26" }
    let(:long_pubid) do
      "National Institute of Standards and Technology Special Publication "\
          "305 Supplement 26"
    end
    let(:abbrev_pubid) do
      "Natl. Inst. Stand. Technol. Spec. Publ. 305 Suppl. 26"
    end

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 955 Suppl." do
    let(:original_pubid) { "NIST SP 955 Suppl." }
    let(:short_pubid) { "NIST SP 955sup" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 260-162 2006ed." do
    let(:original_pubid) { "NIST SP 260-162 2006ed." }
    let(:short_pubid) { "NIST SP 260-162e2006" }
    let(:mr_pubid) { "NIST.SP.260-162e2006" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 500-300-upd" do
    let(:original_pubid) { "NIST SP 500-300-upd" }
    let(:short_pubid) { "NIST SP 500-300/Upd1-202105" }
    let(:mr_pubid) { "NIST.SP.500-300.u1-202105" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-90b" do
    let(:original_pubid) { "NIST SP 800-90b" }
    let(:short_pubid) { "NIST SP 800-90B" }

    it_behaves_like "converts pubid to different formats"
  end

  # 800-85A-4 but 800-85Apt1r4
  context "NIST SP 800-85A-4" do
    let(:original_pubid) { "NIST SP 800-85A-4" }
    let(:short_pubid) { "NIST SP 800-85Ar4" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-56Ar2" do
    let(:short_pubid) { "NIST SP 800-56Ar2" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-56Cr1" do
    let(:short_pubid) { "NIST SP 800-56Cr1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-56ar" do
    let(:original_pubid) { "NIST SP 800-56ar" }
    let(:short_pubid) { "NIST SP 800-56Ar1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 1262es" do
    let(:original_pubid) { "NIST SP 1262es" }
    let(:short_pubid) { "NIST SP 1262(spa)" }
    let(:mr_pubid) { "NIST.SP.1262.spa" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-38e" do
    let(:original_pubid) { "NIST SP 800-38e" }
    let(:short_pubid) { "NIST SP 800-38E" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 1075-NCNR" do
    let(:short_pubid) { "NIST SP 1075-NCNR" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 260-126 rev 2013" do
    let(:original_pubid) { "NIST SP 260-126 rev 2013" }
    let(:short_pubid) { "NIST SP 260-126r2013" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-27ra" do
    let(:original_pubid) { "NIST SP 800-27ra" }
    let(:short_pubid) { "NIST SP 800-27ra" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-53ar1" do
    let(:original_pubid) { "NIST SP 800-53ar1" }
    let(:short_pubid) { "NIST SP 800-53Ar1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-53Ar4" do
    let(:short_pubid) { "NIST SP 800-53Ar4" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 800-57Pt3r1" do
    let(:original_pubid) { "NIST SP 800-57Pt3r1" }
    let(:short_pubid) { "NIST SP 800-57pt3r1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 801-errata" do
    let(:original_pubid) { "NIST SP 801-errata" }
    let(:short_pubid) { "NIST SP 801err" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST SP 955 Suppl." do
    let(:original_pubid) { "NIST SP 955 Suppl." }
    let(:short_pubid) { "NIST SP 955sup" }

    it_behaves_like "converts pubid to different formats"
  end
end
