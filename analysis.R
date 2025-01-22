library(httr)
library(readr)
library(tibble)
library(dplyr)
library(xml2)

# Importing R file with custom functions
source("functions.R")

### Objects Needed ###
# API Keys
con <- file(description = ".api_keys/fred.txt", open = "rt", blocking = F)
FRED_API_KEY <- readLines(con, n = 1)
close(con)

# Vector of the dates of the recessionary periods defined by the NBER from here:
# https://fred.stlouisfed.org/series/USREC
recession_dates_df <- get_fred_data("USREC", FRED_API_KEY)

recession_dates <- filter(recession_dates_df, value == 1L) %>% 
  pull(date)

# Vector of the two-digit NAICS codes for the BLS supersectors:
# https://www.bls.gov/sae/additional-resources/naics-supersectors-for-ces-program.htm
# https://download.bls.gov/pub/time.series/ce/ce.industry
naics_supersectors <- c(
  "00", # Total nonfarm
  "10", # Mining and logging
  "20", # Construction
  "30", # Manufacturing
  "40", # Trade, transportation, and utilities
  "50", # Information
  "55", # Financial activities
  "60", # Professional and business services
  "65", # Private education and health services
  "70", # Leisure and hospitality
  "80", # Other services
  "90", # Government
)

# Basic viz caption citation:
base_viz_caption <- "Seasonally adjusted as of MMM. 'YY\nSource: BLS Current Employment Statistics | Chart: Adrian Nesta"

### Data Collection ###
# Grabbing BLS CES full data file from here:
# https://download.bls.gov/pub/time.series/ce/ce.data.0.AllCESSeries

user_email <- "govdata.decimeter618@passmail.net"

message("Grabbing BLS CES data...")

ces_raw <- get_bls_data(
  url = "https://download.bls.gov/pub/time.series/ce/ce.data.0.AllCESSeries",
                          email = user_email
  )



