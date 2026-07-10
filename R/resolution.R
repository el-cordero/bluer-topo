#' Construct a BlueTopo native-resolution policy
#'
#' `bluertopo_resolution()` creates an explicit native source-tile selection
#' policy. Smaller meter values are finer source resolution. This object never
#' requests output resampling; use `output_resolution` in [bluertopo()] for an
#' explicit output grid.
#'
#' @param strategy Resolution strategy.
#' @param value A single meter value used by target-like strategies.
#' @param values One or more exact meter values.
#' @param min_m,max_m Inclusive meter bounds.
#' @param n Rank or count for rank-based strategies.
#' @param scope `"global"` or `"local"`.
#' @param tie Tie preference for nearest/target strategies.
#' @param prefer Preference direction for coverage/rank strategies.
#' @param strict Whether fallback must remain inside hard constraints.
#' @param min_coverage Coverage target for coverage-oriented strategies.
#'
#' @return A `bluertopo_resolution` S3 object.
#' @export
#' @examples
#' bluertopo_resolution("nearest", value = 10, tie = "finer")
#' bluertopo_resolution("between", min_m = 4, max_m = 16)
bluertopo_resolution <- function(
  strategy,
  value = NULL,
  values = NULL,
  min_m = NULL,
  max_m = NULL,
  n = NULL,
  scope = "global",
  tie = "finer",
  prefer = "finest",
  strict = TRUE,
  min_coverage = 1
) {
  strategy <- .bt_match_arg(
    strategy,
    c(
      "native", "finest", "highest", "coarsest", "lowest",
      "best_available", "coarsest_available", "dominant",
      "exact", "nearest", "finer_or_equal", "coarser_or_equal",
      "between", "rank", "finest_n", "coarsest_n", "target", "coverage"
    ),
    "strategy"
  )
  strategy <- switch(strategy,
    highest = "finest",
    lowest = "coarsest",
    strategy
  )
  scope <- .bt_match_arg(scope, c("global", "local"), "scope")
  tie <- .bt_match_arg(tie, c("finer", "coarser"), "tie")
  prefer <- .bt_match_arg(prefer, c("finest", "coarsest"), "prefer")
  strict <- .bt_validate_bool(strict, "strict")
  min_coverage <- .bt_validate_number(min_coverage, "min_coverage", positive = FALSE)
  if (min_coverage < 0 || min_coverage > 1) {
    .bt_abort("`min_coverage` must be between 0 and 1.", class = "bluertopo_error_resolution")
  }

  value <- if (is.null(value)) NULL else .bt_parse_resolution_m(value, allow_na = FALSE)
  values <- if (is.null(values)) NULL else .bt_parse_resolution_m(values, allow_na = FALSE)
  min_m <- if (is.null(min_m)) NULL else .bt_parse_resolution_m(min_m, allow_na = FALSE)
  max_m <- if (is.null(max_m)) NULL else .bt_parse_resolution_m(max_m, allow_na = FALSE)
  n <- if (is.null(n)) NULL else as.integer(.bt_validate_number(n, "n"))

  .bt_validate_resolution_strategy(strategy, value, values, min_m, max_m, n)

  structure(
    list(
      strategy = strategy,
      value = value,
      values = values,
      min_m = min_m,
      max_m = max_m,
      n = n,
      scope = scope,
      tie = tie,
      prefer = prefer,
      strict = strict,
      min_coverage = min_coverage
    ),
    class = "bluertopo_resolution"
  )
}

.bt_validate_resolution_strategy <- function(strategy, value, values, min_m, max_m, n) {
  needs_value <- strategy %in% c("nearest", "finer_or_equal", "coarser_or_equal", "target")
  if (needs_value && is.null(value)) {
    .bt_abort(sprintf("Resolution strategy `%s` requires `value`.", strategy),
      class = "bluertopo_error_resolution"
    )
  }
  if (identical(strategy, "exact") && is.null(values)) {
    .bt_abort("Resolution strategy `exact` requires `values`.",
      class = "bluertopo_error_resolution"
    )
  }
  if (identical(strategy, "between")) {
    if (is.null(min_m) || is.null(max_m)) {
      .bt_abort("Resolution strategy `between` requires `min_m` and `max_m`.",
        class = "bluertopo_error_resolution"
      )
    }
    if (min_m > max_m) {
      .bt_abort("`min_m` must be less than or equal to `max_m`.",
        class = "bluertopo_error_resolution"
      )
    }
  }
  if (strategy %in% c("rank", "finest_n", "coarsest_n") && is.null(n)) {
    .bt_abort(sprintf("Resolution strategy `%s` requires `n`.", strategy),
      class = "bluertopo_error_resolution"
    )
  }
  invisible(TRUE)
}

.bt_parse_resolution_m <- function(x, allow_na = FALSE) {
  if (inherits(x, "bluertopo_resolution")) {
    .bt_abort("A resolution policy object cannot be parsed as a meter value.",
      class = "bluertopo_error_resolution"
    )
  }
  original <- x
  if (is.factor(x)) {
    x <- as.character(x)
  }
  if (is.character(x)) {
    y <- trimws(tolower(x))
    y <- gsub("\\s*meters?$", "", y)
    y <- gsub("\\s*m$", "", y)
    y <- trimws(y)
    value <- suppressWarnings(as.numeric(y))
  } else {
    value <- suppressWarnings(as.numeric(x))
  }
  bad <- is.na(value) | !is.finite(value) | value <= 0
  if (!allow_na && any(bad)) {
    .bt_abort(
      sprintf("Invalid native resolution meter value: %s.", paste(original[bad], collapse = ", ")),
      class = "bluertopo_error_resolution"
    )
  }
  if (allow_na) {
    value[bad] <- NA_real_
  } else if (any(bad)) {
    .bt_abort("Resolution values must be positive finite meter values.",
      class = "bluertopo_error_resolution"
    )
  }
  value
}

