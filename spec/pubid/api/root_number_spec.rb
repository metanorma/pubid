# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for API.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. Every other API type set the `number` inherited from
# ::Pubid::Identifier, but `Identifiers::Mpms` kept the document number in its
# own `chapter` :string and left `number` nil, so all 30 Manual of Petroleum
# Measurement Standards ids keyed "".
#
# The chapter IS the document number — "API MPMS CH 12.2" is chapter 12,
# section 2 — so the attribute is MOVED rather than duplicated: `chapter` is
# deleted and the value lands in `number`, keeping `section`/`subsection` as
# the sibling part columns. That gives the ISO/IEEE bucket semantics a
# part-less reference needs: every section of chapter 12 shares one key.
#
# `CH` stays a literal marker in the renderer; it was never part of the value.
module ApiIndexKeySpec
  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/api/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::Api.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::Api index key (root.number)" do
  describe "Identifiers::Mpms" do
    # `rendered` differs from the input only for the misspelled "MPMP", which
    # pubid normalises to "MPMS". That normalisation is pre-existing on main
    # and is not what this change is about; it is pinned here so a future edit
    # to the type token is visible.
    [
      ["API MPMS CH 12.2", "12", "API MPMS CH 12.2"],
      ["API MPMP CH 10.10", "10", "API MPMS CH 10.10"],
    ].each do |ref, key, rendered|
      context ref do
        subject(:id) { Pubid::Api.parse(ref) }

        it "keys on the chapter #{key.inspect}" do
          expect(id.root.number.to_s).to eq(key)
        end

        it "renders as #{rendered.inspect}" do
          expect(id.to_s).to eq(rendered)
        end

        it "round-trips through from_hash(to_hash)" do
          h = id.to_hash
          expect(Pubid::Api::Identifier.from_hash(h).to_hash).to eq(h)
        end
      end
    end

    it "no longer serializes a separate `chapter`" do
      expect(Pubid::Api.parse("API MPMS CH 12.2").to_hash)
        .not_to have_key("chapter")
    end

    it "keeps the section as a sibling of the number" do
      id = Pubid::Api.parse("API MPMS CH 12.2")
      expect(id.section).to eq("2")
    end

    # The point of keying on the bare chapter: every section of one chapter
    # lands in the same bucket, so a part-less reference finds them all.
    it "puts every section of one chapter in the same bucket" do
      keys = ["API MPMS CH 12.2", "API MPMS CH 12.3"]
        .map { |r| Pubid::Api.parse(r).root.number.to_s }
      expect(keys.uniq).to eq(["12"])
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(ApiIndexKeySpec.parsed_corpus.size).to be >= 190
    end

    it "gives every identifier a non-empty root.number" do
      bad = ApiIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end
  end
end
