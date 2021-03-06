% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{setWorkflowParameterDisplayPathsFromFile}
\alias{setWorkflowParameterDisplayPathsFromFile}
\title{setWorkflowParameterDisplayPathsFromFile}
\usage{
setWorkflowParameterDisplayPathsFromFile(fileName, workflow)
}
\arguments{
\item{fileName}{name of file that includes mapping of Parameters with their display paths
Names in header should include `parameter` and `displayPath`.}

\item{workflow}{Object of class `MeanModelWorkflow` or `PopulationWorkflow`}
}
\description{
Set mapping between parameters and their display paths in a workflow
to replace standard display of parameter paths.
}
