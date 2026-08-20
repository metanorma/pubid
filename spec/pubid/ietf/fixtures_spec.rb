# frozen_string_literal: true

require "spec_helper"

module IetfFixturesSpec
  FIXTURE_FILES = Dir.glob(File.join(__dir__,
                                     "../../fixtures/ietf/identifiers/pass",
                                     "*.txt")).freeze
end

# Every fixture line must satisfy the WHOLE relaton-index contract, with zero
# tolerance. A percentage threshold is wrong for IETF specifically: the unified
# index relaton builds is all-or-nothing — Relaton::Index::FileIO#deserialize_id
# raises on the FIRST id it cannot parse and #load_index then rejects the entire
# index, so one bad row means no consumer can resolve any IETF reference.
#
# The to_hash/from_hash leg is not redundant with relaton's own validation:
# FileIO#id_supported? SKIPS its round-trip check whenever the deserialized
# object is a concrete subclass (`return true unless
# obj.instance_of?(@pubid_class)`), and EVERY Pubid::Ietf id is a subclass
# (Rfc/Bcp/Std/Fyi/InternetDraft). A lossy to_hash would therefore pass
# relaton's validation silently and produce wrong lookups. pubid has to
# catch it here.
#
# Consequence: pass/*.txt is strictly BYTE-EXACT. Normalizing inputs — the
# zero-padded rfc-index.xml spellings STD0066 / RFC0001 / BCP0009 / FYI0036 —
# must NOT be added to these files; they are pinned by zero_padded_spec.rb.
RSpec.describe "IETF Fixture Round-trip Tests" do
  # A broken glob silently zeroes a fixture spec — it has happened twice in
  # this repo (the ITU and CIE fixture specs both iterated an empty file list
  # for a while). Assert the file list OUTSIDE the per-file `.each`, or this
  # whole file can go green with no coverage at all.
  it "finds every fixture file" do
    expect(IetfFixturesSpec::FIXTURE_FILES.map { |f| File.basename(f) })
      .to contain_exactly("bcp.txt", "fyi.txt", "internet_draft.txt",
                          "internet_draft_edge.txt",
                          "internet_draft_sample.txt", "rfc.txt", "std.txt")
  end

  describe "all fixture files" do
    IetfFixturesSpec::FIXTURE_FILES.each do |fixture_file|
      describe File.basename(fixture_file) do
        let(:identifiers) do
          File.readlines(fixture_file).map(&:strip).reject do |line|
            line.empty? || line.start_with?("#")
          end
        end

        it "parses, renders and round-trips every identifier" do
          failures = identifiers.filter_map do |id_str|
            parsed = Pubid::Ietf.parse(id_str)
            hash = parsed.to_hash
            rebuilt = Pubid::Ietf::Identifier.from_hash(hash)

            next if parsed.to_s == id_str &&
              rebuilt.to_s == id_str &&
              rebuilt.to_hash == hash &&
              !parsed.root.number.to_s.empty?

            { original: id_str, rendered: parsed.to_s, rebuilt: rebuilt.to_s,
              hash: hash, index_key: parsed.root.number.to_s }
          rescue StandardError => e
            { original: id_str, error: "#{e.class}: #{e.message}" }
          end

          expect(failures).to be_empty, lambda {
            "#{failures.size}/#{identifiers.count} failed. " \
              "First 10: #{failures.first(10)}"
          }
        end

        it "has at least one identifier" do
          expect(identifiers).not_to be_empty
        end
      end
    end
  end
end
