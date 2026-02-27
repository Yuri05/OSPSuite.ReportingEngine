#' @title plotQualificationComparisonTimeProfile
#' @description Plot comparison time profile for qualification workflow
#' @param configurationPlan A `ConfigurationPlan` object
#' @param settings `ConfigurationPlan` object
#' @return list with `plots` and `tables`
#' @import tlf
#' @import ospsuite
#' @import ospsuite.utils
#' @keywords internal
plotQualificationComparisonTimeProfile <- function(configurationPlan, settings) {
  # Pre-load all unique simulations and results to avoid redundant I/O
  simulationCache <- preloadSimulationsForComparisonTimeProfile(configurationPlan)
  observedDataCache <- preloadObservedDataForComparisonTimeProfile(configurationPlan)

  # Determine if parallel processing should be used
  timeProfilePlans <- configurationPlan$plots$ComparisonTimeProfilePlots
  numberOfCores <- settings$numberOfCores %||% reEnv$defaultSimulationNumberOfCores
  useParallel <- all(
    requireNamespace("parallel", quietly = TRUE),
    numberOfCores > 1,
    length(timeProfilePlans) > 1
  )

  if (useParallel) {
    # Parallel execution
    cl <- parallel::makeCluster(numberOfCores)
    on.exit(parallel::stopCluster(cl))

    # Export necessary objects to cluster
    parallel::clusterExport(cl, c(
      "simulationCache",
      "observedDataCache",
      "configurationPlan",
      "settings"
    ), envir = environment())

    # Export necessary functions to cluster
    parallel::clusterEvalQ(cl, {
      library(ospsuite)
      library(ospsuite.utils)
      library(tlf)
      library(ospsuite.reportingengine)
    })

    timeProfileResultsList <- parallel::parLapply(
      cl = cl,
      seq_along(timeProfilePlans),
      function(i) {
        processTimeProfilePlan(
          timeProfilePlan = timeProfilePlans[[i]],
          plotIndex = i,
          simulationCache = simulationCache,
          observedDataCache = observedDataCache,
          configurationPlan = configurationPlan,
          settings = settings
        )
      }
    )
  } else {
    # Sequential execution
    timeProfileResultsList <- lapply(
      seq_along(timeProfilePlans),
      function(i) {
        processTimeProfilePlan(
          timeProfilePlan = timeProfilePlans[[i]],
          plotIndex = i,
          simulationCache = simulationCache,
          observedDataCache = observedDataCache,
          configurationPlan = configurationPlan,
          settings = settings
        )
      }
    )
  }

  # Convert list to named list and remove NULL entries
  timeProfileResults <- list()
  for (result in timeProfileResultsList) {
    if (!is.null(result)) {
      timeProfileResults[[result$id]] <- result$data
    }
  }

  return(timeProfileResults)
}

#' @title processTimeProfilePlan
#' @description Process a single time profile plan (extracted for parallelization)
#' @param timeProfilePlan A time profile plan from configuration
#' @param plotIndex Index of the plot
#' @param simulationCache Pre-loaded simulations cache
#' @param observedDataCache Pre-loaded observed data cache
#' @param configurationPlan A `ConfigurationPlan` object
#' @param settings Settings object
#' @return A list with id and data, or NULL on error
#' @keywords internal
processTimeProfilePlan <- function(timeProfilePlan, plotIndex, simulationCache, observedDataCache, configurationPlan, settings) {
  result <- qualificationCatch(
    {
      # Create a unique ID for the plot name as <Plot index>-<Project>-<Simulation>
      plotID <- defaultFileNames$resultID("comparison_time_profile", timeProfilePlan$Title, plotIndex)

      # Get axes properties (with scale, limits and display units)
      axesProperties <- getAxesProperties(timeProfilePlan$Axes) %||% settings$axes
      if (isEmpty(axesProperties)) {
        logError(messages$warningNoAxesSettings(
          timeProfilePlan$Title,
          plotType = "Comparison Time Profile Plots"
        ))
        return(NULL)
      }

      simulationDuration <- ospsuite::toUnit(
        quantityOrDimension = "Time",
        values = as.numeric(timeProfilePlan$SimulationDuration),
        targetUnit = axesProperties$x$unit,
        sourceUnit = timeProfilePlan$TimeUnit
      )
      axesProperties$x <- c(
        axesProperties$x,
        getTimeTicksFromUnit(axesProperties$x$unit, simulationDuration)
      )

      plotConfiguration <- getPlotConfigurationFromPlan(timeProfilePlan[["PlotSettings"]])
      timeProfilePlot <- tlf::initializePlot(plotConfiguration)
      for (outputMapping in timeProfilePlan$OutputMappings) {
        timeProfilePlot <- addOutputToComparisonTimeProfile(
          outputMapping,
          simulationDuration,
          axesProperties,
          timeProfilePlot,
          configurationPlan,
          simulationCache,
          observedDataCache
        )
      }
      # Set axes based on Axes properties
      timeProfilePlot <- updatePlotAxes(timeProfilePlot, axesProperties)
      # Save results
      taskResult <- saveTaskResults(
        id = plotID,
        sectionId = timeProfilePlan$SectionReference %||% timeProfilePlan$SectionId,
        plot = timeProfilePlot,
        plotCaption = timeProfilePlan$Title
      )

      return(list(id = plotID, data = taskResult))
    },
    configurationPlanField = timeProfilePlan
  )

  return(result)
}

