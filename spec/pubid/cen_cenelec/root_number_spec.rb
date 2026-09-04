# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for CEN/CENELEC.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. `Identifiers::EuropeanPrestandard` is a WRAPPER: an
# "ENV ISO 11079:1999" carries the whole document identity on its nested
# `adopted_identifier` (the ISO standard) and holds no number of its own, so it
# keyed "" — and so did every BSI identifier that adopts one, because BSI's
# `AdoptedEuropeanNorm#number` delegates INTO this class and the chain stopped
# here.
#
# The fix is `#root`, not a `#number` method. `number` is a lutaml attribute in
# this hierarchy, and CLAUDE.md records that defining a `#number` method
# collides with the generated accessor and corrupts attribute resolution
# hierarchy-wide. `#root` is a plain method on ::Pubid::Identifier with an
# established wrapper precedent (ConsolidatedIdentifier walks
# `identifiers.first.root`), so walking `adopted_identifier` there is both safe
# and the documented shape.
module CenIndexKeySpec
  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/cen_cenelec/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::CenCenelec.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::CenCenelec index key (root.number)" do
  describe "Identifiers::EuropeanPrestandard" do
    subject(:id) { Pubid::CenCenelec.parse(ref) }

    context "ENV ISO 11079:1999" do
      let(:ref) { "ENV ISO 11079:1999" }

      it "walks #root to the adopted standard" do
        expect(id.root).to be_a(Pubid::Iso::Identifiers::InternationalStandard)
      end

      it "keys on the adopted standard's number" do
        expect(id.root.number.to_s).to eq("11079")
      end

      it "leaves the wrapper's own rendering unchanged" do
        expect(id.to_s).to eq(ref)
      end
    end

    context "ENV ISO/TR 13843:2001" do
      let(:ref) { "ENV ISO/TR 13843:2001" }

      it "keys on the adopted standard's number" do
        expect(id.root.number.to_s).to eq("13843")
      end
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(CenIndexKeySpec.parsed_corpus.size).to be >= 100
    end

    it "gives every identifier a non-empty root.number" do
      bad = CenIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end
  end
end
