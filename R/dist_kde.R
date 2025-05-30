#' Create distributional object based on a kernel density estimate
#'
#' Creates a distributional object using a kernel density estimate with a
#' Gaussian kernel obtained from the \code{\link[ks]{kde}()} function. The bandwidth
#' can be specified; otherwise the \code{\link{kde_bandwidth}()} function is used.
#' The cdf, quantiles and moments are consistent with the kde. Generating
#' random values from the kde is equivalent to a smoothed bootstrap.
#'
#' @param y Numerical vector or matrix of data, or a list of such objects. If a
#' list is provided, then all objects should be of the same dimension. e.g.,
#' all vectors, or all matrices with the same number of columns.
#' @param h Bandwidth for univariate distribution. If `NULL`, the
#' \code{\link{kde_bandwidth}} function is used.
#' @param H Bandwidth matrix for multivariate distribution. If `NULL`, the
#' \code{\link{kde_bandwidth}} function is used.
#' @param multiplier Multiplier for bandwidth passed to \code{\link{kde_bandwidth}}.
#' Ignored if `h` or `H` are specified.
#' @param ... Other arguments are passed to \code{\link[ks]{kde}}.
#' @examples
#' dist_kde(c(rnorm(200), rnorm(100, 5)), multiplier = 2)
#' dist_kde(cbind(rnorm(200), rnorm(200, 5)))
#'
#' @export

dist_kde <- function(y, h = NULL, H = NULL, multiplier = 1, ...) {
  if (!is.list(y)) {
    y <- list(y)
  } else if (is.data.frame(y)) {
    y <- list(as.matrix(y))
  }
  d <- unlist(lapply(y, function(u) NCOL(u)))
  if (!all(d == d[1])) {
    stop("All data sets must have the same dimension")
  }
  y <- vctrs::as_list_of(y, .ptype = vctrs::vec_ptype(y[[1]]))
  # Estimate density using ks::kde
  density <- lapply(
    y,
    function(u) {
      if (NCOL(u) == 1L) {
        if (is.null(h)) {
          if (!is.null(H)) {
            h <- sqrt(H)
          } else {
            h <- kde_bandwidth(u, multiplier = multiplier)
          }
        }
        ks::kde(x = u, h = h, ...)
      } else {
        if (is.null(H)) {
          H <- kde_bandwidth(u, multiplier = multiplier)
        }
        ks::kde(x = u, H = H, ...)
      }
    }
  )
  # Convert to distributional object
  distributional::new_dist(kde = density, class = "dist_kde")
}

#' @export
format.dist_kde <- function(x, ...) {
  d <- vapply(x, function(u) {
    NCOL(u$x)
  }, integer(1L))
  ngrid <- vapply(x, function(u) {
    length(u$eval.points)
  }, integer(1L))
  if (d == 1) {
    # Find bandwidth and convert to string
    h <- vapply(x, function(u) {
      u$h
    }, numeric(1L))
    sprintf("kde[%sd, h=%.2g]", d, h)
  } else {
    # Create matrix as string
    H <- c(vapply(x, function(u) {
      u$H
    }, numeric(d * d)))
    Hstring <- "{"
    for (i in seq(d)) {
      Hstring <- paste0(
        Hstring, "(",
        paste0(sprintf("%.2g", H[(i - 1) * d + seq(d)]),
          sep = "", collapse = ", "
        ),
        ")'"
      )
      if (i < d) {
        Hstring <- paste0(Hstring, ", ")
      }
    }
    Hstring <- paste0(Hstring, "}")
    sprintf("kde[%sd, H=%s]", d, Hstring)
  }
}

