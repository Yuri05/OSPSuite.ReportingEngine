#' @title SimulationSet
#' @description R6 class representing Reporting Engine Mean Model Set
#' @field simulationSetName display name of simulation set
#' @field simulationFile names of pkml file to be used for the simulation
#' @field outputs list of `Output` R6 class objects
#' @field observedDataFile name of csv file to be used for observed data
#' @field observedMetaDataFile name of csv file to be used as dictionary of the observed data
#' @field timeUnit display unit for time variable
#' @field applicationRanges named list of logicals defining which Application ranges are included in
#' reported time profiles and residual plots when applicable
#' @export
SimulationSet <- R6::R6Class(
  "SimulationSet",
  public = list(
    simulationSetName = NULL,
    simulationFile = NULL,
    outputs = NULL,
    observedDataFile = NULL,
    observedMetaDataFile = NULL,
    timeUnit = NULL,
    applicationRanges = NULL,

    #' @description
    #' Create a new `SimulationSet` object.
    #' @param simulationSetName display name of simulation set
    #' @param simulationFile names of pkml file to be used for the simulation
    #' @param outputs list of `Output` R6 class objects
    #' @param observedDataFile name of csv file to be used for observed data
    #' @param observedMetaDataFile name of csv file to be used as dictionary of the observed data
    #' @param timeUnit display unit for time variable. Default is "h"
    #' @param applicationRanges names of application ranges to include in the report. Names are available in enum `ApplicationRanges`.
    #' @return A new `SimulationSet` object
    initialize = function(simulationSetName,
                          simulationFile,
                          outputs = NULL,
                          observedDataFile = NULL,
                          observedMetaDataFile = NULL,
                          timeUnit = "h",
                          applicationRanges = ApplicationRanges) {
      # Test and validate the simulation object
      validateIsString(simulationSetName)
      validateIsString(simulationFile)
      # For optional input, usually null is allowed
      # but not here as it would mean that nothing would be reported
      validateIsIncluded(c(applicationRanges), ApplicationRanges)

      validateIsFileExtension(simulationFile, "pkml")
      simulation <- ospsuite::loadSimulation(simulationFile)
      # Test and validate outputs and their paths
      validateOutputObject(c(outputs), simulation, nullAllowed = TRUE)
      # Test and validate observed data
      validateIsString(c(observedDataFile, observedMetaDataFile, timeUnit), nullAllowed = TRUE)
      if (!is.null(observedDataFile)) {
        validateObservedMetaDataFile(observedMetaDataFile, observedDataFile)
      }

      self$simulationSetName <- simulationSetName
      self$simulationFile <- simulationFile

      self$outputs <- c(outputs)

      self$observedDataFile <- observedDataFile
      self$observedMetaDataFile <- observedMetaDataFile

      self$timeUnit <- timeUnit %||% "h"

      self$applicationRanges <- list(
        total = isIncluded(ApplicationRanges$total, applicationRanges),
        firstApplication = isIncluded(ApplicationRanges$firstApplication, applicationRanges),
        lastApplication = isIncluded(ApplicationRanges$lastApplication, applicationRanges)
      )
    }
  )
)
