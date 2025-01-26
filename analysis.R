library(httr)
library(readr)
library(dplyr)
library(purrr)
library(stringr)
library(rlang)
library(lubridate)
library(ggplot2)
library(scales)
library(ggtext)

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
  "00000000", # Total nonfarm
  "10000000", # Mining and logging
  "20000000", # Construction
  "30000000", # Manufacturing
  "40000000", # Trade, transportation, and utilities
  "50000000", # Information
  "55000000", # Financial activities
  "60000000", # Professional and business services
  "65000000", # Private education and health services
  "70000000", # Leisure and hospitality
  "80000000", # Other services
  "90000000" # Government
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

# Getting accompanying code title reference files from the BLS parent directory
# here: https://download.bls.gov/pub/time.series/ce/
survey_abb <- "ce"
table_names <- c(
  "datatype",
  "industry",
  "seasonal"
)

# Looping through the various code title reference files and fetching
# them as data frames and putting them into a list.
ref_code_df_list <- map(table_names, function(x){
  ref_code_df <- get_bls_ref_code_table(survey_abb = survey_abb, x, email = user_email)
})

# Adding code columns from the `series_id` for each data aspect.
# Code locations from `series_id` referenced from here:
# https://www.bls.gov/help/hlpforma.htm#CE
ces_raw_codes <- ces_raw %>% 
  mutate(
    seasonal_code = str_sub(series_id, 3, 3),
    industry_code = str_sub(series_id, 4, 11),
    data_type_code = str_sub(series_id, 12, 13),
    date = base::as.Date(paste0(year, "-", str_sub(period, 2, 3), "-01")),
    value = as.numeric(value)
  )

# Adding CES data frame with code columns to the front of the list of code
# title reference data frames.
full_ce_df_list <- list_flatten(
  list(
    ces_raw_codes,
    ref_code_df_list
  )
)

# Iteratively joining each code title reference file onto main data frame with
# `dplyr::reduce()`
ces_full <- reduce(full_ce_df_list, left_join) %>% 
  mutate(data_type_text = str_to_title(
    str_remove(
      data_type_text,
      ",\\s+THOUSANDS"
      )
    )
  ) %>% 
  rename(industry_text = industry_name)

### Analysis & Visualizations ###
## Time Series Line Graphs ##
# Payroll Employment year-over-year and month-over-month annualized
ces_emp_ttlnf_yoy_momann_df <- ces_full %>% 
  filter(!is.na(date),
         data_type_code == "01",
         seasonal_code == "S",
         industry_code == "00000000"
         ) %>% 
  arrange(desc(date)) %>% 
  mutate(
    yoy_chg = (value / lead(value, n = 12)) - 1,
    mom_chg_ann = ((value / lead(value, n = 1)) ^ 12) - 1,
    val_type_text = "ts_line"
  ) %>% 
  select(date, yoy_chg, mom_chg_ann, data_type_text, industry_text, val_type_text)

ces_emp_yoy_non_recession_avg <- get_avg_col_val(
  df = ces_emp_ttlnf_yoy_momann_df,
  dts = recession_dates,
  val_col = yoy_chg
)

ces_emp_ttlnf_yoy_momann_last_yr_df <- ces_emp_ttlnf_yoy_momann_df %>% 
  filter(date >= max(date) %m-% months(12))

econ_csv_write_out(ces_emp_ttlnf_yoy_momann_last_yr_df,
                   "./data")

ces_emp_ttlnf_yoy_momann_viz <- make_ts_two_line_chart(
  viz_df = ces_emp_ttlnf_yoy_momann_last_yr_df,
  avg_line = ces_emp_yoy_non_recession_avg,
  x_col = date,
  y_col_one = mom_chg_ann,
  y_col_two = yoy_chg,
  viz_title = "Change in Payroll Nonfarm Employment",
  viz_subtitle = "<b style=\"color: #a6cee3\">Monthly annualized</b> and <b style = \"color: #1f78b4\">yearly</b>",
  viz_caption = paste("Non-recession average for data since Jan. '39.", base_viz_caption)
)

save_chart(ces_emp_ttlnf_yoy_momann_viz)
# TODO: Update `make_ts_two_line_chart` to optionally apply the `coord_cartesian()`,
# geom_hline(), and annotate() layers if the recession & non-recession averages
# are in the data range. 
# TODO: Make `y_col_two` argument (smaller light blue line) optional and only
# add on the `geom_line()` layer for it if supplied.
# TODO: Change `get_avg_col_val` function so that it can calculate average
# for dates supplied _or_ *not* for dates supplied.
# TODO: Change function so that it applies `scale_y_continuous()` based on function
# argument specifying if it is dollar label, percentage label, or no label
# TODO: Try out eliminating the `date_breaks` arguement in `scale_x_date()` to
# see if automatic labels fit better. If not, build in some logic based on the
# range of dates in the `date` column
# TODO: Apply all of these tweaks to the bls_jolts_analysis `make_ts_two_line_chart()`
# and see how the vizes look.

