# confirm_bor.R
# Confirmed Best Overall Response (BOR) per RECIST 1.1, rules 1-13.
# Source rules: ../references/recist11_cbor_rules.md (verbatim doc text +
# the EIK1001-006 interpretation defaults). This is the vetted derivation
# engine, generalized from confirm_assessments()/derive_cbor() in
# eik1001-006_analysis.R section (11) — reuse it rather than
# re-deriving the rule logic from scratch for each dataset. Write only the
# thin per-dataset glue code (reading the source data, mapping raw category
# codes, looping over subjects) around these two functions.

#' Confirm each overall-response assessment in date order (rules 1-13).
#'
#' @param resp character vector, one of CR/PR/SD/PD/NE, same order as
#'   `date` (ascending, one subject only). Map study-specific codes (e.g.
#'   NON-CR/NON-PD -> SD, NED -> NE) and drop inadequate codes BEFORE
#'   calling: every element of `resp` must already be CR/PR/SD/PD/NE.
#' @param date Date vector, same length/order as resp.
#' @param trtsdt scalar Date, treatment start date (rules 2/6/9: "observed
#'   >= late_days from treatment start").
#' @param late_days numeric, default 42 (rules 2/6/9's "42 days").
#' @param confirm_gap_days numeric, default 28 (rules 1/5's confirmation gap).
#' @return character vector of confirmed values, same length/order as resp.
confirm_assessments <- function(resp, date, trtsdt,
                                 late_days = 42, confirm_gap_days = 28) {
  n <- length(resp)
  out <- character(n)
  for (i in seq_len(n)) {
    nxt  <- if (i < n) resp[i + 1] else NA_character_
    late <- !is.na(trtsdt) && as.numeric(date[i] - trtsdt) >= late_days

    if (resp[i] %in% c("CR", "PR")) {
      tgt <- if (resp[i] == "CR") "CR" else c("CR", "PR")        # rule 1 vs 5
      j <- which(seq_len(n) > i & resp %in% tgt)[1]
      between <- if (!is.na(j) && j > i + 1) resp[(i + 1):(j - 1)] else character(0)
      conf <- !is.na(j) && !any(between == "PD") &&
        as.numeric(date[j] - date[i]) >= confirm_gap_days
      out[i] <- if (conf) resp[i]                                        # rule 1 / 5
      else if (late || (!is.na(nxt) && !nxt %in% c("PD", "NE"))) "SD"    # rule 2 / 6
      else if (is.na(nxt) || nxt == "NE") "NE"                           # rule 3 / 7
      else "PD"                                                          # rule 4 / 8 (next is PD)
    } else if (resp[i] == "SD") {
      out[i] <- if (late) "SD"                                           # rule 9
      else if (is.na(nxt) || nxt != "PD") "NE"                           # rule 10
      else "PD"                                                          # rule 11
    } else {
      out[i] <- resp[i]                                                  # rule 12 (PD), 13 (NE)
    }
  }
  out
}

#' Derive one subject's confirmed BOR from a date-ordered sequence of
#' overall-response assessments. Applies Note 1 (drop assessments on/after
#' new anti-cancer therapy) and Note 2 (drop everything after the first PD,
#' keeping the PD itself), confirms each remaining assessment, and takes the
#' first assessment at the numerically best confirmed level.
#'
#' BOR order is CR > PR > SD > PD > NE (EIK1001-006 decision 2026-10-13,
#' overriding the doc's literal "CR = PR" tie-break): a PR later upgraded by
#' a confirmed CR gives BOR = CR even if that confirmed PR came first. To
#' follow the doc's literal tie-break instead, treat CR and PR as the same
#' rank before interpreting the result.
#'
#' @param resp,date as in confirm_assessments(), NOT yet restricted by
#'   Note 1/2 (this function applies both).
#' @param trtsdt scalar Date, treatment start date.
#' @param new_therapy_dt scalar Date or NA — assessments with date >=
#'   new_therapy_dt are dropped before evaluation (Note 1). If a study has
#'   two candidate source dates, pass the earlier of the two (or NA if
#'   neither exists) per the project default.
#' @return list(bor, bor_date, confirmed, dates_considered, raw_sequence)
subject_bor <- function(resp, date, trtsdt, new_therapy_dt = NA,
                         late_days = 42, confirm_gap_days = 28) {
  raw_sequence <- paste0(resp, "@", date, collapse = " ")
  ord <- order(date)
  resp <- resp[ord]; date <- date[ord]

  if (!is.na(new_therapy_dt)) {
    keep <- date < new_therapy_dt                                # Note 1
    resp <- resp[keep]; date <- date[keep]
  }
  pd1 <- which(resp == "PD")[1]
  if (!is.na(pd1)) { resp <- resp[seq_len(pd1)]; date <- date[seq_len(pd1)] }  # Note 2

  if (!length(resp)) {
    return(list(bor = "No assessment", bor_date = as.Date(NA),
                confirmed = character(0), dates_considered = as.Date(character(0)),
                raw_sequence = raw_sequence))
  }

  cv <- confirm_assessments(resp, date, trtsdt, late_days, confirm_gap_days)
  rank <- c(CR = 5, PR = 4, SD = 3, PD = 2, NE = 1)
  k <- which(rank[cv] == max(rank[cv]))[1]     # first assessment at the best confirmed level

  list(bor = cv[k], bor_date = date[k], confirmed = cv,
       dates_considered = date, raw_sequence = raw_sequence)
}
