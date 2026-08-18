# PubID Conformance Corpus

`conformance/` is the language-independent test library. Inputs are the
entire ground-truth fixture library (every line, nothing sampled); the
component tree and representations are recorded from the reference
implementation. A second implementation (pubid-ts) must rebuild each
identifier from the tree and reproduce every representation.

## Case format (v2, conformance/corpus.schema.yaml)

    - id: iso.amendment.0001
      input: "ISO 9001:2015/Amd 1:2020"
      identifier:            # semantic component tree
        type: amendment      # identifier_types[].key from schema/{flavor}.yaml
        components: {number: "9001", year: "2015", publisher: ISO}
        base: {type: international_standard, components: {...}}
      representations:       # every proper output format
        human: "ISO 9001:2015/Amd 1:2020"
        urn: "urn:iso:std:iso:9001:amd:2020:v1"
      roundtrip: true

The corpus is pure YAML: component objects that leak through serialization
are reduced to their string rendering; no language-specific tags exist.

## Files

- `conformance/{flavor}/{type}.yml` - positive cases, one file per
  identifier type, ids `{flavor}.{type}.{seq}` (stable, never renumbered).
- `conformance/{flavor}/_unparsed.yml` - VISIBLE DEBT: ground-truth pass
  fixtures the reference cannot parse, with the error class and message.
  Never treated as expected-failure contract; fix and regenerate.
- `conformance/{flavor}/_negative.yml` - fail fixtures (expected errors).

## Gates (per case)

1. parse(input) rebuilds the recorded component tree.
2. parse(input) reproduces every recorded representation byte-exactly.
3. from_hash(to_hash) round-trips where roundtrip is true.

## Tooling

    bundle exec rake conformance:generate[iso]  # migrate fixtures to corpus
    bundle exec rake conformance:run            # execute corpus, exit on fail

Regeneration is deterministic on unchanged code. Regeneration diffs are
reviewed in PRs. spec/pubid/conformance_corpus_spec.rb runs the same cases
inside the default test suite.

## Current size (2026-08-18)

iso: 7,511 cases + 62 debt; iec: 12,299 cases + 4 debt; failures: 0.
