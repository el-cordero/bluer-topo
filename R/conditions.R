.bt_abort <- function(message, class = NULL, ..., parent = NULL) {
  cli::cli_abort(
    message,
    class = unique(c(class, "bluertopo_error", "rlang_error", "error", "condition")),
    ...,
    parent = parent
  )
}

.bt_warn <- function(message, class = NULL, ...) {
  cli::cli_warn(
    message,
    class = unique(c(class, "bluertopo_warning", "rlang_warning", "warning", "condition")),
    ...
  )
}

.bt_inform <- function(message, quiet = FALSE) {
  if (!isTRUE(quiet)) {
    cli::cli_inform(message)
  }
}

.bt_error_message <- function(condition) {
  msg <- conditionMessage(condition)
  if (!nzchar(msg)) {
    msg <- class(condition)[1L]
  }
  msg
}
