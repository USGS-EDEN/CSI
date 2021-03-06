#' @title Import NERRS-format unit-value files for CSI calculation
#'
#' @description Read in NERRS-format unit value salinity file.
#'
#' @param file character The NERRS-format unit-value file to import (either through the Data Graphing and Export System or through the Advanced Query System; see website for reference: http://cdmo.baruch.sc.edu/get/landing.cfm).
#' @param mindays integer the minimum number of daily values (any number of values per day) needed to produce a mean value for a given month (default 15). Months with fewer data values than this will be asigned mean NA.
#'
#' @return A salinity object data.frame for calculating CSI values; has Year and Month timestamp columns, with column of site salinity values.
#'
#' @importFrom utils read.csv
#' @importFrom dplyr group_by summarize_all
#'
#' @export
#'
#' @examples
#' # NERRS-format data file
#' data_path <- system.file("extdata", "NIWDCWQ.csv.zip", package="CSI")
#' unzip(data_path, exdir = getwd())
#' sal <- CSIimport_NERRS("NIWDCWQ.csv")
#'
CSIimport_NERRS <- function (file, mindays = 15) {
  if (!(length(file) == 1) || !is.character(file))
    stop("file must be a single character string")
  if (!(length(mindays) == 1) || !is.numeric(mindays))
    stop("mindays must be a single numeric value")
  print("Importing data...")
  l1 <- readLines(file, n = 1)
  sk <- if (length(grep("^\\*", l1))) 2 else 0
  sal <- read.csv(file, skip = sk)
  names(sal)[1] <- "Station_Code"
  stn <- trimws(as.character(sal$Station_Code[1]))
  sal <- sal[trimws(as.character(sal$Station_Code)) == stn, ]
  sal <- sal[, c("DateTimeStamp", "Sal")]
  names(sal) <- c("Timestamp", stn)

  Year <- Month <- Day <- 'dplyr'
  sal$Date <- as.Date(sal$Timestamp, "%m/%d/%Y")
  sal$Year <- format(sal$Date, format = "%Y")
  sal$Month <- as.numeric(format(sal$Date, format = "%m"))
  sal$Day <- as.numeric(format(sal$Date, format = "%d"))
  sal <- sal[, -which(names(sal) == 'Timestamp')]
  sal <- sal[, -which(names(sal) == 'Date')]

  sal_daily <- group_by(sal, Year, Month, Day)
  sal_daily <- summarize_all(sal_daily, mean, na.rm = T)
  sal_daily <- as.data.frame(sal_daily)
  sal_daily <- sal_daily[, c(which(names(sal_daily) %in% c("Year", "Month", "Day")), which(!names(sal_daily) %in% c("Year", "Month", "Day")))]
  mo <- seq.Date(as.Date(paste(sal_daily$Year[1], sal_daily$Month[1], "01", sep = "-")), as.Date(paste(rev(sal_daily$Year)[1], rev(sal_daily$Month)[1], "01", sep = "-")), "month")
  for (i in 3:dim(sal_daily)[2])
    for (j in 1:length(mo))
      if (length(which(as.Date(paste(sal_daily$Year, sal_daily$Month, "01", sep = "-")) == mo[j] & !is.na(sal_daily[, i]))) < mindays) {
        print(paste(names(sal_daily)[i], substr(mo[j], 1, 7), "less than minimum", mindays, "days - removed"))
        sal_daily[which(as.Date(paste(sal_daily$Year, sal_daily$Month, "01", sep = "-")) == mo[j]), i] <- NA
      }
  # Find missing days and enter empty rows
  rng <- data.frame(Date = seq.Date(as.Date(paste(sal_daily$Year[1], sal_daily$Month[1], sal_daily$Day[1], sep = "-")), as.Date(paste(rev(sal_daily$Year)[1], rev(sal_daily$Month)[1], rev(sal_daily$Day)[1] , sep = "-")), by = "day"))
  rng$Year <- format(rng$Date, format = "%Y")
  rng$Month <- as.numeric(format(rng$Date, format = "%m"))
  rng$Day <- as.numeric(format(rng$Date, format = "%d"))
  rng <- rng[, -which(names(rng) == "Date")]
  sal_daily <- merge(rng, sal_daily, all.x = T)
  sal_daily <- sal_daily[order(sal_daily$Year, sal_daily$Month, sal_daily$Day), ]
  sal <- group_by(sal_daily, Year, Month)
  sal <- summarize_all(sal, mean, na.rm = T)
  sal <- as.data.frame(sal)
  sal <- sal[, -which(names(sal) == 'Day')]
  # Find missing months and enter empty rows
  rng <- data.frame(Date = seq.Date(as.Date(paste(sal$Year[1], sal$Month[1], "01", sep = "-")), as.Date(paste(rev(sal$Year)[1], rev(sal$Month)[1], "01" , sep = "-")), by = "month"))
  rng$Year <- format(rng$Date, format = "%Y")
  rng$Month <- as.numeric(format(rng$Date, format = "%m"))
  rng <- rng[, -which(names(rng) == "Date")]
  sal <- merge(rng, sal, all.x = T)
  sal <- sal[order(sal$Year, sal$Month), ]
  attr(sal, "daily_data") <- sal_daily

  return(sal)
}
