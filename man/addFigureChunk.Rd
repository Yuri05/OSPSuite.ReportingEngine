% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities-writing-report.R
\name{addFigureChunk}
\alias{addFigureChunk}
\title{addFigureChunk}
\usage{
addFigureChunk(
  fileName,
  figureFileRelativePath,
  figureFileRootDirectory,
  figureCaption = "",
  logFolder = getwd()
)
}
\arguments{
\item{fileName}{name of .md file}

\item{figureFileRelativePath}{path to figure relative to working directory}

\item{figureFileRootDirectory}{working directory}

\item{figureCaption}{caption of figure}

\item{logFolder}{folder where the logs are saved}
}
\description{
Add a figure in a .md document
}