#' @export
density.dist_kde <- function(x, at, ..., na.rm = TRUE) {
  d <- NCOL(x$kde$x)
  if (d == 1) {
    d <- stats::approx(x$kde$eval.points, x$kde$estimate, xout = at)$y
  } else {
    # Turn at into a matrix
    if (is.list(at)) {
      at <- do.call(rbind, at)
    } else {
      at <- matrix(at, ncol = d)
    }
    # Bivariate interpolation
    grid <- expand.grid(x$kde$eval.points[[1]], x$kde$eval.points[[2]])
    ifun <- interpolation::interpfun(x = grid[,1], y = grid[,2], z = c(x$kde$estimate))
    d <- ifun(at[,1], at[,2])
  }
  d[is.na(d)] <- 0
  return(d)
}

#' @exportS3Method distributional::log_density
log_density.dist_kde <- function(x, at, ..., na.rm = TRUE) {
  log(density.dist_kde(x, at = at, ..., na.rm = na.rm))
}

#' @exportS3Method distributional::cdf
cdf.dist_kde <- function(x, q, ..., na.rm = TRUE) {
  # Apply independently over margins
  if (NCOL(x$kde$x) > 1) {
    stop("Multivariate kde cdf not implemented")
  }
  # Integrate density
  F <- cumintegral(x$kde$eval.points, x$kde$estimate)
  stats::approx(F$x, F$y, xout = q, yleft = 0, yright = 1, ..., na.rm = na.rm)$y
}

#' @export
quantile.dist_kde <- function(x, p, ..., na.rm = TRUE) {
  if (NCOL(x$kde$x) > 1) {
    stop("Multivariate kde quantiles not implemented")
  }
  # Compute CDF at density ordinates
  F <- cumintegral(x$kde$eval.points, x$kde$estimate)
  stats::approx(F$y, F$x,
    xout = p, yleft = min(F$x), yright = max(F$x),
    ties = mean, ..., na.rm = na.rm
  )$y
}

#' @exportS3Method distributional::generate
generate.dist_kde <- function(x, times, ...) {
  d <- NCOL(x$kde$x)
  i <- sample(NROW(x$kde$x), size = times, replace = TRUE)
  if (d == 1) {
    x$kde$x[i] + stats::rnorm(times, sd = x$kde$h)
  } else {
    x$kde$x[i, ] + mvtnorm::rmvnorm(times, sigma = x$kde$H)
  }
}

#' @export
mean.dist_kde <- function(x, ...) {
  if (NCOL(x$kde$x) > 1) {
    matrix(apply(x$kde$x, 2, mean, ...), ncol = NCOL(x$kde$x))
  } else {
    mean(x$kde$x, ...)
  }
}

#' @exportS3Method stats::median
median.dist_kde <- function(x, na.rm = FALSE, ...) {
  quantile(x, 0.5, na.rm = na.rm, ...)
}

#' @exportS3Method distributional::covariance
covariance.dist_kde <- function(x, ...) {
  n <- NROW(x$kde$x)
  if (NCOL(x$kde$x) > 1) {
    stop("Multivariate kde covariance is not yet implemented")
    stats::cov(x$kde$x, ...) # Needs adjustment
  } else {
    (n - 1) / n * stats::var(x$kde$x, ...) + x$kde$h^2
  }
}

#' @exportS3Method distributional::skewness
skewness.dist_kde <- function(x, ..., na.rm = FALSE) {
  if (NCOL(x$kde$x) > 1) {
    stop("Multivariate kde skewness is not yet implemented")
  } else {
    mean((x$kde$x - mean(x$kde$x))^3) / distributional::variance(x)^1.5
  }
}

#' @exportS3Method distributional::kurtosis
# Excess kurtosis for consistency with distributional package
kurtosis.dist_kde <- function(x, ..., na.rm = FALSE) {
  if (NCOL(x$kde$x) > 1) {
    stop("Multivariate kde kurtosis is not yet implemented")
  } else {
    h <- x$kde$h
    v <- distributional::variance(x)
    (mean((x$kde$x - mean(x$kde$x))^4) + 6 * h^2 * v - 3 * h^4) / v^2 - 3
  }
}
