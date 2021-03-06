% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/excel-messages.R
\name{ExcelMessaging}
\alias{ExcelMessaging}
\title{ExcelMessaging}
\description{
R6 class for tracking and printing messages for the Excel template
}
\section{Public fields}{
\if{html}{\out{<div class="r6-fields">}}
\describe{
\item{\code{type}}{"warnings" or "errors" (could potentially include other kind of information)}

\item{\code{messages}}{list of messages included in each script section}
}
\if{html}{\out{</div>}}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-new}{\code{ExcelMessaging$new()}}
\item \href{#method-displayMessage}{\code{ExcelMessaging$displayMessage()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-new"></a>}}
\if{latex}{\out{\hypertarget{method-new}{}}}
\subsection{Method \code{new()}}{
Initialize an `ExcelMessaging` object
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ExcelMessaging$new(type)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{type}}{"warnings" or "errors"}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
A new `ExcelMessaging` object
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-displayMessage"></a>}}
\if{latex}{\out{\hypertarget{method-displayMessage}{}}}
\subsection{Method \code{displayMessage()}}{
display the messages stored in messages
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{ExcelMessaging$displayMessage()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
Messages content
}
}
}
