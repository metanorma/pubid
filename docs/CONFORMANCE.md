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

See docs and _unparsed/_negative tallies per flavor; run rake conformance:run.

## Styling versions and normalization aliases

Every case and alias carries a `style` (v1 = legacy "ISO/R 2533/3-1975",
v2 = classic dotted/uppercase "ISO 9001:2001/AMD.1:2010", v3 = modern
"ISO 9001:2001/Amd 1:2010"). Fixture lines that normalize to the same
identifier collapse into one canonical v-entry with the old spellings
recorded as `non_normalized_aliases` ({input, style}) - the corpus thus
encodes "old => normalized", and the normalized form is what round-trips.
Exact duplicate fixture lines are counted (duplicates), not silently
absorbed. Fail-fixture lines that the current parser unexpectedly accepts
are recorded as reclassify debt, not hidden.


## Reconciliation semantics

Canonical inputs are the normalized human rendering and may be synthesized
(phantom): when no fixture line spells the normalized form, the case input
is the normalized form and every fixture spelling is an alias. Exact
duplicate lines are counted. Cases whose parse is nondeterministic in the
reference implementation (order-dependent; e.g. bundled directive
supplements) are quarantined with notes and excluded from gates until the
reference bug is fixed.
