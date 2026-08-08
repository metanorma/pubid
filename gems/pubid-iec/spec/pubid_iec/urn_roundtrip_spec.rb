module Pubid::Iec
  # Locks the ABNF-canonical IEC URN forms used as ground truth by
  # relaton-data-iec (see references/iec-urn-specification.adoc). Every case
  # must satisfy the round-trip identity: parse(urn).urn == urn.
  RSpec.describe "IEC canonical URN round-trip" do
    # pubid string => canonical URN (verified against relaton-data-iec)
    CANONICAL = {
      # plain amendment: 5-colon base, "::" relation-marker, amd:NUM:DATE
      "IEC 61966-2-1:1999/AMD1:2003" =>
        "urn:iec:std:iec:61966-2-1:1999:::::amd:1:2003",
      "IEC 60050-102:2007/AMD1:2017" =>
        "urn:iec:std:iec:60050-102:2007:::::amd:1:2017",
      "IEC 60050-351:2013/AMD1:2016" =>
        "urn:iec:std:iec:60050-351:2013:::::amd:1:2016",
      # consolidated (CSV): "csv" in deliverable slot, ":plus:" for amendments
      "IEC 61666:2010+AMD1:2021 CSV" =>
        "urn:iec:std:iec:61666:2010::csv::plus:amd:1:2021",
      "IEC 62439-1:2010+AMD1:2012+AMD2:2016 CSV" =>
        "urn:iec:std:iec:62439-1:2010::csv::plus:amd:1:2012:plus:amd:2:2016",
      # CSV consolidated amendment + separate corrigendum ("::" for cor)
      "IEC 60529:1989+AMD1:1999 CSV/COR2:2007" =>
        "urn:iec:std:iec:60529:1989::csv::plus:amd:1:1999::cor:2:2007",
      # redline deliverable
      "IEC 61010-2-201:2017 RLV" =>
        "urn:iec:std:iec:61010-2-201:2017::rlv:",
      # plain document (unchanged, must stay canonical-compatible)
      "IEC 60050-102:2007" =>
        "urn:iec:std:iec:60050-102:2007:::",
      # non-IEC publisher amendment
      "CISPR 10:1981/AMD1:1983" =>
        "urn:iec:std:cispr:10:1981:::::amd:1:1983",
    }.freeze

    CANONICAL.each do |pubid, urn|
      context pubid do
        it "renders the canonical URN" do
          expect(Identifier.parse(pubid).urn.to_s).to eq(urn)
        end

        it "parses the canonical URN" do
          expect { Identifier.parse(urn) }.not_to raise_error
        end

        it "round-trips (parse(urn).urn == urn)" do
          expect(Identifier.parse(urn).urn.to_s).to eq(urn)
        end
      end
    end

    context "dated all-parts series URN" do
      let(:urn) { "urn:iec:std:iec:60034:2026::ser:" }

      it "parses and round-trips, keeping the date" do
        expect(Identifier.parse(urn).urn.to_s).to eq(urn)
      end
    end

    # A bare (undated) all-parts series is stored by relaton-data-iec without a
    # trailing language slot: urn:iec:std:iec:80000:::ser (not ...:ser:).
    context "bare all-parts series URN" do
      ["urn:iec:std:iec:80000:::ser",
       "urn:iec:std:iec:61076-7:::ser"].each do |urn|
        context urn do
          it "renders no trailing colon and round-trips" do
            expect(Identifier.parse(urn).urn.to_s).to eq(urn)
          end
        end
      end

      # Guards that dropping the empty language slot does not swallow a
      # legitimately-present language on a series.
      context "urn:iec:std:iec:80000:::ser:fr" do
        let(:urn) { "urn:iec:std:iec:80000:::ser:fr" }

        it "keeps the language slot and round-trips" do
          expect(Identifier.parse(urn).urn.to_s).to eq(urn)
        end
      end
    end
  end
end
