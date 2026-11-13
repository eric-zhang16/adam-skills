# Worked example: multi-subject glue code

This is the pattern to adapt per dataset (column names, category mapping,
and new-therapy source will differ by study) — not a script to run as-is.
It mirrors `derive_cbor()` in `eik1001-006_analysis.R` section (11).

```r
source("scripts/confirm_bor.R")   # confirm_assessments(), subject_bor()

# `assess`: one row per subject per assessment date, already filtered to
#           PARAMCD == "OVRLRESP" and whatever ANL01FL/flag convention
#           applies for this study.
# `subj`:   one row per subject, with TRTSDT and the resolved new-therapy
#           date (NEW_THERAPY, NA if none/not yet reached).

assess <- assess %>%
  mutate(RESP = case_when(AVALC == "NON-CR/NON-PD" ~ "SD",
                           AVALC == "NED"           ~ "NE",
                           TRUE                      ~ AVALC)) %>%
  arrange(USUBJID, ADT)

by_subj <- split(assess, assess$USUBJID)

derived <- lapply(seq_len(nrow(subj)), function(i) {
  s <- subj[i, ]
  r <- by_subj[[s$USUBJID]]
  if (is.null(r)) {
    return(tibble(USUBJID = s$USUBJID, BOR = "No assessment", BOR_DT = as.Date(NA)))
  }
  out <- subject_bor(r$RESP, r$ADT, s$TRTSDT, s$NEW_THERAPY)
  tibble(USUBJID = s$USUBJID, BOR = out$bor, BOR_DT = out$bor_date,
         SEQ = out$raw_sequence)
}) %>% bind_rows()
```

## Worked individual case (for teaching mode)

Subject timeline, treatment start day 0:

| Day | Assessment |
|-----|------------|
| 21  | PR |
| 49  | PR |
| 84  | PD |

- Day 21 PR: next CR/PR is day 49 (gap 28 days, no PD between) -> **confirmed PR** (rule 5).
- Day 49 PR: next CR/PR assessment doesn't exist (day 84 is PD, not CR/PR)
  -> not confirmed by rule 5. Late? day 49 - day 0 = 49 >= 42 -> **confirmed SD**
  (rule 6, via the "late" branch).
- Day 84 PD: passthrough -> **confirmed PD** (rule 12).

Confirmed BOR = **PR**, dated day 21 (first — and only — assessment at the
best confirmed level; the day-49 record confirmed to SD, not PR).
