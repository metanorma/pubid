require "parslet/rig/rspec"

RSpec.describe Pubid::Ieee::Parser do
  subject { described_class.new }

  it "parses draft date" do
    expect(subject.draft_date).to parse(", Feb 6, 2007")
  end

  it "parses draft date without space" do
    expect(subject.draft_date).to parse(",Mar 2007")
  end

  it "parses part" do
    expect(subject.part_subpart_year).to parse("-20601a", trace: true)
    expect(subject.part_subpart_year).to parse(".3-2012", trace: true)
    expect(subject.part_subpart_year).to parse("-REV", trace: true)
  end

  it "parses identifier_without_dual_pubids" do
    expect(subject.identifier_without_dual_pubids).to parse("IEEE Std 802.3-2008", trace: true)
  end

  it "don't parse identifier with extra space" do
    expect(subject.parameters(Parslet::str(""))).not_to parse(" C22-1925", trace: true)
  end

  describe "#amendment" do
    it "parses amendments" do
      expect(subject.amendment).to parse("Amendment to IEEE Std 802.11-2012, as amended by IEEE Std 802.11ae-2012,"\
      " IEEE Std 802.11aa-2012, IEEE Std 802.11ad-2012, and IEEE Std 802.11ac-2013", trace: true)
    end

    it "parses amendments without ',' before as" do
      expect(subject.amendment).to parse("Amendment to IEEE Std 802.15.3-2016 as "\
        "amended by IEEE Std 802.15.3d-2017, and IEEE Std 802.15.3e-2017", trace: true)
    end

    it "parses single amendment to IEEE format" do
      expect(subject.amendment).to parse("Amendment to IEEE 802.3-2018", trace: true)
    end

    it "parses amendment to ISO format PubID" do
      expect(subject.amendment).to parse("Amendment to ISO/IEEE 11073-10101:2004", trace: true)
    end
  end

  describe "#additional_parameters" do
    let(:amendment_identifier) { "IEEE 802.3-2018" }

    it "parses additional_parameters" do
      expect(subject.additional_parameters.parse(" (Amendment to #{amendment_identifier})", trace: true))
        .to eq([{ amendment: { identifier: amendment_identifier } }])
    end

    it "parses iso revision" do
      expect(subject.additional_parameters).to parse(" (Revision of ISO/IEEE 11073-10101:2004)", trace: true)
    end

    it "parses incorporates with revision" do
      expect(subject.additional_parameters)
        .to parse(" (Revision of IEEE Std 525-1992/Incorporates IEEE Std 525-2007/Cor 1:2008)", trace: true)
    end
  end

  describe "#incorporates" do
    it do
      expect(subject.incorporates).to parse("Incorporates IEEE Std 525-2007/Cor 1:2008", trace: true)
    end
  end

  it "parses previous amendments" do
    expect(subject.previous_amendments).to parse(" as"\
      " amended by IEEE Std 802.15.3d-2017, and IEEE Std 802.15.3e-2017", trace: true)
  end

  it "parses draft date" do
    expect(subject.draft_date).to parse(", 2011", trace: true)
  end

  it "parses iso amendment" do
    expect(subject.iso_amendment).to parse("/Amd8-2021", trace: true)
  end

  describe "#identifier" do
    let(:identifier) { "IEEE 802.3-2018" }
    let(:iso_identifier) { "IEC/IEEE 62582-1:2011"}

    it "parses iso identifier" do
      expect(subject.identifier).to parse("#{iso_identifier} Edition 1.0 2011-08", trace: true)
      # expect(subject.identifier.parse("#{iso_identifier} Edition 1.0 2011-08", trace: true))
      #   .to eq([{ iso_identifier: { identifier: iso_identifier } }])
    end

    it "parses identifier with edition" do
      expect(subject.identifier).to parse("IEC 61691-6 Edition 1.0 2009-12", trace: true)
    end
  end

  describe "#iso_identifier" do
    let(:iso_identifier) { "IEC/IEEE 62582-1:2011" }

    it "parses iso identifier" do
      expect(subject.iso_identifier).to parse(iso_identifier, trace: true)
      # expect(subject.identifier.parse("#{iso_identifier} Edition 1.0 2011-08", trace: true))
      #   .to eq([{ iso_identifier: { identifier: iso_identifier } }])
    end

    it "parses iso identifier with stage after document number" do
      expect(subject.iso_identifier.parse("ISO/IEC/IEEE P26514/FDIS")[:iso_identifier]).to include(stage: "FDIS")
    end

    it "parses stage as part of document number" do
      # expect(subject.iso_identifier.parse("ISO/IEC/IEEE P15288-DIS-1403")[:iso_identifier])
      #   .to include({part: "1403", stage: "DIS"})
      expect(subject.iso_identifier).to parse("IEEE/ISO/IEC P29119-2-DIS", trace: true)
      expect(subject.iso_identifier.parse("IEEE/ISO/IEC P29119-2-DIS")[:iso_identifier])
        .to include(part: "2", stage: "DIS")
    end

    it "parses draft status" do
      expect(subject.identifier).to parse("IEEE Unapproved Draft Std P29148_CD2, Feb 2010", trace: true)
    end
  end

  describe "#iso_part_stage_iteration" do
    it { expect(subject.iso_part_stage_iteration).to parse("-2-DIS", trace: true) }
  end

  describe "#iso_stage_part_iteration" do
    it { expect(subject.iso_stage_part_iteration).to parse("-DIS-1403") }
  end

  describe "#iso_stage_part_iteration" do
    it { expect(subject.iso_stage_part_iteration).to parse("/CD") }
  end

  describe "#iso_part_stage_iteration_matcher" do
    it { expect(subject.iso_part_stage_iteration_matcher).to parse("-2-DIS", trace: true) }
    it { expect(subject.iso_part_stage_iteration_matcher).to parse("-DIS-1403") }
    it { expect(subject.iso_part_stage_iteration_matcher).to parse("/FDIS") }
  end

  describe "#iso_part" do
    it "don't match stage as last part" do
      expect(subject.iso_part).not_to parse("-2-DIS", trace: true)
    end

    it "match number without stage" do
      expect(subject.iso_part).to parse("-2", trace: true)
    end
  end

  describe "#dual_pubids" do
    it "parses dual-PubID with edition" do
      expect(subject.dual_pubids).to parse("(IEC 60255-24 Edition 2.0 2013-04)", trace: true)
    end

    it "parses ISO PubID as part of dual-PubID" do
      expect(subject.dual_pubids).to parse(" (ISO/IEC 8802-5:1998/Amd.1)", trace: true)
    end
  end

  describe "#identifier_with_organization" do
    it "parses identifier with edition" do
      expect(subject.identifier_with_organization).to parse("IEC 60255-24 Edition 2.0 2013-04", trace: true)
    end
  end

  describe "#edition" do
    it "parses edition" do
      expect(subject.edition).to parse(" Edition 2.0 2013-04", trace: true)
    end

    it "parses edition with (E)" do
      expect(subject.edition).to parse(", April 2014(E)", trace: true)
    end
  end

  describe "#iso_parameters" do
    it "parses just edition" do
      expect(subject.iso_parameters)
        .to parse(" Edition 2.0 2013-04", trace: true)
    end
  end

  describe "#ieee_without_prefix" do
    it "parses IEEE 1234-1987" do
      expect(subject.ieee_without_prefix).to parse("IEEE 1234-1987", trace: true)
    end
  end
end
