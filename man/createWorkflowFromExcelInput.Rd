% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities-excel-input.R
\name{createWorkflowFromExcelInput}
\alias{createWorkflowFromExcelInput}
\title{createWorkflowFromExcelInput}
\usage{
createWorkflowFromExcelInput(
  excelFile,
  workflowFile = "workflow.R",
  removeComments = FALSE
)
}
\arguments{
\item{excelFile}{name of the Excel file from which the R script is created}

\item{workflowFile}{name of the R script file created from the Excel file}

\item{removeComments}{logical to remove comments and information in `workflowFile`}
}
\value{
An R script of name `workflowFile` to be run
}
\description{
Creates an R script for running mean model or population workflows from an Excel file
}
