# ASTM flavor notes

ASTM index key and MR slug.

These notes were part of the root `CLAUDE.md`. Read them before you change `lib/pubid/astm/` or `spec/pubid/astm/`. The root file keeps the cross-flavor contract that every flavor obeys.

## From the root note "AMCA / ASME / ASTM index key (`root.number`): three flavors, three different shapes"

**(3) ASTM — the mixin, on EVERY concrete class.** `Astm::Components::Code` is a five-field taxonomy (`letter`/`number`/`suffix`/`subseries`/`dual_m`) that the renderer reads field-by-field, so it keeps its structure: `Identifiers::CodeNumber` installs the five columns plus a derived `#code`. **It is included by `Standard` AND by `IsoDualPublished`, which inherits `Standard` — deliberately, not redundantly**: a class that is itself inherited from must still declare the columns so its subclass holds its own snapshot rather than relying on a parent table. `Adjunct` has no code at all, so its designation IS its number: the `designation` attribute was **removed** and the value stored in `number` directly, because keeping both made `to_hash` emit the same string twice and a `def number` shadowing the attribute is the construct CLAUDE.md forbids.
