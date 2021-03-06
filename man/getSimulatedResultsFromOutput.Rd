% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities-goodness-of-fit.R
\name{getSimulatedResultsFromOutput}
\alias{getSimulatedResultsFromOutput}
\title{getSimulatedResultsFromOutput}
\usage{
getSimulatedResultsFromOutput(
  simulationPathResults,
  output,
  simulationQuantity,
  molWeight,
  simulationSet
)
}
\arguments{
\item{simulationPathResults}{list with simulated data included}

\item{output}{An `Output` object}

\item{simulationQuantity}{Dimension/quantity for unit conversion of dependent variable}

\item{molWeight}{Molar weight for unit conversion of dependent variable}

\item{simulationSet}{`SimulationSet` object}
}
\value{
list of data and metaData
}
\description{
Get simulated data from an Output object
}
