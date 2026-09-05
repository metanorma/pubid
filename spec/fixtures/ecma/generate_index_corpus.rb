# frozen_string_literal: true

# Regenerates spec/fixtures/ecma/identifiers/pass/index_corpus.txt from the
# published relaton-data-ecma index. Run from the repo root:
#
#   ruby spec/fixtures/ecma/generate_index_corpus.rb \
#     /path/to/relaton-data-ecma/index-v1.yaml
#
# ECMA has no `identifiers/full/` corpus, so `rake "validation:classify[ecma]"`
# neither generates nor clobbers these fixtures — this script is how the corpus
# file is refreshed after a new crawl.
#
# Each index row is rendered as "<:id:>[ ed<:ed:>][ vol<:vol:>]", which is
# exactly what `Pubid::Ecma::Identifier#to_s` produces, because the relaton
# index keys on a bare `to_s`. spec/pubid/ecma/corpus_spec.rb then asserts the
# whole file parses, round-trips byte-exactly and keys uniquely on all three
# identity surfaces.
require "yaml"

DEFAULT_SOURCE =
  "/Users/andrej/RubyProjects/ribose/relaton/relaton-data-ecma/index-v1.yaml"

source = ARGV[0] || DEFAULT_SOURCE
rows = YAML.load_file(source, permitted_classes: [Symbol])

lines = rows.map do |row|
  id = row[:id]
  rendered = id[:id].dup
  rendered << " ed#{id[:ed]}" if id[:ed]
  rendered << " vol#{id[:vol]}" if id[:vol]
  rendered
end

raise "the index contains duplicate keys" unless lines.uniq.size == lines.size

destination = "spec/fixtures/ecma/identifiers/pass/index_corpus.txt"
File.open(destination, "w") do |file|
  file.puts "# ECMA — the complete published corpus, byte-exact round-trip."
  file.puts "# Generated from relaton-data-ecma/index-v1.yaml " \
            "(#{rows.size} rows) as"
  file.puts "#   \"<:id:>[ ed<:ed:>][ vol<:vol:>]\"."
  file.puts "# Regenerate with:"
  file.puts "#   ruby spec/fixtures/ecma/generate_index_corpus.rb " \
            "<path to index-v1.yaml>"
  file.puts "# Every line must satisfy parse(line).to_s == line, and the whole"
  file.puts "# file must key uniquely on to_s, to_urn and to_mr_string — see"
  file.puts "# spec/pubid/ecma/corpus_spec.rb."
  file.puts
  lines.each { |line| file.puts line }
end

warn "wrote #{lines.size} identifiers to #{destination}"
