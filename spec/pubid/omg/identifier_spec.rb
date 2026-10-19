# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Omg::Identifier do
  describe ".parse" do
    context "acronym + version" do
      subject(:parsed) { described_class.parse("OMG AMI4CCM 1.0") }

      it "captures acronym" do
        expect(parsed.acronym).to eq("AMI4CCM")
      end

      it "captures version" do
        expect(parsed.version).to eq("1.0")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq("OMG AMI4CCM 1.0")
      end
    end

    context "mixed-case acronym (SysML)" do
      it "round-trips" do
        expect(described_class.parse("OMG SysML 1.6").to_s).to eq("OMG SysML 1.6")
      end
    end

    context "version with beta suffix" do
      it "captures the full version string" do
        expect(described_class.parse("OMG DDS 5 beta 3").version).to eq("5 beta 3")
      end
    end

    context "acronym only" do
      it "round-trips" do
        expect(described_class.parse("OMG CORBA").to_s).to eq("OMG CORBA")
      end
    end

    it "raises on malformed input" do
      expect { described_class.parse("OMG") }
        .to raise_error(Parslet::ParseFailed)
    end
  end

  # OMG published UML 2.1.1 as two documents, Superstructure and
  # Infrastructure, and its URLs carry the same segment
  # (/spec/UML/2.1.1/Superstructure). The segment also holds a format name
  # (/spec/DDS/1.4/PDF). Both occupy one optional component after the version.
  describe "document part" do
    subject(:parsed) { described_class.parse("OMG UML 2.1.1 Superstructure") }

    it "captures the part" do
      expect(parsed.part).to eq("Superstructure")
    end

    it "keeps the acronym and the version" do
      expect(parsed.acronym).to eq("UML")
      expect(parsed.version).to eq("2.1.1")
    end

    it "round-trips" do
      expect(parsed.to_s).to eq("OMG UML 2.1.1 Superstructure")
    end

    it "reads a format name in the same position" do
      expect(described_class.parse("OMG DDS 1.4 PDF").part).to eq("PDF")
    end

    it "parses without a version" do
      identifier = described_class.parse("OMG UML Superstructure")

      expect(identifier.part).to eq("Superstructure")
      expect(identifier.version).to be_nil
    end

    it "is settable" do
      identifier = described_class.parse("OMG UML 2.1.1")
      identifier.part = "Infrastructure"

      expect(identifier.to_s).to eq("OMG UML 2.1.1 Infrastructure")
    end
  end

  # OMG writes the separator both ways. pubid accepts both and renders one, so
  # two spellings of the same document stay ==, and #matches? works between
  # them. A sibling attribute recording the input separator would break that.
  describe "separator normalization" do
    it "accepts a slash and renders a space" do
      expect(described_class.parse("OMG UML 2.1.1/Superstructure").to_s)
        .to eq("OMG UML 2.1.1 Superstructure")
    end

    it "accepts a slash after the version" do
      expect(described_class.parse("OMG DDS 1.4/PDF").to_s)
        .to eq("OMG DDS 1.4 PDF")
    end

    it "makes the two spellings equal" do
      expect(described_class.parse("OMG DDS 1.4/PDF"))
        .to eq(described_class.parse("OMG DDS 1.4 PDF"))
    end
  end

  describe "the document part as a discriminator" do
    let(:superstructure) do
      described_class.parse("OMG UML 2.1.1 Superstructure")
    end
    let(:infrastructure) do
      described_class.parse("OMG UML 2.1.1 Infrastructure")
    end

    it "tells the two documents apart" do
      expect(superstructure).not_to eq(infrastructure)
    end

    it "keeps them apart when the version is ignored" do
      expect(superstructure.matches?(infrastructure, ignore: %i[version]))
        .to be false
    end

    it "matches a part-less reference when the part is ignored" do
      expect(described_class.parse("OMG UML 2.1.1")
        .matches?(superstructure, ignore: %i[part])).to be true
    end
  end

  describe "#exclude" do
    subject(:parsed) { described_class.parse("OMG UML 2.1.1 Superstructure") }

    it "drops the version and keeps the part" do
      excluded = parsed.exclude(:version)

      expect(excluded.version).to be_nil
      expect(excluded.part).to eq("Superstructure")
      expect(excluded.to_s).to eq("OMG UML Superstructure")
    end

    it "drops the part and keeps the version" do
      excluded = parsed.exclude(:part)

      expect(excluded.part).to be_nil
      expect(excluded.to_s).to eq("OMG UML 2.1.1")
    end
  end

  # OMG's own metadata for https://www.omg.org/spec/UML/2.5/Beta1/ gives the
  # version as "2.5 beta", and DDS 1.4 supersedes .../DDS/1.4/Beta2. Both
  # spellings are real, so the number after "beta" is optional.
  describe "bare beta" do
    subject(:parsed) { described_class.parse("OMG UML 2.5 beta") }

    it "keeps beta inside the version" do
      expect(parsed.version).to eq("2.5 beta")
    end

    # Without this the document-part rule swallows "beta" and reports the
    # version as "2.5" — a silent wrong answer, not a parse failure.
    it "does not read beta as a document part" do
      expect(parsed.part).to be_nil
    end

    it "round-trips" do
      expect(parsed.to_s).to eq("OMG UML 2.5 beta")
    end

    it "still reads a numbered beta" do
      numbered = described_class.parse("OMG BPMN 2.0 beta 1")

      expect(numbered.version).to eq("2.0 beta 1")
      expect(numbered.part).to be_nil
    end

    # pubid#548: the glued catalogue label (/spec/ALMAS/1.5/Beta1) is the
    # version suffix, not a document part. A Beta-prefixed part without
    # digits ("BetaWave") still lexes as the part — the boundary guard.
    it "keeps a glued capitalized beta inside the version" do
      glued = described_class.parse("OMG ALMAS 1.5 Beta1")

      expect(glued.version).to eq("1.5 Beta1")
      expect(glued.part).to be_nil
      expect(glued.to_s).to eq("OMG ALMAS 1.5 Beta1")
    end

    it "reads a Beta-prefixed part without digits as the part" do
      part = described_class.parse("OMG XYZ 1.5 BetaWave")

      expect(part.version).to eq("1.5")
      expect(part.part).to eq("BetaWave")
    end

    it "reads a document part after a numbered beta" do
      identifier = described_class.parse("OMG UML 2.5 beta 1 PDF")

      expect(identifier.version).to eq("2.5 beta 1")
      expect(identifier.part).to eq("PDF")
    end

    it "reads a document part after a bare beta" do
      identifier = described_class.parse("OMG UML 2.5 beta PDF")

      expect(identifier.version).to eq("2.5 beta")
      expect(identifier.part).to eq("PDF")
    end

    # Parslet never backtracks into a .maybe that already succeeded, so an
    # unanchored " beta" literal makes the version eat the front of a document
    # part and then reject the whole identifier. Both these raised before the
    # word-boundary guard.
    context "when a document part begins with the beta label" do
      it "reads the glued lowercase form as a part" do
        identifier = described_class.parse("OMG DDS 1.4 beta2")

        expect(identifier.version).to eq("1.4")
        expect(identifier.part).to eq("beta2")
      end

      it "reads a longer word as a part" do
        identifier = described_class.parse("OMG DDS 1.4 betawave")

        expect(identifier.version).to eq("1.4")
        expect(identifier.part).to eq("betawave")
      end

      it "does not let the beta number eat a part that starts with a digit" do
        identifier = described_class.parse("OMG UML 2.5 beta 1x")

        expect(identifier.version).to eq("2.5 beta")
        expect(identifier.part).to eq("1x")
      end
    end
  end

  describe "serialization" do
    subject(:parsed) { described_class.parse("OMG UML 2.1.1 Superstructure") }

    it "emits the part as a bare scalar" do
      expect(parsed.to_hash).to eq(
        "_type" => "pubid:omg:specification",
        "acronym" => "UML",
        "version" => "2.1.1",
        "part" => "Superstructure",
      )
    end

    it "omits the part when there is none" do
      expect(described_class.parse("OMG UML 2.1.1").to_hash)
        .not_to have_key("part")
    end

    # to_s and to_hash agreeing is not enough: only == sees an attribute that
    # one construction path leaves nil and the other fills.
    it "round-trips through from_hash" do
      expect(described_class.from_hash(parsed.to_hash)).to eq(parsed)
    end
  end

  # The acronym is the URL segment of https://www.omg.org/spec/<ACRONYM>/, and
  # relaton builds that URL from the parsed acronym. So the acronym must hold
  # every character OMG puts in the segment, verbatim.
  describe "acronym charset" do
    {
      "OMG DDS-XTypes 1.3" => ["DDS-XTypes", "1.3"],
      "OMG DDSI-RTPS 2.5" => ["DDSI-RTPS", "2.5"],
      "OMG DDS-PSM-Cxx" => ["DDS-PSM-Cxx", nil],
      "OMG EDMC-FIBO/BE 1.1" => ["EDMC-FIBO/BE", "1.1"],
      "OMG EDMC-FIBO/BE" => ["EDMC-FIBO/BE", nil],
      "OMG VSIPL++ 1.3" => ["VSIPL++", "1.3"],
      "OMG smartant 1.0" => ["smartant", "1.0"],
    }.each do |ref, (acronym, version)|
      it "reads #{ref} as acronym #{acronym}" do
        identifier = described_class.parse(ref)

        expect(identifier.acronym).to eq(acronym)
        expect(identifier.version).to eq(version)
        expect(identifier.part).to be_nil
        expect(identifier.to_s).to eq(ref)
      end
    end

    # Every acronym on https://www.omg.org/spec/ that the letters-and-digits
    # rule rejected (30 of 270, fetched 2026-09-14).
    %w[
      APP-INST CORBA-REST DDS-DLRL DDS-JSON DDS-Java DDS-Monitoring DDS-OPCUA
      DDS-PSM-Cxx DDS-RPC DDS-SECURITY DDS-TSN DDS-WEB DDS-XML DDS-XRCE
      DDS-XTypes DDSI-RTPS EDMC-FIBO/BE EDMC-FIBO/FBC EDMC-FIBO/FND
      EDMC-FIBO/IND IDL4-CPP IDL4-CSHARP IDL4-Java IEF-RA NIEM-UML PAGE-OM
      TelcoML-SES VSIPL++ WS-POS smartant
    ].each do |acronym|
      it "keeps the catalog acronym #{acronym} verbatim" do
        identifier = described_class.parse("OMG #{acronym}")

        expect(identifier.acronym).to eq(acronym)
        expect(identifier.to_s).to eq("OMG #{acronym}")
      end
    end

    # A slash before the version belongs to the acronym, because OMG puts it in
    # the URL segment (spec/EDMC-FIBO/BE/). A slash after the version still
    # separates the document part.
    describe "the slash" do
      it "separates the part after a version" do
        identifier = described_class.parse("OMG DDS 1.4/PDF")

        expect(identifier.acronym).to eq("DDS")
        expect(identifier.part).to eq("PDF")
      end

      it "belongs to the acronym before a version" do
        identifier = described_class.parse("OMG UML/Superstructure")

        expect(identifier.acronym).to eq("UML/Superstructure")
        expect(identifier.part).to be_nil
      end

      it "separates the part after a version that follows a slashed acronym" do
        identifier = described_class.parse("OMG EDMC-FIBO/BE 1.1/PDF")

        expect(identifier.acronym).to eq("EDMC-FIBO/BE")
        expect(identifier.version).to eq("1.1")
        expect(identifier.part).to eq("PDF")
      end
    end

    ["OMG DDS-", "OMG -DDS", "OMG DDS/", "OMG DDS--XML", "OMG 1DDS",
     "OMG +DDS"].each do |ref|
      it "rejects #{ref.inspect}" do
        expect { described_class.parse(ref) }
          .to raise_error(Parslet::ParseFailed)
      end
    end
  end

  # The relaton OMG flavor queries this string and expects a rejection. It is a
  # document title, not an identifier.
  it "rejects a document title" do
    title = "OMG Model Driven Architecture Guide rev. 2.0"

    expect { described_class.parse(title) }
      .to raise_error(Parslet::ParseFailed)
  end
end
