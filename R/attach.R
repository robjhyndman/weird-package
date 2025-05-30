# Based on attach.R from the tidyverse package

core <- c(
  "dplyr",
  "ggplot2",
  "distributional"
)

core_unloaded <- function() {
  search <- paste0("package:", core)
  core[!search %in% search()]
}

# Attach the package from the same package library it was loaded from before.
same_library <- function(pkg) {
  loc <- if (pkg %in% loadedNamespaces()) dirname(getNamespaceInfo(pkg, "path"))
  do.call(
    "library",
    list(pkg, lib.loc = loc, character.only = TRUE, warn.conflicts = FALSE)
  )
}

weird_attach <- function() {
  to_load <- core_unloaded()
  if (length(to_load) == 0) {
    return(invisible())
  }

  msg(
    cli::rule(
      left = crayon::bold("Attaching packages"),
      right = paste0("weird ", package_version("weird"))
    ),
    startup = TRUE
  )

  versions <- vapply(to_load, package_version, character(1))
  packages <- paste0(
    crayon::green(cli::symbol$tick), " ", crayon::blue(format(to_load)), " ",
    crayon::col_align(versions, max(crayon::col_nchar(versions)))
  )

  if (length(packages) %% 2 == 1) {
    packages <- append(packages, "")
  }
  col1 <- seq_len(length(packages) / 2)
  info <- paste0(packages[col1], "     ", packages[-col1])

  msg(paste(info, collapse = "\n"), startup = TRUE)

  suppressPackageStartupMessages(
    lapply(to_load, same_library)
  )

  invisible()
}

package_version <- function(x) {
  version <- as.character(unclass(utils::packageVersion(x))[[1]])

  if (length(version) > 3) {
    version[4:length(version)] <- crayon::red(as.character(version[4:length(version)]))
  }
  paste0(version, collapse = ".")
}