#' @title preloadSimulationsForComparisonTimeProfile
#' @description Pre-load all unique simulations and results to avoid redundant I/O
#' @param configurationPlan A `ConfigurationPlan` object
#' @return A list with simulation and results data
#' @keywords internal
preloadSimulationsForComparisonTimeProfile <- function(configurationPlan) {
  simulationCache <- list()

  # Collect all unique simulation keys
  uniqueSimKeys <- list()
  for (timeProfilePlan in configurationPlan$plots$ComparisonTimeProfilePlots) {
    for (outputMapping in timeProfilePlan$OutputMappings) {
      simKey <- paste(outputMapping$Project, outputMapping$Simulation, sep = "::")
      uniqueSimKeys[[simKey]] <- list(
        project = outputMapping$Project,
        simulation = outputMapping$Simulation
      )
    }
  }

  # Pre-load all unique simulations
  for (simKey in names(uniqueSimKeys)) {
    simInfo <- uniqueSimKeys[[simKey]]
    simulationFile <- configurationPlan$getSimulationPath(
      project = simInfo$project,
      simulation = simInfo$simulation
    )
    simulationResultsFile <- configurationPlan$getSimulationResultsPath(
      project = simInfo$project,
      simulation = simInfo$simulation
    )

    simulation <- ospsuite::loadSimulation(simulationFile, loadFromCache = TRUE)
    simulationResults <- ospsuite::importResultsFromCSV(simulation, simulationResultsFile)

    simulationCache[[simKey]] <- list(
      simulation = simulation,
      results = simulationResults
    )
  }

  return(simulationCache)
}

#' @title preloadObservedDataForComparisonTimeProfile
#' @description Pre-load all observed data to avoid redundant lookups
#' @param configurationPlan A `ConfigurationPlan` object
#' @return A list with observed data
#' @keywords internal
preloadObservedDataForComparisonTimeProfile <- function(configurationPlan) {
  observedDataCache <- list()

  # Collect all unique observed data IDs
  uniqueObsDataIds <- character(0)
  for (timeProfilePlan in configurationPlan$plots$ComparisonTimeProfilePlots) {
    for (outputMapping in timeProfilePlan$OutputMappings) {
      if (!is.null(outputMapping$ObservedData)) {
        uniqueObsDataIds <- unique(c(uniqueObsDataIds, outputMapping$ObservedData))
      }
    }
  }

  # Pre-load all unique observed data
  for (obsDataId in uniqueObsDataIds) {
    observedDataCache[[obsDataId]] <- getObservedDataFromConfigurationPlan(obsDataId, configurationPlan)
  }

  return(observedDataCache)
}

