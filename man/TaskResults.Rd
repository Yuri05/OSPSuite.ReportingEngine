% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/task-results.R
\name{TaskResults}
\alias{TaskResults}
\title{TaskResults}
\description{
R6 class for TaskResults settings
}
\section{Public fields}{
\if{html}{\out{<div class="r6-fields">}}
\describe{
\item{\code{id}}{unique identifer of results, helps in deriving final plot name}

\item{\code{sectionId}}{unique identifer of section results, used only by qualification workflows}

\item{\code{plot}}{`ggplot` object corresponding to the figure to be saved}

\item{\code{plotCaption}}{text included into the report explaining the figure}

\item{\code{includePlot}}{logical indicating if the plot should be included in final report}

\item{\code{table}}{data.frame corresponding to the table to be saved}

\item{\code{tableCaption}}{text included into the report explaining the table}

\item{\code{includeTable}}{logical indicating if the table should be included in final report}
}
\if{html}{\out{</div>}}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-saveFigure}{\code{TaskResults$saveFigure()}}
\item \href{#method-saveTable}{\code{TaskResults$saveTable()}}
\item \href{#method-addFigureToReport}{\code{TaskResults$addFigureToReport()}}
\item \href{#method-addTableToReport}{\code{TaskResults$addTableToReport()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-saveFigure"></a>}}
\if{latex}{\out{\hypertarget{method-saveFigure}{}}}
\subsection{Method \code{saveFigure()}}{
If table is not null, save table as a csv file at `tableFileName`
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{TaskResults$saveFigure(fileName, logFolder = getwd())}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{fileName}}{path of file corresponding to the figure to save}

\item{\code{logFolder}}{folder were logs are saved}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-saveTable"></a>}}
\if{latex}{\out{\hypertarget{method-saveTable}{}}}
\subsection{Method \code{saveTable()}}{
If table is not null, save table as a csv file at `tableFileName`
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{TaskResults$saveTable(fileName, logFolder = getwd())}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{fileName}}{path of csv file corresponding to the table to save}

\item{\code{logFolder}}{folder were logs are saved}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-addFigureToReport"></a>}}
\if{latex}{\out{\hypertarget{method-addFigureToReport}{}}}
\subsection{Method \code{addFigureToReport()}}{
Add table results to a
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{TaskResults$addFigureToReport(
  reportFile,
  fileRelativePath,
  fileRootDirectory,
  logFolder = getwd()
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{reportFile}}{file in which the figure and its caption should be added}

\item{\code{fileRelativePath}}{path of file relative to reportFile corresponding saved figure}

\item{\code{fileRootDirectory}}{root directory of figure file path}

\item{\code{logFolder}}{folder were logs are saved}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-addTableToReport"></a>}}
\if{latex}{\out{\hypertarget{method-addTableToReport}{}}}
\subsection{Method \code{addTableToReport()}}{
Add table results to a
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{TaskResults$addTableToReport(
  reportFile,
  fileRelativePath,
  fileRootDirectory,
  logFolder = getwd()
)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{reportFile}}{file in which the table and its caption should be added}

\item{\code{fileRelativePath}}{path of file relative to reportFile corresponding saved figure}

\item{\code{fileRootDirectory}}{root directory of figure file path}

\item{\code{logFolder}}{folder were logs are saved}
}
\if{html}{\out{</div>}}
}
}
}
