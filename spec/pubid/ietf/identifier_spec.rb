# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Ietf::Identifier do
  describe ".parse" do
    context "RFC" do
      describe "RFC 2119" do
        subject { "RFC 2119" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as Rfc" do
          expect(parsed).to be_a(Pubid::Ietf::Identifiers::Rfc)
        end

        it "parses the number as a string (no zero-pad)" do
          expect(parsed.number).to eq("2119")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      it "parses a single-digit RFC" do
        expect(described_class.parse("RFC 1").number).to eq("1")
      end
    end

    context "sub-series" do
      {
        "BCP 3" => [Pubid::Ietf::Identifiers::Bcp, "BCP"],
        "STD 66" => [Pubid::Ietf::Identifiers::Std, "STD"],
        "FYI 1" => [Pubid::Ietf::Identifiers::Fyi, "FYI"],
      }.each do |ref, (klass, series)|
        describe ref do
          let(:parsed) { described_class.parse(ref) }

          it "parses as #{klass}" do
            expect(parsed).to be_a(klass)
          end

          it "parses series and number" do
            expect(parsed.series).to eq(series)
            expect(parsed.number).to eq(ref.split.last)
          end

          it "round-trips" do
            expect(parsed.to_s).to eq(ref)
          end
        end
      end
    end

    context "Internet-Draft" do
      describe "draft-giuliano-treedn-02 (versioned)" do
        subject { "draft-giuliano-treedn-02" }

        let(:parsed) { described_class.parse(subject) }

        it "parses as InternetDraft" do
          expect(parsed).to be_a(Pubid::Ietf::Identifiers::InternetDraft)
        end

        it "keeps the leading draft- in number and splits the version" do
          expect(parsed.number).to eq("draft-giuliano-treedn")
          expect(parsed.version).to eq("02")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "draft-giuliano-treedn (unversioned)" do
        subject { "draft-giuliano-treedn" }

        let(:parsed) { described_class.parse(subject) }

        it "has a nil version" do
          expect(parsed.number).to eq("draft-giuliano-treedn")
          expect(parsed.version).to be_nil
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "draft-adams-cast-256 (three-digit topic tail, not a version)" do
        subject { "draft-adams-cast-256" }

        let(:parsed) { described_class.parse(subject) }

        it "keeps the digits in the number and has no version" do
          expect(parsed.number).to eq("draft-adams-cast-256")
          expect(parsed.version).to be_nil
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "draft-aboba-context-802-00 (digit-tail topic + version)" do
        subject { "draft-aboba-context-802-00" }

        let(:parsed) { described_class.parse(subject) }

        it "splits only the final two-digit version" do
          expect(parsed.number).to eq("draft-aboba-context-802")
          expect(parsed.version).to eq("00")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      it "handles a slug ending in four digits (no version)" do
        parsed = described_class.parse("draft-ietf-mpls-ldp-survey2002")
        expect(parsed.number).to eq("draft-ietf-mpls-ldp-survey2002")
        expect(parsed.version).to be_nil
        expect(parsed.to_s).to eq("draft-ietf-mpls-ldp-survey2002")
      end

      it "handles + and _ in the slug" do
        expect(described_class.parse("draft-durand-gse+-00").to_s)
          .to eq("draft-durand-gse+-00")
        expect(described_class.parse("draft-conta-ipv6-nd_ext_ind-00").to_s)
          .to eq("draft-conta-ipv6-nd_ext_ind-00")
      end

      # Two historical shapes the relaton-data-ids corpus carries: a dot inside
      # a topic token, and uppercase letters in protocol/organisation names.
      # 50 of the 166,740 published draft ids need them (21 dotted, 29 upper).
      context "dotted slugs" do
        it "splits the trailing version after a dotted token" do
          parsed = described_class.parse("draft-ietf-pilc-2.5g3g-12")
          expect(parsed.number).to eq("draft-ietf-pilc-2.5g3g")
          expect(parsed.version).to eq("12")
          expect(parsed.to_s).to eq("draft-ietf-pilc-2.5g3g-12")
        end

        it "keeps a dot that is not part of a version" do
          parsed = described_class.parse("draft-manning-ip4.int-roe-00")
          expect(parsed.number).to eq("draft-manning-ip4.int-roe")
          expect(parsed.version).to eq("00")
        end

        it "keeps a dotted version-like token inside the slug" do
          # "v1.0" is a topic token, not the draft version; only the final
          # "-NN" is the version.
          parsed = described_class.parse("draft-ietf-trade-iotp-v1.0-dsig-05")
          expect(parsed.number).to eq("draft-ietf-trade-iotp-v1.0-dsig")
          expect(parsed.version).to eq("05")
        end

        it "handles a dotted tail with no version" do
          expect(described_class.parse("draft-ietf-pem-ansix9.17-00").to_s)
            .to eq("draft-ietf-pem-ansix9.17-00")
        end
      end

      context "uppercase slugs" do
        it "preserves case in the slug" do
          parsed = described_class.parse("draft-chapin-clnp-ISO8473-00")
          expect(parsed.number).to eq("draft-chapin-clnp-ISO8473")
          expect(parsed.version).to eq("00")
          expect(parsed.to_s).to eq("draft-chapin-clnp-ISO8473-00")
        end

        it "handles mixed case and a + sign" do
          expect(described_class.parse("draft-okanoue-mobileip-R+A-00").to_s)
            .to eq("draft-okanoue-mobileip-R+A-00")
        end

        it "handles both a dot and uppercase in one slug" do
          expect(
            described_class.parse("draft-nielsen-v6ops-3GPP-zeroconf-goals-00")
              .to_s,
          ).to eq("draft-nielsen-v6ops-3GPP-zeroconf-goals-00")
        end
      end
    end

    context "invalid input" do
      it "raises on an unrecognized token" do
        expect { described_class.parse("XYZ 1") }.to raise_error(StandardError)
      end

      it "raises on trailing garbage" do
        expect { described_class.parse("RFC 2119x") }
          .to raise_error(StandardError)
      end

      # The widened draft character class is still a closed set: a space or a
      # slash inside a slug is crawler junk, not an identifier.
      it "raises on a space inside a draft slug" do
        expect { described_class.parse("draft-lee-pce-wson routing-00") }
          .to raise_error(StandardError)
      end

      it "raises on a slash inside a draft slug" do
        expect { described_class.parse("draft-foo/bar-00") }
          .to raise_error(StandardError)
      end

      it "raises on an ampersand inside a draft slug" do
        expect { described_class.parse("draft-caviglia-mp2cp&cp2mp-00") }
          .to raise_error(StandardError)
      end
    end
  end

  describe "input length guard" do
    it "raises ArgumentError above MAX_INPUT_LENGTH" do
      expect { Pubid::Ietf.parse("RFC #{'1' * Pubid::MAX_INPUT_LENGTH}") }
        .to raise_error(ArgumentError, /maximum length/)
    end
  end
end
