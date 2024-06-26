% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lookout.R
\name{lookout}
\alias{lookout}
\title{Lookout probabilities}
\usage{
lookout(
  object = NULL,
  density_scores = NULL,
  loo_scores = density_scores,
  threshold_probability = 0.95
)
}
\arguments{
\item{object}{A model object or a numerical data set.}

\item{density_scores}{Numerical vector of log scores}

\item{loo_scores}{Optional numerical vector of leave-one-out log scores}

\item{threshold_probability}{Probability threshold when computing the POT model for the log scores.}
}
\value{
A numerical vector containing the lookout probabilities
}
\description{
Compute leave-one-out log score probabilities using a
Generalized Pareto distribution. These give the probability of each observation
being from the same distribution as the majority of observations. A low probability
indicates a likely anomaly.
}
\details{
This function can work with several object types.
If \code{object} is not \code{NULL}, then the object is passed to \code{\link{density_scores}}
to compute density scores (and possibly LOO density scores). Otherwise,
the density scores are taken from the \code{density_scores} argument, and the
LOO density scores are taken from the \code{loo_scores} argument. Then the Generalized
Pareto distribution is fitted to the scores, to obtain the probability of each observation.
}
\examples{
# Univariate data
tibble(
  y = c(5, rnorm(49)),
  lookout = lookout(y)
)
# Bivariate data with score calculation done outside the function
tibble(
  x = rnorm(50),
  y = c(5, rnorm(49)),
  fscores = density_scores(y),
  loo_fscores = density_scores(y, loo = TRUE),
  lookout = lookout(density_scores = fscores, loo_scores = loo_fscores)
)
# Using a regression model
of <- oldfaithful |> filter(duration < 7200, waiting < 7200)
fit_of <- lm(waiting ~ duration, data = of)
of |>
  mutate(lookout_prob = lookout(fit_of)) |>
  arrange(lookout_prob)
}
\references{
Sevvandi Kandanaarachchi & Rob J Hyndman (2022) "Leave-one-out
kernel density estimates for outlier detection", \emph{J Computational & Graphical
Statistics}, \strong{31}(2), 586-599. \url{https://robjhyndman.com/publications/lookout/}
}
\author{
Rob J Hyndman
}
