require "parslet/rig/rspec"

RSpec.describe Pubid::Ieee::Parser do
  subject { described_class.new }

  it "parses draft date" do
    expect(subject.draft_date).to parse(", Feb 6, 2007")
  end

  it "parses part" do
    expect(subject.part_subpart_year).to parse("-20601a", trace: true)
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
    let(:iso_identifier) { "IEC/IEEE 62582-1:2011"}

    it "parses iso identifier" do
      expect(subject.iso_identifier).to parse(iso_identifier, trace: true)
      # expect(subject.identifier.parse("#{iso_identifier} Edition 1.0 2011-08", trace: true))
      #   .to eq([{ iso_identifier: { identifier: iso_identifier } }])
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
  end

  describe "#iso_parameters" do
    it "parses just edition" do
      expect(subject.iso_parameters)
        .to parse(" Edition 2.0 2013-04", trace: true)
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
            Pubid::Ieee::Transformer.new.apply(subject.parse(pub_id))
          rescue Exception => failure
            raise Pubid::Ieee::Errors::ParseError, "couldn't parse #{pub_id}"
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
