# ASME flavor notes

ASME index key and MR slug.

These notes were part of the root `CLAUDE.md`. Read them before you change `lib/pubid/asme/` or `spec/pubid/asme/`. The root file keeps the cross-flavor contract that every flavor obeys.

## From the root note "AMCA / ASME / ASTM index key (`root.number`): three flavors, three different shapes"

**(2) ASME — the whole printed code, not a split.** `Asme::Components::Code` is designator+number, so the IEEE split looks right — but **152 of 731 fixture ids are Boiler and Pressure Vessel Code documents whose entire identity IS the designator** (`BPVC COMPLETE CODE BIND`, `BPVC.CC.BPV`) with no numeric part at all; splitting leaves every one of them keyed `""`. So `number` holds the whole code (`"B18.3"`), declared on the leaf `Identifiers::Standard`. **`Asme::Components::Code` is now unused on the identifier path and there is no `#code` reader**: an earlier draft composed one so the renderer and URN generator would not have to change, but since `number` already holds the whole code that Code never carried a designator and `code.to_s` equalled `number` for all 731 ids — a string wrapped in an object whose only job was to unwrap to the same string. Both readers use `number` directly. **Contrast ASTM, which keeps its composed `#code`**: its renderer reads `code.letter`/`code.dual_m` field-by-field, so there the component carries real structure. The test for whether a derived `#code` earns its place is whether any caller reads a *field* of it rather than just `to_s`.
