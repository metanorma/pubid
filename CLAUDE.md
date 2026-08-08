# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PubID is a Ruby gem monorepo containing 13 interdependent gems for creating interoperable identifiers for standards documents (ISO, IEC, NIST, IEEE, etc.). All gems share synchronized versioning.

## Common Commands

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rake test:all

# Run integration tests (cross-gem)
bundle exec rake test:integration

# Run tests for a specific gem (use underscore: pubid_core not pubid-core)
bundle exec rake test:pubid_core
bundle exec rake test:pubid_iso

# Run all quality checks (tests + rubocop)
bundle exec rake

# Lint all code
bundle exec rake rubocop:all

# Build all gems
bundle exec rake build:all

# Version management
bundle exec rake version:show       # Show master version
bundle exec rake version:check      # Verify all gems synchronized
bundle exec rake version:sync       # Sync master version to all gems
```

## Architecture

### Dependency Hierarchy

```
pubid-core          # Foundation - all other gems depend on this
    ├── pubid-iso   # ISO identifiers
    │   └── pubid-ieee
    ├── pubid-iec
    ├── pubid-nist
    ├── pubid-cen   # depends on iso, iec, core
    ├── pubid-bsi   # depends on cen, nist, iso, iec, core
    ├── pubid-etsi
    ├── pubid-itu
    ├── pubid-jis
    ├── pubid-ccsds
    └── pubid-plateau
pubid               # Meta-gem that bundles common gems (released last)
```

### Key Patterns

- **Parslet PEG parsers**: Each gem uses `parslet` for identifier parsing (`parser.rb`)
- **Transformers**: AST transformation via `transformer.rb`
- **Identifier models**: Core `Identifier` class extended by each standards org
- **Renderers**: Output formatting in `renderer/` directories (base, URN formats). Supports `annotated: true` option in `to_s` to wrap semantic components in `<span>` tags with CSS classes (defined in `Pubid::Core::Renderer::Base::SEMANTIC_CLASSES`).

### IEC URN canonical form (`gems/pubid-iec`)

`Pubid::Iec::Identifier#urn` emits, and `.parse` accepts, the ABNF-canonical
IEC URN used as ground truth by `relaton-data-iec`:

```
urn:iec:std:{pub}[-{copub}][:{type}]:{number}[-{part}][,{conj}]
    :{date}:{stage}:{deliverable}:{language}{adjuncts}[{fragment}]
```

The four positional slots after the number/part are always colon-separated
even when empty (plain doc → `...:2007:::`). `{deliverable}` holds `csv`/`rlv`/
`cmv`/`exv`/`ser` (or the `ed-N` edition when no deliverable — the two never
co-occur). Amendments/corrigenda follow the language slot with a relation-
marker: `::` normally, `:plus:` for an amendment **merged into a consolidation**
(CSV/CMV deliverable). Corrigenda are always `::`. Order is `amd:{num}:{date}`
(number then date), e.g. `...:1999:::::amd:1:2003` and
`...:2010::csv::plus:amd:1:2021`. Because the parser discards the `+`/`/`
supplement join, the `:plus:` marker is **inferred** from the deliverable in
`Renderer::Urn#render_amendments` — do not expect a stored consolidation flag.
Deferred (also unsupported before): typed docs with the type in the canonical
after-date slot (`...:tr:csv:...`), ISH adjuncts, and the `ca` publisher.

**Bare-series exception to the always-colon rule:** a bare (undated,
language-less, adjunct-less) all-parts series drops the trailing empty language
slot — `urn:iec:std:iec:80000:::ser`, *not* `...:ser:` — matching the
relaton-data-iec ground truth. A **dated** series keeps it
(`urn:iec:std:iec:60034:2026::ser:`), as does any deliverable
(`...:2017::rlv:`). `Renderer::Urn#bare_series?` gates this on the rendered
deliverable value (`"ser"`), so it holds whether the series is carried as an
`all_parts` flag or a `ser` vap.

### Version Synchronization

Master version lives in `lib/pubid/version.rb`. All gem versions and inter-gem dependencies use exact version matching and must stay synchronized. Use `rake version:bump[patch|minor|major]` to update all gems atomically.

### Individual Gem Structure

Each gem in `gems/` follows:
```
gems/pubid-{name}/
├── lib/pubid/{name}/
│   ├── parser.rb
│   ├── identifier.rb
│   ├── transformer.rb
│   └── version.rb
├── spec/
├── pubid-{name}.gemspec
└── Rakefile
```

## Testing Notes

- RSpec with `--format documentation`
- Integration tests in root `spec/integration/` verify cross-gem compatibility
- Rake task names use underscore (`pubid_core`) not hyphen (`pubid-core`)
