# Confirmed Best Overall Response (RECIST 1.1) — source rules

Verbatim from `references/Confirmed Best of Response Recisit1.1.docx` (the
project's source document — re-read that file directly if this copy is ever
in doubt).

1. A CR is confirmed as CR if a) there is no PD before the next CR
   assessment, and b) there is an interval >= 28 days between the CR and the
   next CR assessment dates.
2. A CR is confirmed as SD if a) step 1 was not confirmed, b) the CR was
   observed >= 42 days away from treatment start date, or the next
   assessment is not PD or NE.
3. A CR is confirmed as NE if a) steps 1 and 2 were not confirmed, and b)
   the next assessment after the CR is NE or there is no assessment after
   the CR.
4. A CR is confirmed as PD if a) steps 1–3 were not confirmed, and b) the
   next assessment is PD.
5. A PR is confirmed as PR if a) there is no PD before the next CR/PR
   assessment, and b) there is an interval >= 28 days between the PR and
   the next CR/PR assessment dates.
6. A PR is confirmed as SD if a) step 5 was not confirmed, b) the PR was
   observed >= 42 days away from treatment start date, or the next
   assessment is not PD or NE.
7. A PR is confirmed as NE if a) steps 5 and 6 were not confirmed, and b)
   the next assessment after the PR is NE or there is no assessment after
   the PR.
8. A PR is confirmed as PD if a) steps 5–7 were not confirmed, and b) the
   next assessment is PD.
9. An SD is confirmed as SD if the SD was observed >= 42 days away from
   treatment start date.
10. An SD is confirmed as NE if a) step 9 was not confirmed, and b) the
    next assessment after the SD is not PD.
11. An SD is confirmed as PD if a) steps 9 and 10 were not confirmed, and
    the next assessment is PD.
12. A PD is confirmed as PD in any situation.
13. An NE is confirmed as NE in any situation.

After all individual assessments are evaluated, the subject's best overall
response (BOR) is the first record with the best confirmed response, in
order **CR = PR > SD > PD > NE**, and its date is the BOR date.

**Note 1:** Only assessments *before* the start of new anti-cancer therapy
are included in the confirmation evaluation.

**Note 2:** Any CR/PR/SD/NE after the first PD is excluded from the best
overall response evaluation (the first PD itself is kept).

## Defaults baked in from EIK1001-006 (apply unless the user says otherwise)

These are interpretation decisions made when this rule was first programmed
in `references/eik1001-006_analysis.R` (section 11), not part of the literal
doc above. Apply them by default for a new study; call them out explicitly
if you do, so the user can override per-study.

- **Category mapping before confirmation**: `NON-CR/NON-PD` -> `SD`;
  `NED` -> `NE` (NED/NE are treated as inadequate assessments, decided
  2026-10-12 — see the PFS rule doc for the same mapping).
- **BOR order is strictly CR > PR > SD > PD > NE**, not the doc's literal
  "CR = PR" tie-break (decided 2026-10-13). A PR later confirmed, then
  upgraded by a subsequent confirmed CR, gives BOR = CR even if the
  confirmed PR occurred earlier in time — take the *first* assessment at
  whichever level is numerically highest, not just the first assessment to
  reach *a* best level. This matches vendor-derived CBOR in practice.
- **New anti-cancer therapy date (Note 1)** = the earlier of two sources
  when both exist: the dedicated new-anti-cancer-therapy-start dataset
  (e.g. ADaM `adintev`, `PARAMCD == "NACTI"`, earliest `ADT`) and the
  subject-level new-treatment-start date (e.g. ADaM `adsl.NCTXSDT`). If one
  source is unavailable in a given data snapshot, fall back to the other
  alone and say so.
- Comparison universe for QC re-derivation is ITT; a subject with no usable
  post-baseline assessment derives to `"No assessment"`, which should match
  a reference dataset's missing/absent CBOR record for that subject.
