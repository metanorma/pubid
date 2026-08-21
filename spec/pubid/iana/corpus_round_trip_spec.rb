# frozen_string_literal: true

require "spec_helper"

# Corpus-scale round-trip validation for the IANA registry index. OPT-IN:
#
#   PUBID_IANA_CORPUS=/path/to/checkouts bundle exec rake test:corpus_iana
#
# PUBID_IANA_CORPUS points at a directory holding a local checkout of
# relaton-data-iana with its index-v1.yaml. Without it every example
# self-skips, so the default suite pays nothing.
#
# Why it exists: relaton's Relaton::Index::FileIO#id_supported? SKIPS its
# to_hash/from_hash validation whenever the deserialized object is a concrete
# subclass (`return true unless obj.instance_of?(@pubid_class)`), and every
# Pubid::Iana id is an Identifiers::Registry subclass. So no IANA row would
# ever be round-trip checked downstream: a lossy to_hash would pass relaton's
# validation silently and produce wrong lookups — no error, no warning. pubid
# has to catch it, and only a corpus-scale run can.
#
# The five things checked are exactly what an index depends on:
#   1. it parses at all              (FileIO#deserialize_id raises on the first
#                                     failure and rejects the WHOLE index)
#   2. to_s is byte-exact            (the id relaton stores and prints back;
#                                     the corpus stores the bare slug, so the
#                                     expected rendering is "IANA <slug>")
#   3. from_hash(to_hash) is faithful in both to_s and to_hash
#                                    (precisely the check relaton skips)
#   4. root.number is non-empty      (the key Relaton::Index bsearches on;
#                                     empty silently degrades to a linear scan)
#   5. to_mr_string is unique        (issue #142 — the MR doubles as a filename,
#                                     so a collision silently overwrites a file)
#
# ~3400 rows; expect a couple of seconds.
module IanaCorpusSpec
  ROOT = ENV.fetch("PUBID_IANA_CORPUS", nil)
  REPO = "relaton-data-iana"
  # Cap the collected failures so a pathological run cannot exhaust memory.
  MAX_FAILURES = 500

  def self.index_path
    ROOT && File.join(ROOT, REPO, "index-v1.yaml")
  end

  # Line scan rather than YAML.load. IANA slugs are plain scalars restricted to
  # [A-Za-z0-9._-] plus a single "/", so no quoting or escaping occurs; the
  # `- :id: ` line count matches the `:file:` count exactly.
  def self.each_id(path)
    return to_enum(:each_id, path) unless block_given?

    File.foreach(path) do |line|
      next unless line.start_with?("- :id: ")

      yield line[7..].strip.sub(/\A(["'])(.*)\1\z/, '\2')
    end
  end
end

RSpec.describe "Pubid::Iana published-corpus round-trip" do
  before do
    unless IanaCorpusSpec::ROOT
      skip "set PUBID_IANA_CORPUS=<dir containing relaton-data-iana> to run"
    end

    path = IanaCorpusSpec.index_path
    skip "missing #{path}" unless path && File.exist?(path)
  end

  let(:ids) { IanaCorpusSpec.each_id(IanaCorpusSpec.index_path).to_a }

  # Collect into a capped bucket: a pathological run must not exhaust memory,
  # and the cap keeps the failure message readable.
  def record(bucket, entry)
    bucket << entry if bucket.size < IanaCorpusSpec::MAX_FAILURES
  end

  it "parses, renders and round-trips every published id" do
    parse_failures = []
    render_failures = []
    round_trip_failures = []
    empty_keys = []

    ids.each do |slug|
      begin
        id = Pubid::Iana::Identifier.parse(slug)
      rescue StandardError => e
        record(parse_failures, [slug, e.class.to_s])
        next
      end

      record(render_failures, [slug, id.to_s]) if id.to_s != "IANA #{slug}"

      hash = id.to_hash
      begin
        rebuilt = Pubid::Iana::Identifier.from_hash(hash)
        faithful = rebuilt.to_hash == hash && rebuilt.to_s == id.to_s
        record(round_trip_failures, slug) unless faithful
      rescue StandardError => e
        record(round_trip_failures, [slug, e.class.to_s])
      end

      record(empty_keys, slug) if id.root.number.to_s.empty?
    end

    aggregate_failures do
      expect(ids.size).to be > 3000, "index looks truncated: #{ids.size} rows"
      expect(parse_failures).to be_empty,
                                -> { parse_failures.first(10).inspect }
      expect(render_failures).to be_empty,
                                 -> { render_failures.first(10).inspect }
      expect(round_trip_failures).to be_empty,
                                     -> { round_trip_failures.first(10).to_s }
      expect(empty_keys).to be_empty, -> { empty_keys.first(10).inspect }
    end
  end

  it "gives every published id a distinct MR slug" do
    seen = Hash.new { |h, k| h[k] = [] }

    ids.each do |slug|
      id = Pubid::Iana::Identifier.parse(slug)
      seen[id.to_mr_string] << slug
    end

    collisions = seen.reject { |mr, found| mr.empty? || found.size == 1 }
    empty = seen.fetch("", [])

    aggregate_failures do
      expect(empty).to be_empty, -> { empty.first(10).inspect }
      expect(collisions).to be_empty, -> { collisions.first(5).inspect }
    end
  end

  it "narrows usefully: root.number buckets the corpus" do
    buckets = ids.group_by do |slug|
      Pubid::Iana::Identifier.parse(slug).root.number.to_s
    end

    sizes = buckets.values.map(&:size).sort
    largest = sizes.last

    aggregate_failures do
      expect(buckets.keys).not_to include("")
      # The whole point of the key: without it every row shares one bucket.
      expect(buckets.size).to be > (ids.size / 10)
      expect(largest).to be < (ids.size / 10)
    end
  end
end
