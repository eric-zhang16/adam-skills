---
name: pfs-censoring-recist
description: Derive Progression-Free Survival (PFS) primary censoring status per RECIST-based oncology trial rules — event (PD/death) vs. censoring for missed scheduled assessments ("2 missed scans") and new anti-cancer therapy, with censoring backed up to the last adequate non-PD assessment. Use this whenever the user wants to independently re-derive or QC a PFS AVAL/CNSR against a programmed value (e.g. ADaM adtte), apply PFS censoring rules to a new oncology trial's response assessment data from scratch, or wants an explanation of why a specific subject's PFS event got censored instead of counted (or vice versa). Trigger on "PFS censoring", "PFS AVAL/CNSR", "2 missed scans", "progression-free survival derivation", "censor at new anti-cancer therapy", or a pasted/described timeline of scan results and therapy/death dates asking whether PFS should be an event or censored.
---

# PFS Primary Censoring (RECIST-based)

Derives, per subject, whether the apparent PFS outcome (progression or
death) should be scored as an **event** or **censored**, and the
corresponding date (AVAL-equivalent) and censoring flag (CNSR-equivalent:
0 = event, 1 = censored). Full rule write-up, required inputs, and a worked
`miss_threshold()` example are in `references/pfs_censoring_rules.md` —
read it first; it also explains why the "2 missed scans" window is
study-specific and must never be copied from one trial to another.

The algorithm itself is bundled as a tested R function,
`pfs_censor_one()`, in `scripts/pfs_censor.R`. **Use it — don't re-derive
the branch logic by hand.** What you write fresh each time is: the glue
code reading the actual source data and mapping it to the function's
inputs, and — the one genuinely per-study piece — the `miss_threshold()`
function itself, built from that trial's actual assessment schedule.

## Before anything else: get the schedule

This rule cannot be applied correctly without knowing the trial's scheduled
(or empirically observed) tumor-assessment interval(s), because the missed-
scans window is double that interval. Ask, or derive it empirically from the
response dataset (gaps between consecutive scheduled assessments for
subjects with many assessments), whether:

- there's a single constant interval throughout, or
- the interval changes at some point (e.g. more frequent scans early,
  less frequent later) — if so, you need the day the schedule changes and
  how to size a straddling window for gaps that span the change (see the
  worked EIK1001-006 example in the reference doc for the pattern, not the
  specific numbers).

Do not guess or default to EIK1001-006's 9-week/12-week/365-day numbers for
a different trial.

## Three ways this gets used

### 1. Independent QC re-derivation (most common)

The user has a programmed PFS AVAL/CNSR (e.g. ADaM `adtte`,
`PARAMCD == "PFS"`) and wants an independent check. Work like section (3)
of `references/eik1001-006_analysis.R` (read it for the full worked
pattern, including how it sources new-anti-cancer-therapy dates from two
possible datasets):

1. Read the raw overall-response assessments per subject, restricted to
   adequate categories (`nonpd` values + PD; drop NE/NED first) and the
   comparator time-to-event record.
2. Resolve `randdt`, `dthdt`, and `new_therapy_dt` per subject (earlier of
   two sources if both exist, matching the confirmed-BOR rule's default).
3. Build this trial's `miss_threshold()` (see above).
4. Split by subject, call `pfs_censor_one()` per subject.
5. Convert the function's date/cnsr output to whatever AVAL convention the
   comparator uses (e.g. `AVAL = date - randdt + 1`) before comparing.
6. Join and report matches/discrepancies with enough detail (assessment
   sequence, which branch of the algorithm fired) that the user can see
   *why* two sources disagree. A mismatch is often a legitimately different
   new-therapy-date source or missed-scan window, not necessarily a bug —
   say so rather than assuming the comparator is wrong.

### 2. New-trial derivation from scratch

No comparator yet. Same steps 1-4 above. Spend the most effort getting the
`miss_threshold()` schedule right (see above) and confirming the new-
anti-cancer-therapy date source(s) for this specific study, since those are
the two genuinely study-specific inputs; the branch logic itself is fixed.

### 3. Teaching / explaining a specific subject's outcome

The user describes a hypothetical or real subject's timeline (assessment
dates + results, randomization/death/new-therapy dates) and wants to know
whether PFS is an event or censored, and why. Run `pfs_censor_one()` on it,
then walk through which of the four branches
(no-assessment / event-exists / no-event-with-therapy / administrative)
applied and, if censored, whether it was for the missed-scans reason or the
new-therapy reason — these have different clinical implications and the
user will usually want to know which one it was, not just the cnsr flag.

## Common pitfalls

- **The censoring date is backed up to the last adequate non-PD
  assessment**, not the PD/death date, in every censoring case except "no
  assessment + death too early/too late" (where it backs up all the way to
  randomization) and "no assessment, no death" (also randomization). Don't
  report a censored subject's "event date" as the apparent PD date.
- **New therapy wins over the missed-scans check when both could apply**:
  if the event is after new therapy, the new-therapy exclusion fires
  regardless of whether the gap would also have exceeded the missed-scans
  threshold.
- The missed-scans gap is measured from the **last adequate non-PD
  assessment before the event**, not from randomization and not from the
  immediately preceding assessment if that one was PD-adjacent/excluded.
- `miss_threshold(event_day)` is evaluated at the **event's day from
  randomization**, except in the "no post-baseline assessment" branch,
  where it's evaluated at day 0 (there's no assessment yet to measure from,
  so the earliest applicable window always governs).
