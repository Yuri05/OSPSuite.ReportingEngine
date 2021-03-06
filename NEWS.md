# ospsuite.reportingengine 1.2.0

## New features

* Descriptor of simulation sets is now available and can be defined in Excel template (#445) as well as using the function `setSimulationDescriptor` (#423).
* Each task property `settings` is now an R6 object (#396). This allows users to have an easy and direct access to setting properties.
* Posibility to read time and measurement units from nonmem columns (#414)

## Minor improvements and bug fixes

* Calculation of time profile residuals can use __Linear__ or __Logarithmic__ scale (#395).
* Units for observed data is appropriately taken into account within dictionary (#414).
* Settings for number format within reports are now available (#424).
They can be updated in global settings using `setDefaultNumericFormat` or within specific tasks through their `settings` property.
* The `settings` property for task `plotTimeProfilesAndResiduals` include 
* Application Ranges can be switched on/off from SimulationSet objects regarding simulations with multiple administrations (#419)
* Population workflows: captions for tables (PK parameters) missing (#421)
* Population workflows: units for tables (PK parameters) missing (#422)
* Population/RatioComparison: box-Whisker Ratio plots (#425)


# ospsuite.reportingengine 1.1.0

## New features

* `createWorkflowFromExcelInput` writes a commented workflow script ready to run based on Excel input file (#25). 
An Excel input file template is available at `system.file("extdata", "WorkflowInput.xlsx", package = "ospsuite.reportingengine")`

```R
excelFile <- system.file("extdata", "WorkflowInput.xlsx", package = "ospsuite.reportingengine")
workflowFile <- createWorkflowFromExcelInput(excelFile)
```

* `setWorkflowParameterDisplayPathsFromFile` overwrites display path names for simulation parameters in workflow `plotDemography` and `plotPKParameters` tasks (#399).
The input needs to be a csv file with `parameter` and `displayPath` in its header.

## Minor improvements and bug fixes

* Default `settings` in workflow `plotDemography` and `plotPKParameters` tasks improved the binning (#383).
* `bins` and `stairstep` are now included in `settings` options of workflow `plotDemography` and `plotPKParameters` tasks (#383).
