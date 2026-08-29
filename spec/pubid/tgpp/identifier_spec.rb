# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Tgpp::Identifier do
  describe ".parse" do
    context "technical specification with REL- release" do
      subject { "TS 23.207:REL-4/2.0.0" }

      let(:parsed) { described_class.parse(subject) }

      it "parses as TechnicalSpecification" do
        expect(parsed).to be_a(Pubid::Tgpp::Identifiers::TechnicalSpecification)
      end

      it "parses the dotted number core" do
        expect(parsed.number).to eq("23.207")
      end

      it "has no suffix" do
        expect(parsed.suffix).to be_nil
      end

      it "has no parts" do
        expect(parsed.parts).to eq([])
      end

      it "parses the release verbatim" do
        expect(parsed.release).to eq("REL-4")
      end

      it "parses the version" do
        expect(parsed.version).to eq("2.0.0")
      end

      it "round-trips without publisher by default" do
        expect(parsed.to_s).to eq(subject)
      end

      it "renders with the 3GPP publisher on request" do
        expect(parsed.to_s(with_publisher: true))
          .to eq("3GPP TS 23.207:REL-4/2.0.0")
      end

      it "does not leak the publisher flag past the to_s call that set it" do
        parsed.to_s(with_publisher: true)
        expect(parsed.render(format: :human)).to eq("TS 23.207:REL-4/2.0.0")
      end
    end

    context "technical report" do
      subject { "TR 26.905:REL-8/1.0.0" }

      let(:parsed) { described_class.parse(subject) }

      it "parses as TechnicalReport" do
        expect(parsed).to be_a(Pubid::Tgpp::Identifiers::TechnicalReport)
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "accepts an optional leading 3GPP prefix on input" do
      subject { "3GPP TS 23.207:REL-4/2.0.0" }

      let(:parsed) { described_class.parse(subject) }

      it "normalizes to the no-prefix form" do
        expect(parsed.to_s).to eq("TS 23.207:REL-4/2.0.0")
      end
    end

    context "letter suffix on the number (U / dcs / ext)" do
      describe "UMTS 'U' suffix" do
        subject { "TR 00.01U:UMTS/3.0.0" }

        let(:parsed) { described_class.parse(subject) }

        it "captures the suffix" do
          expect(parsed.suffix).to eq("U")
        end

        it "parses the UMTS release" do
          expect(parsed.release).to eq("UMTS")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "'dcs' suffix with Ph release" do
        subject { "TS 02.06dcs:Ph1/2.0.0" }

        let(:parsed) { described_class.parse(subject) }

        it "captures the suffix" do
          expect(parsed.suffix).to eq("dcs")
        end

        it "parses the phase release" do
          expect(parsed.release).to eq("Ph1")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "hyphenated parts" do
      describe "single part" do
        subject { "TS 26.171-1:REL-8/8.0.0" }

        let(:parsed) { described_class.parse(subject) }

        it "parses the part" do
          expect(parsed.parts).to eq(["1"])
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "two-level, zero-padded parts" do
        subject { "TS 29.198-04-1:REL-5/5.0.0" }

        let(:parsed) { described_class.parse(subject) }

        it "preserves both zero-padded parts" do
          expect(parsed.parts).to eq(%w[04 1])
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "'Release N' release form (with internal space)" do
      subject { "TS 02.68:Release 2000/9.0.0" }

      let(:parsed) { described_class.parse(subject) }

      it "parses the whole release token verbatim" do
        expect(parsed.release).to eq("Release 2000")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "legacy record with no release segment" do
      subject { "TS 29.215/2.0.0" }

      let(:parsed) { described_class.parse(subject) }

      it "has a nil release" do
        expect(parsed.release).to be_nil
      end

      it "still parses the version" do
        expect(parsed.version).to eq("2.0.0")
      end

      it "round-trips without a release colon" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    # A user reference omits the trailing ":<release>/<version>" qualifiers;
    # relaton parses that bare form to search the index, so it must parse with
    # the omitted components nil (see spec/pubid/partial_ref_spec.rb).
    context "partial references (bare / release-only / version-only)" do
      {
        "TS 23.207" => {
          klass: Pubid::Tgpp::Identifiers::TechnicalSpecification,
          number: "23.207", suffix: nil, parts: [],
          release: nil, version: nil, renders: "TS 23.207"
        },
        "3GPP TS 23.207" => {
          klass: Pubid::Tgpp::Identifiers::TechnicalSpecification,
          number: "23.207", suffix: nil, parts: [],
          release: nil, version: nil, renders: "TS 23.207"
        },
        "TS 29.198-04-1" => {
          klass: Pubid::Tgpp::Identifiers::TechnicalSpecification,
          number: "29.198", suffix: nil, parts: %w[04 1],
          release: nil, version: nil, renders: "TS 29.198-04-1"
        },
        "TR 00.01U" => {
          klass: Pubid::Tgpp::Identifiers::TechnicalReport,
          number: "00.01", suffix: "U", parts: [],
          release: nil, version: nil, renders: "TR 00.01U"
        },
        "TS 23.207:REL-4" => {
          klass: Pubid::Tgpp::Identifiers::TechnicalSpecification,
          number: "23.207", suffix: nil, parts: [],
          release: "REL-4", version: nil, renders: "TS 23.207:REL-4"
        },
        "TS 23.207/4.0.0" => {
          klass: Pubid::Tgpp::Identifiers::TechnicalSpecification,
          number: "23.207", suffix: nil, parts: [],
          release: nil, version: "4.0.0", renders: "TS 23.207/4.0.0"
        },
      }.each do |ref, expected|
        describe ref do
          let(:parsed) { described_class.parse(ref) }

          it "builds the right identifier type" do
            expect(parsed).to be_a(expected[:klass])
          end

          it "parses the document code" do
            expect([parsed.number, parsed.suffix, parsed.parts])
              .to eq([expected[:number], expected[:suffix], expected[:parts]])
          end

          it "leaves the omitted qualifiers nil" do
            expect([parsed.release, parsed.version])
              .to eq([expected[:release], expected[:version]])
          end

          it "renders without a dangling separator" do
            expect(parsed.to_s).to eq(expected[:renders])
          end

          it "keeps a non-empty index key" do
            expect(parsed.root.number.to_s).not_to be_empty
          end
        end
      end

      it "renders the bare form with the publisher on request" do
        expect(described_class.parse("TS 23.207").to_s(with_publisher: true))
          .to eq("3GPP TS 23.207")
      end
    end

    context "a partial reference matches every full identifier" do
      let(:bare) { described_class.parse("TS 23.207") }

      it "matches a fully qualified identifier" do
        full = described_class.parse("TS 23.207:REL-4/4.0.0")
        expect(bare.matches?(full, ignore: %i[release version])).to be true
      end

      it "does not match a different document number" do
        other = described_class.parse("TS 23.208:REL-4/4.0.0")
        expect(bare.matches?(other, ignore: %i[release version])).to be false
      end
    end

    context "still rejects incomplete or malformed input" do
      [
        "TS",                    # type alone
        "TS foo",                # no number core
        "TS 23.207/4.0",         # two-part version
        "TS 23.207/",            # dangling version separator
        "TS 23.207:",            # dangling release separator
        "TS 23.207:REL-4/4.0",   # two-part version after a release
        "TS 23.207:REL-4/",      # dangling separator after a release
        # A mistyped "/" must not silently misfile the version as a release.
        # Only reachable once the version segment became optional; no release
        # in the published index contains a dot at all.
        "TS 23.207:2.0.0",
        "TR 00.01U:3.0.0",
      ].each do |bad|
        it "rejects #{bad.inspect}" do
          expect { described_class.parse(bad) }.to raise_error(StandardError)
        end
      end

      # The guard is anchored at end of input, so a release that merely starts
      # with digits and dots is untouched when a real version follows.
      it "still accepts a release-shaped token when a version follows" do
        parsed = described_class.parse("TS 23.207:Release 2000/9.0.0")
        expect([parsed.release, parsed.version])
          .to eq(["Release 2000", "9.0.0"])
      end
    end

    context "input length guard" do
      it "raises ArgumentError for over-long input" do
        expect { described_class.parse("TS #{'9' * 1001}") }
          .to raise_error(ArgumentError, /maximum length/)
      end
    end
  end
end
