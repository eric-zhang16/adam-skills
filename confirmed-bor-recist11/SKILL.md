---
name: confirmed-bor-recist11
description: Derive confirmed Best Overall Response (BOR) per RECIST 1.1's 13-rule confirmation algorithm (CR/PR confirmation windows, SD/NE/PD resolution, new-anti-cancer-therapy and post-PD exclusions). Use this whenever the user wants to independently re-derive or QC confirmed BOR / CBOR against a vendor or programmed value (e.g. ADaM adeffsum), apply the RECIST 1.1 confirmation rules to a new oncology trial's response assessment data from scratch, or just wants a worked explanation of how a specific sequence of CR/PR/SD/PD/NE assessments confirms to a BOR. Trigger on mentions of "confirmed BOR", "confirmed best overall response", "CBOR", "RECIST 1.1 confirmation", "best overall response rules", or a pasted/described sequence of tumor response assessments asking what the confirmed response or BOR is.
---

# Confirmed Best Overall Response (RECIST 1.1)

This skill derives, per subject, the **confirmed value of each overall-response
assessment** and the subject's **confirmed Best Overall Response (BOR)** and
its date, following the 13-rule algorithm in
`references/recist11_cbor_rules.md`. That file is the full rule text plus the
EIK1001-006 interpretation defaults (category mapping, BOR tie-break, new-therapy
date source) — read it before doing anything else; everything below assumes
you already have.

The actual confirmation algorithm is bundled as a working, tested R engine in
`scripts/confirm_bor.R` (`confirm_assessments()` for per-assessment confirmation,
`subject_bor()` for the subject-level Note 1/Note 2 + rank-and-pick BOR). **Use
that engine — do not re-derive the rule logic by hand or reimplement it from
the rule text.** It has already been validated rule-by-rule. What you write
fresh each time is the thin glue around it: reading the actual source data,
mapping its response codes onto CR/PR/SD/PD/NE, and looping over subjects.

## Three ways this gets used

### 1. Independent QC re-derivation (most common)

The user has a programmed/vendor confirmed BOR (e.g. ADaM `adeffsum` CBOR)
and wants an independent check. Work like section (11) of
`references/eik1001-006_analysis.R` (read it for the full worked pattern):

1. Read the raw overall-response assessments (e.g. ADaM `adrs`,
   `PARAMCD == "OVRLRESP"`, `ANL01FL == "Y"` — ask if the flag/filter
   convention differs for this study) and the comparator (e.g. `adeffsum`,
   `PARAMCD == "CBOR"`).
2. Map response codes per the defaults in the reference doc (`NON-CR/NON-PD`
   -> `SD`, `NED` -> `NE`) unless told otherwise for this study.
3. Resolve the new-anti-cancer-therapy date per subject (earlier of the two
   sources if both exist, per the default) and the treatment start date.
4. Split by subject, call `subject_bor()` per subject using `scripts/confirm_bor.R`.
5. Join derived vs. comparator by subject; report counts matching/differing,
   and list every discrepancy with the full assessment sequence
   (`raw_sequence` from `subject_bor()`'s return) so the user can see *why*
   two sources disagree, not just that they do.
6. State which interpretation defaults you applied, since a real mismatch
   is often a legitimate difference in interpretation decisions rather than
   a derivation bug — flag that possibility rather than assuming the
   comparator is wrong.

### 2. New-trial derivation from scratch

No comparator yet — this derivation is the primary analysis. Same steps 1-4
above (minus the join/compare), but spend more time up front confirming with
the user: which column/dataset holds raw response, what the new-anti-cancer-
therapy source is for this study (there may be only one candidate date, not
two), and whether the default category mapping and CR>PR BOR tie-break still
apply (they're defaults, not universal law — ask if this looks like an
unusual case, e.g. a trial with its own documented RECIST variant).

### 3. Teaching / explaining the rule on a hypothetical sequence

The user describes or pastes a short sequence of assessments (dates +
CR/PR/SD/PD/NE) and wants to know what each confirms to, or what the BOR is,
typically for discussion or documentation rather than a dataset. Still use
`scripts/confirm_bor.R` rather than reasoning it out manually — run it on
the sequence and then **walk through which rule (1-13) fired for each
assessment and why**, citing the rule number, since the point of this mode
is understanding the mechanism, not just the final answer.

## Common pitfalls (from the reference implementation's own audit notes)

- **Each assessment confirms independently**, based only on what comes
  *after it* in time — not shared with neighboring assessments. A sequence
  like `CR, CR` does NOT confirm both as CR: the first CR is confirmed by
  the second (rule 1), but the second CR, having no further CR after it, is
  itself unconfirmed (falls to rule 3 -> NE, if not late and no next
  assessment). This trips people up when sanity-checking by eye.
  Confirmed BOR compares across time, per-record.
- Rules 2/6's "or" is inclusive: late (>=42 days from TRTSDT) by itself is
  enough for SD, regardless of what the next assessment is.
  Rules 2/6 and 10's "next assessment" condition only matters when the
  assessment is NOT already late.
- **BOR date** is the date of the *first* assessment at the best confirmed
  level — not the date confirmation was established. A confirmed CR's BOR
  date is the CR's own assessment date, not the later confirming CR's date.
- Don't forget Note 1 (drop assessments on/after new therapy) and Note 2
  (drop everything after the first PD, keep the PD) run BEFORE confirmation,
  not after — they change which assessment is "next" for confirmation
  purposes.