#' @title addOutputToComparisonTimeProfile
#' @description Add plot layers for an output mapping from comparison time profile plot
#' @param outputMapping list of mapping elements from `OutputMappings` field in configuration plan
#' @param simulationDuration Duration of simulation in X axis unit
#' @param axesProperties list of axes properties obtained from `getAxesProperties`
#' @param plotObject ggplot object
#' @param configurationPlan A `ConfigurationPlan` object
#' @param simulationCache Pre-loaded simulations cache (optional)
#' @param observedDataCache Pre-loaded observed data cache (optional)
#' @return A ggplot object
#' @import ospsuite.utils
#' @keywords internal
addOutputToComparisonTimeProfile <- function(outputMapping, simulationDuration, axesProperties, plotObject, configurationPlan, simulationCache = NULL, observedDataCache = NULL) {
  # Get simulation output from cache or load it
  simKey <- paste(outputMapping$Project, outputMapping$Simulation, sep = "::")
  if (!is.null(simulationCache) && !is.null(simulationCache[[simKey]])) {
    simulation <- simulationCache[[simKey]]$simulation
    simulationResults <- simulationCache[[simKey]]$results
  } else {
    simulationFile <- configurationPlan$getSimulationPath(
      project = outputMapping$Project,
      simulation = outputMapping$Simulation
    )
    simulationResultsFile <- configurationPlan$getSimulationResultsPath(
      project = outputMapping$Project,
      simulation = outputMapping$Simulation
    )
    simulation <- ospsuite::loadSimulation(simulationFile, loadFromCache = TRUE)
    simulationResults <- ospsuite::importResultsFromCSV(simulation, simulationResultsFile)
  }
  # Get and convert output path values into display unit
  simulationQuantity <- ospsuite::getQuantity(outputMapping$Output, simulation)
  simulationPathResults <- ospsuite::getOutputValues(simulationResults, quantitiesOrPaths = simulationQuantity)
  molWeight <- simulation$molWeightFor(outputMapping$Output)

  # timeOffset and simulationDuration needs to be in same unit as x Axis
  timeOffset <- ospsuite::toUnit(
    quantityOrDimension = "Time",
    values = as.numeric(outputMapping$StartTime %||% 0),
    targetUnit = axesProperties$x$unit,
    sourceUnit = outputMapping$TimeUnit %||% axesProperties$x$unit
  )
  simulatedTime <- ospsuite::toUnit(
    "Time",
    simulationPathResults$data[, "Time"],
    axesProperties$x$unit
  )
  simulatedTime <- simulatedTime - timeOffset
  selectedTimeValues <- simulatedTime >= 0 & simulatedTime <= simulationDuration
  simulatedTime <- simulatedTime[selectedTimeValues]

  logDebug(paste0(
    "In Comparison Time Profile Plots, Project '",
    outputMapping$Project, "' - Simulation '", outputMapping$Simulation, "'\n",
    messages$dataIncludedInTimeRange(
      sum(selectedTimeValues),
      timeOffset + c(0, simulationDuration),
      axesProperties$x$unit,
      "simulated"
    )
  ))

  simulatedValues <- ospsuite::toUnit(
    simulationQuantity,
    simulationPathResults$data[, outputMapping$Output],
    axesProperties$y$unit,
    molWeight = molWeight
  )
  simulatedValues <- simulatedValues[selectedTimeValues]
  # If issues with log scale due to all zeros or negative values
  # Warn and do not plot the data
  logScaleIssue <- all(simulatedValues <= 0, isIncluded(axesProperties$y$scale, "log"))
  if (logScaleIssue) {
    warning(messages$warningLogScaleIssue(outputMapping$Output), call. = FALSE)
  }

  if (!logScaleIssue) {
    # Add simulated values to plot
    plotObject <- tlf::addLine(
      x = simulatedTime,
      y = simulatedValues,
      caption = prettyCaption(paste(outputMapping$Caption, "Simulated Data"), plotObject),
      linetype = tlfLinetype(outputMapping$LineStyle),
      color = outputMapping$Color,
      size = outputMapping$Size,
      plotObject = plotObject
    )
  }

  # Loop on each observed dataset in OutputMappings
  for (observedDataSet in outputMapping$ObservedData) {
    # Get data and meta data of observed results from cache or load it
    if (!is.null(observedDataCache) && !is.null(observedDataCache[[observedDataSet]])) {
      observedResults <- observedDataCache[[observedDataSet]]
    } else {
      observedResults <- getObservedDataFromConfigurationPlan(observedDataSet, configurationPlan)
    }
    observedTime <- ospsuite::toUnit(
      quantityOrDimension = "Time",
      values = as.numeric(observedResults$data[, 1]),
      targetUnit = axesProperties$x$unit,
      sourceUnit = observedResults$metaData$time$unit
    )
    observedTime <- observedTime - timeOffset
    selectedObservedTimeValues <- observedTime >= 0 & observedTime <= simulationDuration
    observedTime <- observedTime[selectedObservedTimeValues]
    logDebug(paste0(
      "In Comparison Time Profile Plots, Observed Dataset '", observedDataSet, "'\n",
      messages$dataIncludedInTimeRange(
        sum(selectedObservedTimeValues),
        timeOffset + c(0, simulationDuration),
        axesProperties$x$unit,
        "observed"
      )
    ))

    observedValues <- ospsuite::toUnit(
      quantityOrDimension = ospsuite::getDimensionForUnit(observedResults$metaData$output$unit),
      values = observedResults$data[, 2],
      targetUnit = axesProperties$y$unit,
      sourceUnit = tolower(observedResults$metaData$output$unit),
      molWeight = molWeight
    )
    observedValues <- observedValues[selectedObservedTimeValues]
    observedResults$data <- observedResults$data[selectedObservedTimeValues, ]

    # Add observed errorbars
    if (!isEmpty(observedResults$metaData$error)) {
      observedError <- getObservedErrorValues(observedValues, observedResults, axesProperties, molWeight = molWeight)

      plotObject <- tlf::addErrorbar(
        x = observedTime,
        ymin = observedError$ymin,
        ymax = observedError$ymax,
        caption = prettyCaption(paste(outputMapping$Caption, "Observed Data"), plotObject),
        color = outputMapping$Color,
        size = outputMapping$Size,
        plotObject = plotObject
      )
    }
    # Add observed points
    plotObject <- tlf::addScatter(
      x = observedTime,
      y = observedValues,
      caption = prettyCaption(paste(outputMapping$Caption, "Observed Data"), plotObject),
      shape = tlfShape(outputMapping$Symbol),
      color = outputMapping$Color,
      size = outputMapping$Size,
      plotObject = plotObject
    )
  }
  return(plotObject)
}
