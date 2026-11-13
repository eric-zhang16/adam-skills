# PFS primary censoring rule — source logic

Generalized from `pfs_one()` / `validate_pfs()` in
`references/eik1001-006_analysis.R` section (3) ("PFS validation: BICR and
INV"). Unlike the confirmed-BOR rule, there is no separate reference Word
doc for this one — the R comments in that section ARE the rule
specification; re-read them directly if this summary is ever in doubt.

## What the rule does

Standard oncology PFS primary censoring: the event is disease progression
(PD, by the trial's response assessment) or death. A subject is censored
instead of scored as an event when:

- the apparent PD/death comes **too long after the last adequate
  (non-PD) assessment** — specifically, more than "2 missed scheduled
  assessments" worth of time — so the progression can't be dated reliably
  to within the protocol's assessment schedule; or
- the apparent PD/death happened **after the subject started new
  anti-cancer therapy**, which confounds the assessment.

When censored, the censoring date is backed up to the **last adequate
non-PD assessment before the problem** (not the PD/death date itself) —
except when there is no such assessment at all, in which case censoring
falls back to the randomization date.

## Required inputs (per subject)

- `resp`, `date`: the subject's date-ordered overall-response assessments,
  already restricted to adequate categories only — i.e. `nonpd` values
  (default CR/PR/SD; map NON-CR/NON-PD -> SD first) plus PD. **Drop
  NE/NED rows before calling** — they are inadequate assessments, not valid
  non-PD evidence, per the 2026-10-12 decision also used for confirmed BOR.
- `randdt`: randomization date.
- `dthdt`: death date, or NA.
- `new_therapy_dt`: new anti-cancer therapy start date, or NA. Same
  earlier-of-two-sources convention as the confirmed-BOR rule when a study
  has more than one candidate source date.
- `miss_threshold(event_day)`: a function, **study-specific**, returning
  the maximum allowed number of days between the last adequate non-PD
  assessment and the apparent event before that event converts to
  censoring ("2 missed scheduled assessments"). This is **not** a universal
  constant — it is double the protocol's scheduled assessment interval *in
  force at that point in the trial*, and must be rebuilt per study from
  the actual (or protocol-specified) scan schedule. Never reuse
  EIK1001-006's numbers for a different trial.

### Worked example: EIK1001-006's own miss_threshold

EIK1001-006 scans roughly q9w through Year 1, then q12w thereafter (derived
empirically from `adrs` BICR scan dates in that study). Its threshold
function — **do not copy these day counts into a different study**, derive
new ones the same way:

```r
miss_threshold <- function(event_day) {
  if (event_day <= 365) 18 * 7           # 2 x 9-week interval (pre-Year-1)
  else if (event_day <= 435) (9 + 12) * 7  # gap straddles the schedule change
  else 24 * 7                             # 2 x 12-week interval (post-Year-1)
}
```

To derive a new study's version: find the scheduled (or empirically
observed) inter-assessment interval(s) from the protocol / SAP or from the
actual scan dates in the response dataset, double whichever interval is in
force at the event day for the "normal" windows, and size a straddling
window around any point where the schedule itself changes. If the schedule
never changes, `miss_threshold` is simply `function(event_day) 2 * interval_days`.

## Algorithm (per subject, from `pfs_censor_one()`)

1. **No post-baseline assessment at all**: if death occurred, censor at
   randomization if it happened after new therapy OR later than
   `miss_threshold(0)` days from randomization; otherwise death is the
   event. If no death either, censor at randomization.
2. **An event exists** (PD date and/or death date, whichever is earlier):
   - if new therapy started before the event, censor at the last adequate
     non-PD assessment before new-therapy start (or at randomization if
     none) — new therapy confounds the reading;
   - else if the gap from the last adequate non-PD assessment to the event
     exceeds `miss_threshold(event_day)`, censor at that last adequate
     assessment (the event can't be dated reliably to within schedule);
   - else the event is scored as-is, on its actual date.
3. **No event, but new therapy started**: censor at the last adequate
   non-PD assessment before new-therapy start (or randomization if none).
4. **No event, no new therapy**: censor at the latest adequate non-PD
   assessment date (standard administrative censoring).
