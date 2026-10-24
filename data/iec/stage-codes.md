# IEC stage codes — extracted from IEC's own published API documents

This directory's stage-code reference. The authoritative source is IEC's
own documentation of its project-stage vocabulary, committed here as an
extract because the primary document cannot be fetched programmatically.

## Provenance

- **Primary (unreachable):** IEC Data Feeds,
  <https://www.iec.ch/system/files?file=2020-08/IEC_DATA_FEEDS.pdf>
  (19 pages, August 2020). `www.iec.ch` serves an AWS WAF JS challenge to
  non-browser clients and the Wayback Machine holds no snapshot, so the
  bytes could not be retrieved (attempts of 2026-10-21).
- **Used instead — IEC's own successors of Data Feeds**, both fetched
  2026-10-21:
  - *IEC/ISO Harmonized APIs*, v0.0.8, 60 pages, June 2023,
    <https://api-portal.iec.ch/files/APIsLegacyCorrespondence_0_0_8.pdf>
    — section 3 "IEC/ISO Stage Code correspondance" (p. 37–38).
  - *IEC/ISO Harmonized APIs*, v0.0.7, 32 pages, May 2021,
    <https://iec-apiportal.apigee.io/files/APIsLegacyCorrespondence.pdf>
    — same table (p. 31–32); its change log (2021-01-18) introduces the
    "CSV Feeder and IEC/ISO Stage Code correspondence".
  - The 2021 document lists "IEC Data Feeds (<https://www.iec.ch/datafeeds>)"
    among the *legacy feeders* these Harmonized APIs replace, and maps the
    legacy feed's fields (STAGE_CODE, STAGE_CODE_NAME, ISO_LEVEL) onto the
    modern stageCode/harmonizedStageCode pairs.
