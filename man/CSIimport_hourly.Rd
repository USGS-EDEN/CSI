% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CSIimport_unit.R
\name{CSIimport_hourly}
\alias{CSIimport_hourly}
\title{Import hourly-value files for CSI calculation}
\usage{
CSIimport_hourly(file, mindays = 15)
}
\arguments{
\item{file}{character The hourly-value file to import. Must have Year, Month, Day, and Time columns, or single Timestamp = 'YYYY-MM-DD HH:mm:ss', and columns of salinty values by site.}

\item{mindays}{integer the minimum number of daily values (any number of values per day) needed to produce a mean value for a given month (default 15). Months with fewer data values than this will be asigned mean NA.}
}
\description{
Read in hourly value salinity file.

Alias of CSIimport_unit.
}
