# pfs_censor.R
# PFS primary censoring rule (RECIST 1.1-based progression + new-therapy +
# missed-scans censoring), generalized from pfs_one() in
# eik1001-006_analysis.R section (3). See ../references/pfs_censoring_rules.md
# for the full rule write-up and a worked miss_threshold() example. Reuse
# this engine rather than re-deriving the censoring logic from scratch; write
# only the per-dataset glue code (reading the source data, mapping category
# codes, looping over subjects, and building the study's own miss_threshold()).

#' Derive PFS censoring/event status for ONE subject.
#'
#' @param resp,date date-ordered overall-response assessments, restricted to
#'   adequate categories already: every element of `nonpd` plus "PD" only.
#'   Drop NE/NED rows before calling.
#' @param randdt scalar Date, randomization date.
#' @param dthdt scalar Date or NA, death date.
#' @param new_therapy_dt scalar Date or NA, new anti-cancer therapy start.
#' @param miss_threshold function(event_day) -> max allowed gap in days
#'   between the last adequate non-PD assessment and the event before it
#'   converts to censoring. STUDY-SPECIFIC — see the reference doc; do not
#'   reuse another study's thresholds.
#' @param nonpd character vector of response values counting as "not
#'   progressed" (default CR/PR/SD; map NON-CR/NON-PD -> SD before calling).
#' @return list(cnsr = 0/1, date = Date)  (0 = event, 1 = censored, matching
#'   ADaM CNSR convention)
pfs_censor_one <- function(resp, date, randdt, dthdt, new_therapy_dt,
                            miss_threshold, nonpd = c("CR", "PR", "SD")) {
  # Coerce scalars to Date: a bare NA (logical, not Date) for dthdt/
  # new_therapy_dt is a common and harmless way for glue code to signal
  # "no date", but arithmetic on it loses the Date class unless coerced here.
  randdt <- as.Date(randdt); dthdt <- as.Date(dthdt); new_therapy_dt <- as.Date(new_therapy_dt)
  ord <- order(date); resp <- resp[ord]; date <- date[ord]
  has_canc <- !is.na(new_therapy_dt)

  last_before_canc <- function() {
    t <- date[resp %in% nonpd & has_canc & date < new_therapy_dt]
    if (length(t)) max(t) else randdt
  }

  if (!length(resp)) {                                      # (1) no post-baseline assessment
    if (!is.na(dthdt)) {
      after_canc <- has_canc && dthdt > new_therapy_dt
      # event_day = 0: before any scheduled assessment has occurred, so the
      # applicable window is always the earliest one a well-formed
      # miss_threshold() returns for day 0.
      after_miss <- as.numeric(dthdt - randdt + 1) > miss_threshold(0)
      if (after_canc || after_miss) return(list(cnsr = 1, date = randdt))
      return(list(cnsr = 0, date = dthdt))
    }
    return(list(cnsr = 1, date = randdt))
  }

  pd_date <- if (any(resp == "PD")) min(date[resp == "PD"]) else as.Date(NA)

  if (!(is.na(dthdt) && is.na(pd_date))) {                   # (2) an event exists
    evt   <- min(dthdt, pd_date, na.rm = TRUE)
    dur   <- as.numeric(evt - randdt)
    prior <- date[resp %in% nonpd & date < evt]
    last_nonpd <- if (length(prior)) max(prior) else randdt
    gap   <- as.numeric(evt - last_nonpd) + 1
    thr   <- miss_threshold(dur)
    if (has_canc && evt > new_therapy_dt) return(list(cnsr = 1, date = last_before_canc()))
    if (gap > thr)                        return(list(cnsr = 1, date = last_nonpd))
    return(list(cnsr = 0, date = evt))
  }
  if (has_canc) return(list(cnsr = 1, date = last_before_canc()))        # (3) no event, new therapy
  list(cnsr = 1, date = max(date[resp %in% nonpd]))                      # (4) no event, no new therapy
}