- **Also held: *Stage Codes — International Standard (IS)*, v2.0, 2023-06**
  (`StageCodes_IS_v2.pdf`, cited by metanorma/pubid-iec#127). The bytes
  are withheld from retrieval by the same WAF; a human-downloaded copy
  is preserved outside the repository. It is the IS-lifecycle flow
  diagram; the abbreviations it defines are transcribed below.
- **Extraction:** `pdftotext -layout`; table transcribed verbatim below,
  including IEC's own spelling of the section title ("correspondance").

## IEC/ISO Stage Code correspondance (section 3, v0.0.8 p.37–38; identical in v0.0.7)

| Harmonized Stage | IEC Stage Code | Meaning | Deliverable |
|---|---|---|---|
| 20.99 | ACD | Approved for CD | IS, TR, TS |
| 30.99 | ACDV | Approved for CDV | IS |
| 40.99 | ADTR | Approved for DTR | TR |
| 40.99 | ADTS | Approved for DTS | TS |
| 40.99 | AFDIS | Approved for FDIS | IS |
| 50.99 | APUB | Approved for publication | IS, TR, TS, PAS, ISH, COR |
| 60.00 | BPUB | Being published | IS, TR, TS, PAS, ISH, COR |
| 30.98 | CAN | Draft Cancelled | IS, TR, TS |
| 50.98 | CAN | Draft Cancelled | PAS, ISH, COR |
| 40.20 | CCDV | Draft circulated as CDV | IS |
| 30.20 | CD | Draft circulated as CD | IS, TR, TS |
| 50.20 | CDISH | Draft circulated as DISH | ISH |
| 30.60 | CDM | CD to be discussed at meeting | IS, TR, TS |
| 50.20 | CDPAS | Draft circulated as DPAS | PAS |
| 50.20 | CDTR | Draft circulated as DTR | TR |
| 50.20 | CDTS | Draft circulated as DTS | TS |
| 40.91 | CDVM | Rejected CDV to be discussed at meeting | IS |
| 50.20 | CFDIS | Draft circulated as FDIS | IS |
| 50.00 | DECDISH | DISH at editing check | ISH |
| 50.00 | DECFDIS | FDIS at editing check | IS |
| 60.00 | DECPUB | Publication at editing check | IS, TR, TS, PAS, COR |
| 10.98 | DEL | Deleted/abandoned | IS, TR, TS |
| 20.98 | DEL | Deleted/abandoned | ISH |
| 99.60 | DELPUB | Deleted publication | IS, TR, TS, PAS, ISH, COR |
| 50.92 | DTRM | Rejected DTR to be discussed at meeting | TR |
| 50.92 | DTSM | Rejected DTS to be discussed at meeting | TS |
| 30.97 | MERGED | Fragment merged | IS, TR, TS, PAS, COR |
| 40.91 | NCDV | CDV rejected | IS |
| 50.92 | NDTR | DTR rejected | TR |
| 50.92 | NDTS | DTS rejected | TS |
| 50.92 | NFDIS | FDIS rejected | IS |
| 30.60 | PCC | Preparation of CC | IS, TR, TS |
| 10.20 | PNW | New work item proposal | IS, TS |
| 60.60 | PPUB | Publication issued | IS, TR, TS, PAS, ISH, COR |
| 40.60 | PRVC | Preparation of RVC | IS |
| 50.60 | PRVD | Preparation of RVD | IS |
| 50.60 | PRVDISH | Preparation of RVDISH | ISH |
| 50.60 | PRVDPAS | Preparation of RVDPAS | PAS |
| 50.60 | PRVDTR | Preparation of RVDTR | TR |
| 50.60 | PRVDTS | Preparation of RVDTS | TS |
| 10.60 | PRVN | Preparation of RVN | IS, TS |
| 00.00 | PWI | Preliminary work item | IS, TR, TS |
| 50.00 | RDISH | DISH received and registered | ISH |
| 50.00 | RFDIS | FDIS received and registered | IS |
| 60.00 | RPUB | Publication received and registered | IS, TR, TS, PAS, COR |
| 30.96 | SPLIT | Project Fragmented | IS, TR, TS, PAS |
| 40.00 | TCDV | Translation of CDV | IS |
| 50.00 | TDISH | Translation of DISH | ISH |
| 50.00 | TDTR | Translation of DTR | TR |
| 50.00 | TDTS | Translation of DTS | TS |
| 60.00 | TPUB | Translation of publication | IS, TR, TS, COR |
| 95.99 | WPUB | Publication withdrawn | IS, TR, TS, PAS, ISH, COR |

The modern API spells the enquiry/FDIS
ladder with the C-prefixed circulation codes (CCDV/CFDIS/RFDIS/NFDIS…)
rather than DIS/FDIS.

## The IS-lifecycle ladder (StageCodes_IS_v2.pdf, v2.0 2023-06)

The IS diagram chains these abbreviations; the intermediate registered
states do not all appear in the correspondence table above:

PRELIMINARY: PWI → PROPOSAL: prePNW ("Preparation of NP"), PNW/NP,
DEL, PRVN, RVN, RR → COMMITTEE: ACD, CD, PCC, CC, CDM →
ENQUIRY: ACDV, TCDV, CCDV, CDV, PRVC, RVC → APPROVAL: CFDIS, FDIS,
DECFDIS, RFDIS, CAN → PUBLICATION: BPUB, PPUB, APUB, RPUB, TPUB →
WPUB, DECPUB, DELPUB.

Notable: the ladder runs through **NP** (not bare "DIS") for the
proposal, and the enquiry/approval drafts are the C-prefixed
circulation codes plus **RVC/RFDIS** — bare "DIS" and "FDIS" appear
only as the delivered drafts, and **ADIS appears nowhere** (it is a
legacy-Data-Feeds-only code; the diagram uses RFDIS at 50.00).
"prePNW", "CC" and "RVN/RVC/RVD" are diagram codes with no
correspondence-table row.

## Legacy IEC Data Feeds stage codes (use-case examples, v0.0.8 p.24–25; v0.0.7 p.18–19)

The documents' legacy-feeds example is the only place a code outside the
table above appears:

| Legacy field | Value | Modern counterpart in the same example |
|---|---|---|
| STAGE_CODE | `ADIS` | stageCode `RFDIS` |
| STAGE_CODE_NAME | "Approved for FDIS circulation" | harmonizedStageCode `50.00` |
| ISO_LEVEL | `40.99` | |

`ADIS` is the legacy Data Feeds spelling of what the modern API calls
`AFDIS` ("Approved for FDIS", harmonized 40.99): same meaning, same
ISO_LEVEL. The example pairs it with the modern project's then-CURRENT
stage RFDIS/50.00 — a snapshot of the project's plan, not a code rename.

## Relationship to the pubid stage registry

- `ADIS` is registered as an alias on the IEC `cdv` typed stage, whose
  harmonized list covers 40.99.
- **Reconciliation (2026-10-22, applied):** `DELPUB`'s code 99.60 is
  claimed by the `is` ladder; `SPLIT`/`MERGED` are claimed at
  30.96/30.97 by the `cd` ladder; `PCC`, `RPUB`, `TPUB`, `DECPUB`,
  `DEL` (10.98 and 20.98) and `PRVN` are registered as typed-stage
  abbreviations; every per-deliverable row — the translation/preparation
  families, `DECDISH`, `PRVDISH`/`PRVDPAS`/`PRVDTR`/`PRVDTS`, `CDTR`/
  `CDTS`/`CDISH`/`CDPAS`, `ADTR`/`ADTS`, `DTRM`/`DTSM`, `NDTR`/`NDTS`,
  `RDISH`, `TCDV`, `PRVC`, `AFDIS`, … — is queryable through
  `Pubid::Iec.locate_stage` via the classes' PROJECT_STAGES;
  `Pubid::Iec.locate_stage_by_harmonized_code` resolves the codes with
  the IS-family preference (the pubid#570 deterministic rule). The
  review/withdrawal ladder rows (90.xx/95.xx) stay claimed: the
  harmonized system is joint ISO/IEC and #237's own list maps RR to
  9092 — IEC's table simply does not name IEC stage codes for the
  review sub-states. Locked by `spec/pubid/iec/stage_reconciliation_spec.rb`.
