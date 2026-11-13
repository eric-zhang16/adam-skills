# PFS Censoring (RECIST-based) Skill

A Claude Code skill for deriving **PFS primary censoring status**
(event vs. censored, and the corresponding date) for oncology trials,
generalized from `eric-zhang16`'s EIK1001-006 analysis script
(`pfs_one()` / `validate_pfs()`, section 3 of
`references/eik1001-006_analysis.R`).

## What it does

Given a subject's randomization/death/new-anti-cancer-therapy dates and
date-ordered adequate tumor-response assessments (CR/PR/SD/PD), derives
whether the apparent PFS outcome is an event (PD or death) or should be
censored because:

- it comes too long after the last adequate non-PD assessment ("2 missed
  scheduled assessments" — a study-specific window, double the trial's
  scan interval), or
- it comes after the subject started new anti-cancer therapy.

Used for: independent QC re-derivation against a programmed PFS AVAL/CNSR
(e.g. ADaM `adtte`), deriving PFS censoring for a new trial from scratch, or
explaining why a specific subject's PFS was censored instead of scored as
an event.

## Skill File Reference

| File | Purpose |
|------|---------|
| `SKILL.md` | Entry point — the three usage modes, how to size the study's own missed-scans window, and common pitfalls |
| `references/pfs_censoring_rules.md` | The full rule write-up and a worked (non-reusable) `miss_threshold()` example |
| `scripts/pfs_censor.R` | The tested derivation engine (`pfs_censor_one()`) |

## Usage

Describe the task naturally, e.g.:

> "Can you independently re-derive BICR PFS censoring for EIK1002 from adrs
> and compare it to adtte? Scans are q8w for the first year, then q12w."

or describe a single subject's timeline and ask whether PFS should be
censored.

## Requirements

Base R only (no packages beyond what the user's own data-reading code needs,
e.g. `haven` for SAS datasets).
