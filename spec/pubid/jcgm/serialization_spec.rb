# frozen_string_literal: true

require "spec_helper"
require "pubid/jcgm"

RSpec.describe "JCGM serialization" do
  describe "#to_hash / .from_hash round-trip" do
    {
      "JCGM 17th Meeting (2012)" => "pubid:jcgm:meeting",
      "JCGM 11st Meeting (2006)" => "pubid:jcgm:meeting",
      "JCGM 23rd Meeting (2020)" => "pubid:jcgm:meeting",
      # a guide, to show the mechanism is general (not meeting-specific)
      "JCGM 100:2008" => "pubid:jcgm:guide",
      # dateless named guides and the corrigendum suffix form
      "JCGM GUM" => "pubid:jcgm:guide",
      "JCGM VIM-3" => "pubid:jcgm:guide",
      "JCGM GUM-6:2020" => "pubid:jcgm:gum-guide",
      "JCGM 200:2008 Corrigendum" => "pubid:jcgm:corrigendum",
      "JCGM 100:2008/Amd 1:2023" => "pubid:jcgm:amendment",
    }.each do |id_str, expected_type|
      describe id_str do
        let(:identifier) { Pubid::Jcgm.parse(id_str) }
        let(:hash) { identifier.to_hash }

        it "produces a non-empty hash" do
          expect(hash).to be_a(Hash)
          expect(hash).not_to be_empty
        end

        it "carries the polymorphic _type #{expected_type.inspect}" do
          expect(hash["_type"]).to eq(expected_type)
        end

        it "rebuilds via from_hash and round-trips to_s" do
          rebuilt = Pubid::Jcgm::Identifier.from_hash(hash)
          expect(rebuilt.to_s).to eq(id_str)
        end

        it "is idempotent under from_hash(to_hash)" do
          rebuilt = Pubid::Jcgm::Identifier.from_hash(hash)
          expect(rebuilt.to_hash).to eq(hash)
        end

        it "preserves the URN through from_hash(to_hash)" do
          rebuilt = Pubid::Jcgm::Identifier.from_hash(hash)
          expect(rebuilt.to_urn).to eq(identifier.to_urn)
        end

        # The assertion the other four miss. to_s, to_hash and to_urn were all
        # correct while `typed_stage.original_abbr` diverged between the parse
        # path (nil) and the attribute default (the canonical abbreviation), so
        # only `==` ever saw it.
        it "rebuilds an EQUAL identifier" do
          rebuilt = Pubid::Jcgm::Identifier.from_hash(hash)
          expect(rebuilt).to eq(identifier)
        end

        # `#matches?` is `exclude(*ignore) == other.exclude(*ignore)`, so an
        # inequality survives the exclusion. This is the shape of a relaton
        # index lookup: a parsed reference against a from_hash-ed row.
        it "matches its own rebuilt row" do
          rebuilt = Pubid::Jcgm::Identifier.from_hash(hash)
          expect(identifier.matches?(rebuilt, ignore: [])).to be true
          expect(identifier.matches?(rebuilt, ignore: [:date])).to be true
        end
      end
    end
  end

  # The flattened hash carries ONLY per-instance information: the derived
  # publisher / type / stage / typed_stage are dropped (reconstructed from the
  # class on load), and components collapse to bare scalars (number "100", not
  # {value:"100"}; year "2008", not {year:"2008"}). _type pins the doctype.
  describe "compact shape" do
    {
      "JCGM 100:2008" => {
        "_type" => "pubid:jcgm:guide", "number" => "100", "year" => "2008"
      },
      # partial (dateless) numeric guide — omits year entirely
      "JCGM 100" => {
        "_type" => "pubid:jcgm:guide", "number" => "100"
      },
      "JCGM GUM" => {
        "_type" => "pubid:jcgm:guide", "number" => "GUM"
      },
      "JCGM VIM-3" => {
        "_type" => "pubid:jcgm:guide", "number" => "VIM-3"
      },
      "JCGM GUM-6:2020" => {
        "_type" => "pubid:jcgm:gum-guide", "number" => "6", "year" => "2020"
      },
      "JCGM 17th Meeting (2012)" => {
        "_type" => "pubid:jcgm:meeting", "number" => "17", "year" => "2012"
      },
      "JCGM 200:2008 Corrigendum" => {
        "_type" => "pubid:jcgm:corrigendum",
        "base" => {
          "_type" => "pubid:jcgm:guide", "number" => "200", "year" => "2008"
        },
      },
      "JCGM 100:2008/Amd 1:2023" => {
        "_type" => "pubid:jcgm:amendment", "number" => "1", "year" => "2023",
        "base" => {
          "_type" => "pubid:jcgm:guide", "number" => "100", "year" => "2008"
        }
      },
    }.each do |id_str, expected|
      it "#{id_str} serializes to #{expected.inspect}" do
        expect(Pubid::Jcgm.parse(id_str).to_hash).to eq(expected)
      end
    end
  end
end
