# NIST flavor notes

NIST rendering formats and annotated output.

Read this before you change `lib/pubid/nist/` or `spec/pubid/nist/`. The root
`CLAUDE.md` keeps the cross-flavor contract that every flavor obeys.

- **Six NIST types rendered plain under `to_s(annotated: true)`, and two
  more carried a latent corruption.** NIST's `to_s` takes a **positional**
  `format`, which Ruby fills with a Hash when a caller passes `annotated:`;
  `Identifiers::Base#to_s` already handles that and annotates. The six that
  did not — `CommercialStandardsMonthly`, `CrplReport`, `InteragencyReport`,
  `MiscellaneousPublication`, `Monograph`, `Report` — either compose their
  own string or hand `super` a **Symbol**, which drops the flag. Each now
  pulls `annotated` out of the Hash itself and wraps its result.

  **`Circular` and `Handbook` are the interesting half.** Both did
  `result = super` — which annotates — and then rewrote the edition with a
  **`$`-anchored** regex. Once the string ends in `</span>` the anchor
  cannot match, so the rewrite silently stops applying. Both now strip the
  flag before `super`, rewrite, then annotate.

  **An output assertion cannot catch that**, and this is the lesson: for
  both fixture references (`NBS CIRC 11e2-1915`, `NBS HB 44e2-1955`) the
  annotator matches only the leading publisher, so the tail is bare and the
  wrong order still produces the right string. The spec asserts the
  **ordering** instead — it wraps `annotate_plain_render` and checks the
  string handed to it is already rewritten and carries no span — and that
  assertion was verified to fail when the order is reverted.

  `CircularSupplement` and `SupplementIdentifier` were also normalised:
  both had a date-range branch that returned a hand-composed string without
  ever reaching `super`. `SupplementIdentifier` has four exits, so its
  composition moved into a private `render_plain`; **`super` is not
  reachable from a private method**, so `to_s` hands it in as a block —
  `render_plain(format) { super(format) }`.

- **`all_parts_edition_keys` needed `update`/`update_component`, not
  `edition_year`.** `Identifier.all_parts_edition_keys` defaults to
  `%i[date year edition version]`; NIST's primary edition carrier
  (`edition`, a `Components::Edition`) is already covered, but the Letter
  Circular / Circular "rJun1992"-style revision (`Builder` around the
  "Convert revision with month+year to update component" comment) parses
  into a **separate** attribute, `update`/`update_component`
  (`Components::Update`: number+year+month), which the default list
  missed entirely — `"NBS LC 800 rJun1992"` and `"NBS LC 800 rJul1995"`
  failed to collapse under `#to_all_parts`/`#===`. Fixed with
  `Pubid::Nist::Identifier.all_parts_edition_keys` (`super + %i[update
  update_component]`). **`edition_year` and `revision_year`/
  `revision_month` were investigated and are NOT added**: `Builder` only
  ever sets `edition_year` alongside the real `edition` component (never
  as its sole carrier, e.g. the TechnicalNote "date IS edition" branch),
  and `revision_year`/`revision_month` are transient — converted into
  `update`/`update_component` and cleared to `nil` before the object is
  returned. Neither carries live information `edition`/`update` doesn't
  already cover. Locked by `spec/pubid/all_parts_edition_keys_audit_spec.rb`.

- **The URN parser must rebuild the human face the generator started from,
  field for field.** `UrnGenerator` dot-joins identity fields after the
  number (`urn:nist:sp:304.e2017.A.supp`), and `UrnParser#parse_payload`
  splits them back: the edition/volume/revision glue onto the number, a
  single capital-letter token is a **part** glued to the code
  (`304A`), an edition's additional text keeps its dot (`13e2.June1908` —
  the token after `eN`), `insert`/`errata`/`add` markers glue verbatim,
  the bare `.supp` is supplementability (non-identity) and a valued
  `.supp-<v>` is `sup<v>`. The rebuild is only correct if the flavor's own
  grammar accepts it, so every branch is measured against the corpus —
  before this, the five rows with a part letter, an edition additional
  text, or an addendum marker failed to re-parse and the reference's own
  `parse_urn` raised on its own output. The ts mirror must reproduce
  Ruby's `String#split` behaviour and drop **trailing** empty fields
  (`"800-38.A.supp.add."` splits with a trailing `""` in JS but not in
  Ruby; keeping it appends a stray `.`). Locked by
  `spec/pubid/nist/urn_parser_spec.rb`.
