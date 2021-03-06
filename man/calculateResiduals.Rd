% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{calculateResiduals}
\alias{calculateResiduals}
\title{calculateResiduals}
\usage{
calculateResiduals(simulatedData, observedData, residualScale)
}
\arguments{
\item{simulatedData, }{vector of simulated data}

\item{observedData, }{vector of observed data}

\item{residualScale, }{must be selected from enum ResidualScales}
}
\value{
residuals between simulatedData and observedData
}
\description{
Calculate residuals between vectors `simulatedData` and `observedData` according the the residual scale specified in `residualScale`
}
