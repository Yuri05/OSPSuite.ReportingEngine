#' @title QualificationTask
#' @description  R6 class for QualificationTask settings
#' @export
QualificationTask <- R6::R6Class(
  "QualificationTask",
  inherit = PlotTask,

  public = list(
    #' @description
    #' Save results from task run.
    #' @param taskResults list of `TaskResults` objects
    #' @param configurationPlan A `ConfigurationPlan` object
    saveResults = function(taskResults, configurationPlan) {
      for (result in taskResults) {
        figureFilePath <- file.path(
          configurationPlan$getSectionPath(result$sectionId),
          getDefaultFileName(
            suffix = result$id,
            extension = ExportPlotConfiguration$format
          )
        )
        tableFilePath <- file.path(
          configurationPlan$getSectionPath(result$sectionId),
          getDefaultFileName(
            suffix = result$id,
            extension = "csv"
          )
        )

        # Figure and tables paths need to be relative to the final md report
        figureFileRelativePath <- gsub(
          pattern = paste0(self$workflowFolder, "/"),
          replacement = "",
          x = figureFilePath
        )
        tableFileRelativePath <- gsub(
          pattern = paste0(self$workflowFolder, "/"),
          replacement = "",
          x = tableFilePath
        )

        result$saveFigure(fileName = figureFilePath, logFolder = self$workflowFolder)
        result$saveTable(fileName = figureFilePath, logFolder = self$workflowFolder)

        result$addFigureToReport(
          reportFile = configurationPlan$getSectionMarkdown(result$sectionId),
          fileRelativePath = figureFileRelativePath,
          fileRootDirectory = self$workflowFolder,
          logFolder = self$workflowFolder
        )
        result$addTableToReport(
          reportFile = configurationPlan$getSectionMarkdown(result$sectionId),
          fileRelativePath = tableFileRelativePath,
          fileRootDirectory = self$workflowFolder,
          logFolder = self$workflowFolder
        )
      }
    },

    #' @description
    #' Run task and save its output
    #' @param configurationPlan A `ConfigurationPlan` object
    runTask = function(configurationPlan) {
      actionToken <- re.tStartAction(actionType = "TLFGeneration", actionNameExtension = self$nameTaskResults)
      logWorkflow(
        message = paste0("Starting: ", self$message),
        pathFolder = self$workflowFolder
      )
      if (self$validateInput()) {
        taskResults <- self$getTaskResults(
          configurationPlan,
          self$workflowFolder,
          self$settings
        )
        self$saveResults(taskResults, configurationPlan)
      }
      re.tEndAction(actionToken = actionToken)
    }
  )
)
