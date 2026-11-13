# Confirmed BOR (RECIST 1.1) Skill

A Claude Code skill for deriving **confirmed Best Overall Response (BOR)**
per RECIST 1.1's 13-rule confirmation algorithm, generalized from
`eric-zhang16`'s EIK1001-006 analysis scripts and the project's source rule
document (`references/Confirmed Best of Response Recisit1.1.docx`).

## What it does

Given a subject's date-ordered sequence of overall-response assessments
(CR/PR/SD/PD/NE), derives:

1. the **confirmed value** of each individual assessment (rules 1-13), and
2. the subject's **confirmed BOR** and its date (first assessment at the
   best confirmed level, CR > PR > SD > PD > NE), after excluding
   assessments on/after new anti-cancer therapy (Note 1) and anything after
   the first PD (Note 2).

Used for: independent QC re-derivation against a programmed/vendor CBOR
(e.g. ADaM `adeffsum`), deriving confirmed BOR for a new trial from
scratch, or walking through the rule mechanics on a hypothetical sequence.

## Skill File Reference

| File | Purpose |
|------|---------|
| `SKILL.md` | Entry point — the three usage modes and common pitfalls |
| `references/recist11_cbor_rules.md` | Verbatim rules 1-13 + Notes 1-2, plus the EIK1001-006 interpretation defaults |
| `scripts/confirm_bor.R` | The tested derivation engine (`confirm_assessments()`, `subject_bor()`) |

## Usage

Describe the task naturally, e.g.:

> "I have adrs OVRLRESP and adeffsum CBOR for EIK1002 — can you independently
> re-derive confirmed BOR for the BICR assessor and flag any discrepancies?"

or just paste a short assessment timeline and ask what the confirmed BOR is.

## Requirements

Base R only (no packages beyond what the user's own data-reading code needs,
e.g. `haven` for SAS datasets).
