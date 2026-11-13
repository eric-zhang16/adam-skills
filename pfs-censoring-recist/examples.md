# Worked example: multi-subject glue code

Adapt per dataset — column names, category mapping, and new-therapy source
differ by study. Mirrors `validate_pfs()` / `pfs_one()` in
`eik1001-006_analysis.R` section (3).

```r
source("scripts/pfs_censor.R")   # pfs_censor_one()

# This trial's own missed-scans window — NOT EIK1001-006's numbers.
# Example: constant q8w scanning throughout.
miss_threshold <- function(event_day) 2 * 8 * 7

# `assess`: adequate (CR/PR/SD/PD only — NE/NED already dropped) response
#           assessments, one row per subject per date.
# `subj`:   one row per subject: RANDDT, DTHDT (NA if alive),
#           NEW_THERAPY (NA if none).

assess <- assess %>%
  mutate(RESP = if_else(AVALC == "NON-CR/NON-PD", "SD", AVALC)) %>%
  filter(RESP %in% c("CR", "PR", "SD", "PD")) %>%
  arrange(USUBJID, ADT)

by_subj <- split(assess, assess$USUBJID)

derived <- lapply(seq_len(nrow(subj)), function(i) {
  s <- subj[i, ]
  r <- by_subj[[s$USUBJID]]
  out <- if (is.null(r)) {
    pfs_censor_one(character(0), as.Date(character(0)), s$RANDDT, s$DTHDT, s$NEW_THERAPY, miss_threshold)
  } else {
    pfs_censor_one(r$RESP, r$ADT, s$RANDDT, s$DTHDT, s$NEW_THERAPY, miss_threshold)
  }
  tibble(USUBJID = s$USUBJID, CNSR = out$cnsr, ADT = out$date,
         AVAL = as.numeric(out$date - s$RANDDT) + 1)
}) %>% bind_rows()
```

## Worked individual case (for teaching mode)

8-week scanning throughout (`miss_threshold = 112` days). Randomization
day 0, last adequate scan day 56 (SD), apparent PD on day 200, no new
therapy, alive.

- An event exists (PD day 200). Gap from last adequate assessment (day 56)
  to the event: `200 - 56 + 1 = 145` days.
- `145 > miss_threshold(200) = 112` -> the gap is too long to date the
  progression reliably ("missed 2 scheduled scans").
- **Censored**, backed up to the last adequate assessment: day 56, not the
  apparent PD date of day 200.

If instead the last adequate scan had been day 160 (gap `200-160+1=41 <=
112`), PFS would be an **event** on day 200, scored as-is.
