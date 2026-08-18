# PubID Scheme Schema (SSOT declarations)

`schema/` holds the single source of truth declarations for every flavor.
Both the Ruby gem (after TODO.restructure/03-07) and pubid-ts (Phase B)
consume these files; neither implementation owns the data.

## Layout

- `schema/schema.schema.yaml` - JSON Schema (draft 2020-12) for one flavor
  declaration.
- `schema/core/joint_prefixes.yaml` - canonical joint/co-publication tokens,
  merged into each participating flavor's prefixes at load.
- `schema/{flavor}.yaml` - one flavor per file (external flavor key; digit-
  leading keys such as `3gpp` are allowed).

## Field reference

See schema.schema.yaml (authoritative). Key semantics:

- `prefixes`: the flavor's OWN leading tokens only. Joint tokens are never
  duplicated here; they come from `schema/core/joint_prefixes.yaml`, which is
  keyed by flavor. This mirrors Pubid::JOINT_PREFIXES symmetry.
- `identifier_types[].abbr` / `typed_stages[].abbr`: every recognized input
  variant, ordered canonical-first.
- `update_codes`: literal-key -> replacement map; keys written as `/regex/`
  are pattern rewrites (same convention as data/{flavor}/update_codes.yaml).
- `render_profiles`, `urn`: populated by TODO.restructure/14 and /15.

## Generation

Declarations are seeded from the live model (no hand transcription):

    bundle exec rake schema:extract          # iso (default)
    bundle exec rake schema:extract[iec]

During TODO.restructure/07 the direction inverts: the classes read these
files instead of carrying the data in code.

## Portability

Data only. Any regex destined for schema/ must stay in the Ruby(Onigmo) and
ECMAScript intersection: no possessive/atomic groups, no \A \z \G \h, no
conditionals, no interpolation. Enforced by TODO.restructure/16.
