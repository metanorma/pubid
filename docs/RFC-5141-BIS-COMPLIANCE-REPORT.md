# RFC 5141-bis Compliance Report

This document describes PubID's compliance with RFC 5141-bis (URN Namespace for ISO) and related standards.

## Overview

PubID generates and parses URNs that comply with the ISO URN namespace specification defined in RFC 5141-bis. The implementation supports both ISO and IEC identifiers, with extensions for additional flavors.

## URN Namespace

| Namespace | Specification | Status |
|-----------|--------------|--------|
| `urn:iso:std:` | RFC 5141-bis | Fully implemented |
| `urn:iec:std:` | IEC URN scheme | Fully implemented |

## Compliance Requirements

### Met Requirements

| Requirement | Status | Notes |
|------------|--------|-------|
| Publisher identification | Met | Hyphen-separated lowercase copublishers (`iso-iec`, `iso-iec-ieee`) |
| Document type codes | Met | `tr`, `ts`, `pas`, `guide`, `dir`, `dir-sup`, `iwa-sup` |
| Harmonized stage codes | Met | `stage-XX.XX` only, identical to RFC 5141. The typed abbreviations (WD, CD, DIS, DAM, ...) are human-face labels for (deliverable type, stage code) and are never emitted in a URN; legacy abbreviation URNs are accepted on parse as a deprecated ingestion alias and re-canonicalized on render |
| Supplement chain ordering | Met | Multi-level supplements (Amd/Cor) in correct nesting order (Cor wraps Amd wraps Base) |
| Edition specification | Met | `ed-N` format for ISO, `ed.N` for IEC |
| Explicit language codes | Met | Comma-separated language codes (`en`, `en,fr`), always lowercase in URN output |
| Part/subpart numbering | Met | Colon-dash prefix for ISO (`-1`), single hyphenated field for IEC (`60068-2-2`) |
| Version numbering | Met | `vN` = the RFC 5141 `<supplversion>` (published supplements are v1), `vN.M` with the draft iteration |
| Supplement year | Met | `supplyear` slot between the number and the version (`amd:1:2007:v1`); the legacy wire overloaded the number slot with the year and is re-canonicalized on parse |
| Round-trip parsing | Met | ISO and IEC support URN-to-identifier parsing |

### Design Principles

1. **Explicit is better than implicit**: Language codes are always included when present, even for English documents.
2. **Dynamic copublisher combinations**: URNs support any combination of publishers (ISO/IEC/IEEE, ISO/ASTM, etc.) without predefined lists.
3. **Supplement chain semantics**: Supplements are ordered by type, with year and version following RFC 5141-bis conventions.

## Test Coverage

URN generation is tested against real-world identifier databases:

| Flavor | URN Generation | Round-Trip |
|--------|---------------|------------|
| ISO | 90%+ test coverage | Full round-trip |
| IEC | Full coverage | Full round-trip |

### Test Methodology

- ISO URNs are validated against the RFC 5141-bis test vector suite
- IEC URNs follow the same structural conventions
- Round-trip tests verify `parse(to_urn)` produces equivalent identifiers

## Known Limitations

| Limitation | Status | Impact |
|-----------|--------|--------|
| Published stage omitted | By design | Published documents (60.60) don't include stage in URN per RFC |
| Proof stage (60.00) included | Extension | PRF uses 60.00 harmonized code, included in URNs for clarity |
| Non-ISO/IEC URNs | Extension | Other flavors use similar URN structure but are not RFC-defined |
| Stage code evolution | Extension | WDS introduced 2025-06 shares harmonized codes with WD; disambiguation rules apply |
| CDTS no-space variant | Extension | Both `CDTS` and `CD TS` parse correctly; URN uses `CDTS` abbreviation |

## References

- [RFC 5141-bis Specification](../references/iso-urn-specification.adoc) - Full specification with ABNF grammar and gap analysis appendix
- [IEC URN Specification](../references/iec-urn-specification.adoc) - IEC URN model specification
- [URN Generation Guide](URN-GENERATION-GUIDE.adoc) - Usage documentation
- `lib/pubid/iso/urn_generator.rb` - ISO URN generation
- `lib/pubid/iso/urn_parser.rb` - ISO URN parsing
- `lib/pubid/iec/urn_generator.rb` - IEC URN generation
- `lib/pubid/iec/urn_parser.rb` - IEC URN parsing
