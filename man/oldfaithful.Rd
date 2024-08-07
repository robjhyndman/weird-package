% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datasets.R
\docType{data}
\name{oldfaithful}
\alias{oldfaithful}
\title{Old faithful eruption data}
\format{
A data frame with 2261 rows and 3 columns:
\describe{
\item{time}{Time eruption started}
\item{duration}{Duration of eruption in seconds}
\item{waiting}{Time to the following eruption}
}
}
\source{
\url{https://geysertimes.org}
}
\usage{
oldfaithful
}
\value{
Data frame
}
\description{
A data set containing data on recorded eruptions of the Old Faithful Geyser
in Yellowstone National Park, Wyoming, USA, from
1 January 2015 to 1 October 2021.
Recordings are incomplete, especially during the winter months when observers
may not be present.
}
\examples{
oldfaithful |>
  filter(duration < 7000, waiting < 7000) |>
  ggplot(aes(x = duration, y = waiting)) +
  geom_point()
}
\keyword{datasets}
