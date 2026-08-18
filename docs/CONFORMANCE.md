# PubID Conformance Corpus

`conformance/` is the shared behavioral contract: the same cases run under
rspec (Ruby, TODO.restructure/11) and vitest (pubid-ts, TODO.restructure/28).
A case file is a YAML array of case objects; the authoritative shape is
`conformance/corpus.schema.yaml`.

## Gates (all must hold unless the case says otherwise)

1. `parse(input).to_s` is byte-exact with `expect.to_s`.
2. `parse(input).to_hash` deep-equals `expect.to_hash` (canonical no-defaults
   form; key order-insensitive compare, TODO.restructure/13 contract).
3. `from_hash(to_hash)` round-trips: `from_hash(parse(input).to_hash).to_hash
   == parse(input).to_hash`.
4. `to_urn`, when declared, must round-trip through `parse_urn` where the
   flavor supports URN parsing.
5. `expect.error.class_name` cases assert the raised error class (message via
   optional `message_pattern`).

## Layout and provenance

- `conformance/{flavor}/*.yml` - one or more files per flavor; ids are stable
  (`{flavor}.{type}.{seq}`).
- Seed cases are hand-verified anchors recorded from the reference
  implementation. Bulk generation arrives with TODO.restructure/10:
  every regeneration diff is reviewed, each identifier type keeps at least
  one hand-verified anchor, negative cases are curated by hand.

## IDs

Stable forever once committed. Never renumber; retire a case by deleting it
with a rationale in the PR description, not by editing its expectations.
