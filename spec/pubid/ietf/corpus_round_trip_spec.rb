# frozen_string_literal: true

require "spec_helper"

# Corpus-scale round-trip validation for the unified IETF index. OPT-IN:
#
#   PUBID_IETF_CORPUS=/path/to/checkouts bundle exec rake test:corpus_ietf
#
# PUBID_IETF_CORPUS points at a directory holding local checkouts of
# relaton-data-rfcs, relaton-data-rfcsubseries and relaton-data-ids (branch v2),
# each with its index-v1.yaml. Without it every example self-skips, so the
# default suite pays nothing.
#
# Why it exists: relaton's Relaton::Index::FileIO#id_supported? SKIPS its
# to_hash/from_hash validation whenever the deserialized object is a concrete
# subclass (`return true unless obj.instance_of?(@pubid_class)`), and EVERY
# Pubid::Ietf id is a subclass (Rfc/Bcp/Std/Fyi/InternetDraft). So no IETF
# row is ever round-trip checked downstream: a lossy to_hash would pass
# relaton's validation silently and produce wrong lookups — no error, no
# warning. pubid has to catch it, and only a corpus-scale run can.
#
# The four things checked per id are exactly what the index depends on:
#   1. it parses at all              (FileIO#deserialize_id raises on the first
#                                     failure and rejects the WHOLE index)
#   2. to_s is byte-exact            (the id relaton stores and prints back)
#   3. from_hash(to_hash) is faithful in both to_s and to_hash
#                                    (precisely the check relaton skips)
#   4. root.number is non-empty      (the key Relaton::Index bsearches on;
#                                     empty silently degrades to a linear scan)
#
# Ids are read with a line scan rather than YAML.load — the ids index is ~16 MB
# / 166,740 rows. Expect roughly 1-3 minutes for the full run.
module IetfCorpusSpec
  ROOT = ENV.fetch("PUBID_IETF_CORPUS", nil)
  REPOS = %w[
    relaton-data-rfcs
    relaton-data-rfcsubseries
    relaton-data-ids
  ].freeze
  # Cap the collected failures so a pathological run cannot exhaust memory.
  MAX_FAILURES = 500

  def self.index_path(repo)
    ROOT && File.join(ROOT, repo, "index-v1.yaml")
  end

  # Line scan rather than YAML.load: the ids index is ~16 MB / 166,740 rows.
  # This assumes plain (or wholly-quoted) scalars — verified true for all
  # 176,862 published ids, and the `- :id: ` line count matches the `:file:`
  # count exactly in each index, so nothing is skipped.
  def self.each_id(path)
    return to_enum(:each_id, path) unless block_given?

    File.foreach(path) do |line|
      next unless line.start_with?("- :id: ")

      yield line[7..].strip.sub(/\A(["'])(.*)\1\z/, '\2')
    end
  end
end

RSpec.describe "Pubid::Ietf corpus round-trip" do
  IetfCorpusSpec::REPOS.each do |repo|
    it "round-trips every published id in #{repo}" do
      path = IetfCorpusSpec.index_path(repo)
      unless path && File.exist?(path)
        skip "set PUBID_IETF_CORPUS to a directory containing #{repo}"
      end

      failures = []
      total = 0

      IetfCorpusSpec.each_id(path) do |id|
        total += 1
        begin
          parsed = Pubid::Ietf::Identifier.parse(id)
          hash = parsed.to_hash
          rebuilt = Pubid::Ietf::Identifier.from_hash(hash)

          failures << [id, :render, parsed.to_s] unless parsed.to_s == id
          failures << [id, :rebuild, rebuilt.to_s] unless rebuilt.to_s == id
          unless rebuilt.to_hash == hash
            failures << [id, :hash, rebuilt.to_hash]
          end
          failures << [id, :index_key, hash] if parsed.root.number.to_s.empty?
        rescue StandardError => e
          failures << [id, :error, "#{e.class}: #{e.message}"]
        end

        break if failures.size > IetfCorpusSpec::MAX_FAILURES
      end

      expect(total).to be_positive
      expect(failures).to be_empty, lambda {
        "#{failures.size} failures in #{total} ids. First 20:\n" +
          failures.first(20).map(&:inspect).join("\n")
      }
    end
  end
end
