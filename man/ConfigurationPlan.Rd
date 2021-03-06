% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/configuration-plan.R
\name{ConfigurationPlan}
\alias{ConfigurationPlan}
\title{ConfigurationPlan}
\description{
R6 class for ConfigurationPlan guiding Qualification Workflow
}
\section{Public fields}{
\if{html}{\out{<div class="r6-fields">}}
\describe{
\item{\code{plots}}{list defining `PlotConfiguration` settings for specific tasks}

\item{\code{inputs}}{data.frame or list mapping input files to their paths}

\item{\code{intro}}{data.frame or list mapping introduction files to their paths}

\item{\code{markdownIntro}}{name of markdown file that includes intro content}

\item{\code{referenceFolder}}{Reference path for accessing inputs}

\item{\code{workflowFolder}}{path of the output folder created or used by the Workflow.}
}
\if{html}{\out{</div>}}
}
\section{Active bindings}{
\if{html}{\out{<div class="r6-active-bindings">}}
\describe{
\item{\code{sections}}{data.frame mapping section ids to their paths}

\item{\code{simulationMappings}}{data.frame mapping simulations to their paths}

\item{\code{observedDataSets}}{data.frame mapping observed datasets to their paths}
}
\if{html}{\out{</div>}}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-getSectionPath}{\code{ConfigurationPlan$getSectionPath()}}
\item \href{#method-getSectionTitle}{\code{ConfigurationPlan$getSectionTitle()}}
\item \href{#method-getSectionMarkdown}{\code{ConfigurationPlan$getSectionMarkdown()}}
\item \href{#method-getIntroMarkdown}{\code{ConfigurationPlan$getIntroMarkdown()}}
\item \href{#method-copySectionContent}{\code{ConfigurationPlan$copySectionContent()}}
\item \href{#method-copyInput}{\code{ConfigurationPlan$copyInput()}}
\item \href{#method-copyIntro}{\code{ConfigurationPlan$copyIntro()}}
\item \href{#method-getObservedDataPath}{\code{ConfigurationPlan$getObservedDataPath()}}
\item \href{#method-getSimulationPath}{\code{ConfigurationPlan$getSimulationPath()}}
\item \href{#method-getSimulationResultsPath}{\code{ConfigurationPlan$getSimulationResultsPath()}}
\item \href{#method-getPKAnalysisResultsPath}{\code{ConfigurationPlan$getPKAnalysisResultsPath()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-getSectionPath"></a>}}
\if{latex}{\out{\hypertarget{method-getSectionPath}{}}}
\subsection{Method \code{getSectionPath()}}{
Get location of directory corresponding to a specific section Id
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$getSectionPath(id)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{id}}{section identifier}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
The section path corresponding to the id in the configuration plan field `sections`
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-getSectionTitle"></a>}}
\if{latex}{\out{\hypertarget{method-getSectionTitle}{}}}
\subsection{Method \code{getSectionTitle()}}{
Get markdown title to a specific section Id
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$getSectionTitle(id)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{id}}{section identifier}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
The title associated with "#" corresponding to the subection level
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-getSectionMarkdown"></a>}}
\if{latex}{\out{\hypertarget{method-getSectionMarkdown}{}}}
\subsection{Method \code{getSectionMarkdown()}}{
Get location of .md file corresponding to a specific section Id
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$getSectionMarkdown(id)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{id}}{section identifier}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
The markdown file corresponding to the id in the configuration plan field `sections`
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-getIntroMarkdown"></a>}}
\if{latex}{\out{\hypertarget{method-getIntroMarkdown}{}}}
\subsection{Method \code{getIntroMarkdown()}}{
Get location of .md intro file
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$getIntroMarkdown()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
The markdown file corresponding to introduction
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-copySectionContent"></a>}}
\if{latex}{\out{\hypertarget{method-copySectionContent}{}}}
\subsection{Method \code{copySectionContent()}}{
Copy content to section markdown
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$copySectionContent(id, logFolder = getwd())}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{id}}{section identifier}

\item{\code{logFolder}}{path where logs are saved}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-copyInput"></a>}}
\if{latex}{\out{\hypertarget{method-copyInput}{}}}
\subsection{Method \code{copyInput()}}{
Copy input to section markdown
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$copyInput(input, logFolder = getwd())}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{input}}{list including SectionId and Path}

\item{\code{logFolder}}{path where logs are saved}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-copyIntro"></a>}}
\if{latex}{\out{\hypertarget{method-copyIntro}{}}}
\subsection{Method \code{copyIntro()}}{
Copy intro to intro markdown
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$copyIntro(intro, logFolder = getwd())}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{intro}}{list including Path}

\item{\code{logFolder}}{path where logs are saved}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-getObservedDataPath"></a>}}
\if{latex}{\out{\hypertarget{method-getObservedDataPath}{}}}
\subsection{Method \code{getObservedDataPath()}}{
Get location of observed data corresponding to a specific observedDataSet Id
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$getObservedDataPath(id)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{id}}{observedDataSet identifier}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
The observed data file path corresponding to the id in the configuration plan field `observedDataSet`
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-getSimulationPath"></a>}}
\if{latex}{\out{\hypertarget{method-getSimulationPath}{}}}
\subsection{Method \code{getSimulationPath()}}{
Get location of simulation file corresponding to a specific simulation and project names
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$getSimulationPath(project, simulation)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{project}}{name of simulation project}

\item{\code{simulation}}{name of the simulation}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
The simulation file path corresponding to the project and simulation in the configuration plan field `simulationMappings`
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-getSimulationResultsPath"></a>}}
\if{latex}{\out{\hypertarget{method-getSimulationResultsPath}{}}}
\subsection{Method \code{getSimulationResultsPath()}}{
Get location of simulation result file corresponding to a specific simulation and project names
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$getSimulationResultsPath(project, simulation)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{project}}{name of simulation project}

\item{\code{simulation}}{name of the simulation}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
The simulation results file path corresponding to the project and simulation in the configuration plan field `simulationMappings`
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-getPKAnalysisResultsPath"></a>}}
\if{latex}{\out{\hypertarget{method-getPKAnalysisResultsPath}{}}}
\subsection{Method \code{getPKAnalysisResultsPath()}}{
Get location of PK Analysis result file corresponding to a specific simulation and project names
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ConfigurationPlan$getPKAnalysisResultsPath(project, simulation)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{project}}{name of simulation project}

\item{\code{simulation}}{name of the simulation}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
The PKAnalysis results file path corresponding to the project and simulation in the configuration plan field `simulationMappings`
}
}
}
