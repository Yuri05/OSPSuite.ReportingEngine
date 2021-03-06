#' @title QualificationWorkflow
#' @description  R6 class for Reporting Engine Qualification Workflow
#' @field configurationPlan `ConfigurationPlan` object
#' @field simulate `SimulationTask` object for time profile simulations
#' @field calculatePKParameters `CalculatePKParametersTask` object for PK parameters calculation
#' @field plotTimeProfiles `PlotTask` object for time profile plots
#' @field plotComparisonTimeProfiles `PlotTask` object for comparison of time profiles plots
#' @field plotGOFMerged `PlotTask` object for goodness of fit plots
#' @field plotPKRatio `PlotTask` object for PK ratio plot
#' @field plotDDIRatio `PlotTask` object for DDI ratio plot
#' @export
#' @import tlf
#' @import ospsuite
QualificationWorkflow <- R6::R6Class(
  "QualificationWorkflow",
  inherit = Workflow,

  public = list(
    configurationPlan = NULL,
    simulate = NULL,
    calculatePKParameters = NULL,
    plotTimeProfiles = NULL,
    plotGOFMerged = NULL,
    plotComparisonTimeProfiles = NULL,
    plotPKRatio = NULL,
    plotDDIRatio = NULL,

    #' @description
    #' Create a new `QualificationWorkflow` object.
    #' @param ... input parameters inherited from R6 class object `Workflow`.
    #' @param configurationPlan A `ConfigurationPlan` object
    #' @return A new `QualificationWorkflow` object
    #' @import ospsuite
    initialize = function(configurationPlan,
                          ...) {
      super$initialize(...)
      validateIsOfType(configurationPlan, "ConfigurationPlan")
      self$configurationPlan <- configurationPlan

      self$simulate <- loadSimulateTask(self, active = TRUE)
      self$calculatePKParameters <- loadCalculatePKParametersTask(self, active = TRUE)

      # TODO: include global plot & axes settings at this stage
      # -> could be including using the concept of Themes
      # -> updated using setting$plotConfigurations

      self$plotTimeProfiles <- loadPlotTimeProfilesTask(self, configurationPlan)
      self$plotGOFMerged <- loadGOFMergedTask(self, configurationPlan)
      self$plotComparisonTimeProfiles <- PlotTask$new() # loadComparisonPlotTimeProfilesTask(self, configurationPlan)
      self$plotPKRatio <- PlotTask$new() # loadPlotPKRatioTask(self, configurationPlan)
      self$plotDDIRatio <- PlotTask$new() # loadPlotDDIRatioTask(self, configurationPlan)

      self$taskNames <- ospsuite::enum(self$getAllTasks())
    },

    #' @description
    #' Run qualification workflow tasks for all simulation sets if tasks are activated
    #' The order of tasks is as follows:
    #' # 1) Run simulations
    #' # 2) Perform PK analyses
    #' # 3) Perform plot tasks
    #' ## 3.a) time profiles and residual plots
    #' ## 3.b) comparison time profiles plots
    #' ## 3.c) PK ratio tables and plots
    #' ## 3.d) DDI ratio tables and plots
    #' # 4) Render report
    #' @return All results and plots as a structured output in the workflow folder
    runWorkflow = function() {
      logWorkflow(
        message = "Starting run of qualification workflow",
        pathFolder = self$workflowFolder
      )

      # Before running the actual workflow,
      # Create Outputs for sections and copy intro and section content
      appendices <- createSectionOutput(self$configurationPlan, logFolder = self$workflowFolder)
      if (self$simulate$active) {
        self$simulate$runTask(self$simulationStructures)
      }

      if (self$calculatePKParameters$active) {
        self$calculatePKParameters$runTask(self$simulationStructures)
      }

      # The Configuration Plan replaces SimulationStructures for Qualification Workflows
      # since it directly indicates where to save and include results
      for (plotTask in self$getAllPlotTasks()) {
        if (self[[plotTask]]$active) {
          self[[plotTask]]$runTask(self$configurationPlan)
        }
      }

      # Merge appendices into final report
      mergeMarkdowndFiles(appendices, self$reportFileName, logFolder = self$workflowFolder)
      renderReport(self$reportFileName, logFolder = self$workflowFolder, createWordReport = self$createWordReport)
    }
  )
)