.bt_resolution_spec <- function(resolution) {
  if (inherits(resolution, "bluertopo_resolution")) {
    return(resolution)
  }
  if (is.numeric(resolution)) {
    return(bluertopo_resolution("exact", values = resolution))
  }
  if (.bt_is_scalar_character(resolution)) {
    shortcut <- switch(tolower(resolution),
      highest = "finest",
      lowest = "coarsest",
      native = "native",
      finest = "finest",
      coarsest = "coarsest",
      best_available = "best_available",
      coarsest_available = "coarsest_available",
      dominant = "dominant",
      NULL
    )
    if (!is.null(shortcut)) {
      return(bluertopo_resolution(shortcut))
    }
  }
  .bt_abort(
    "`resolution` must be a supported shortcut, numeric native meter value, or bluertopo_resolution object.",
    class = "bluertopo_error_resolution"
  )
}

.bt_resolution_plan <- function(spec, available, area = NULL) {
  available <- sort(unique(available[!is.na(available) & is.finite(available)]))
  if (!length(available)) {
    .bt_abort("No valid native resolution values are available for the AOI.",
      class = "bluertopo_error_resolution"
    )
  }
  area_by_resolution <- .bt_area_by_resolution(available, area)
  strategy <- spec$strategy
  initial <- switch(strategy,
    native = available,
    finest = min(available),
    coarsest = max(available),
    best_available = available,
    coarsest_available = available,
    dominant = as.numeric(names(area_by_resolution)[which.max(area_by_resolution)]),
    exact = intersect(spec$values, available),
    nearest = .bt_nearest_resolution(available, spec$value, spec$tie),
    target = .bt_nearest_resolution(available, spec$value, spec$tie),
    finer_or_equal = available[available <= spec$value],
    coarser_or_equal = available[available >= spec$value],
    between = available[available >= spec$min_m & available <= spec$max_m],
    rank = .bt_rank_resolution(available, spec$n, spec$prefer),
    finest_n = utils::head(available, spec$n),
    coarsest_n = utils::head(rev(available), spec$n),
    coverage = if (identical(spec$prefer, "finest")) min(available) else max(available)
  )
  initial <- sort(unique(as.numeric(initial)))
  if (!length(initial)) {
    .bt_abort(
      sprintf("No BlueTopo tiles match native resolution strategy `%s`.", strategy),
      class = "bluertopo_error_resolution"
    )
  }
  preference <- .bt_resolution_preference(spec, available, area_by_resolution)
  hard_allowed <- .bt_resolution_allowed_values(spec, available)
  fallback <- setdiff(preference, initial)
  if (isTRUE(spec$strict)) {
    fallback <- intersect(fallback, hard_allowed)
  }
  list(
    spec = spec,
    initial = initial,
    preference = preference,
    fallback = fallback,
    hard_allowed = hard_allowed
  )
}

.bt_area_by_resolution <- function(available, area) {
  if (is.null(area) || !length(area)) {
    out <- stats::setNames(rep(1, length(available)), available)
    return(out)
  }
  area <- area[!is.na(names(area))]
  totals <- tapply(as.numeric(area), as.character(names(area)), sum, na.rm = TRUE)
  totals <- totals[as.character(available)]
  totals[is.na(totals)] <- 0
  totals
}

.bt_nearest_resolution <- function(available, value, tie) {
  distance <- abs(available - value)
  best <- available[distance == min(distance)]
  if (length(best) == 1L) {
    return(best)
  }
  if (identical(tie, "finer")) {
    min(best)
  } else {
    max(best)
  }
}

.bt_rank_resolution <- function(available, n, prefer) {
  ordered <- if (identical(prefer, "finest")) available else rev(available)
  if (n > length(ordered)) {
    .bt_abort("`n` is larger than the number of available native resolutions.",
      class = "bluertopo_error_resolution"
    )
  }
  ordered[n]
}

.bt_resolution_preference <- function(spec, available, area_by_resolution) {
  strategy <- spec$strategy
  if (strategy %in% c("coarsest", "coarsest_available", "coarsest_n")) {
    return(rev(available))
  }
  if (strategy %in% c("nearest", "target")) {
    distance <- abs(available - spec$value)
    tie_order <- if (identical(spec$tie, "finer")) available else -available
    return(available[order(distance, tie_order)])
  }
  if (identical(strategy, "dominant")) {
    return(as.numeric(names(sort(area_by_resolution, decreasing = TRUE))))
  }
  if (identical(strategy, "coverage") && identical(spec$prefer, "coarsest")) {
    return(rev(available))
  }
  available
}

.bt_resolution_allowed_values <- function(spec, available) {
  switch(spec$strategy,
    exact = intersect(spec$values, available),
    finer_or_equal = available[available <= spec$value],
    coarser_or_equal = available[available >= spec$value],
    between = available[available >= spec$min_m & available <= spec$max_m],
    rank = .bt_rank_resolution(available, spec$n, spec$prefer),
    finest_n = utils::head(available, spec$n),
    coarsest_n = utils::head(rev(available), spec$n),
    available
  )
}

.bt_resolution_label <- function(spec) {
  if (identical(spec$strategy, "exact")) {
    return(sprintf("exact(%s m)", paste(spec$values, collapse = ", ")))
  }
  if (!is.null(spec$value)) {
    return(sprintf("%s(%s m)", spec$strategy, spec$value))
  }
  spec$strategy
}
