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
library(tidyr)

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

# Final df columns to select
final_cols <- c("date", "date_period_text", "value", "data_element_text", "data_measure_text", 
                "date_measure_text", "data_transform_text", "geo_entity_type_text", "geo_entity_text",
                "industry_text", "seas_adj_text", "viz_type_text")

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
# Adding CES data frame with code columns to the front of the list of code
# title reference data frames.
full_ce_df_list <- ces_raw %>% 
  mutate(
    seasonal_code = str_sub(series_id, 3, 3),
    industry_code = str_sub(series_id, 4, 11),
    data_type_code = str_sub(series_id, 12, 13),
    date = base::as.Date(paste0(year, "-", str_sub(period, 2, 3), "-01")),
    value = as.numeric(value)
  ) %>% 
  list(., ref_code_df_list) %>% 
  list_flatten()

# Iteratively joining each code title reference file onto main data frame with
# `dplyr::reduce()`
ces_full <- reduce(full_ce_df_list, left_join) %>% 
  mutate(data_type_text = str_to_title(
    str_remove(
      data_type_text,
      ",\\s+THOUSANDS"
      )
    ),
    geo_entity_type_text = "Nation",
    geo_entity_text = "US"
  ) %>% 
  rename(industry_text = industry_name,
         data_element_text = data_type_text)

### Analysis & Visualizations ###
## Time Series Line Graphs ##
# Payroll Employment year-over-year and month-over-month annualized
ces_emp_all_naics_yoy_mom_momann_df <- ces_full %>% 
  filter(!is.na(date),
         data_type_code == "01",
         seasonal_code == "S",
         industry_code %in% naics_supersectors
         ) %>% 
  arrange(industry_text, desc(date)) %>% 
  group_by(industry_code, industry_text) %>% 
  mutate(
    seas_adj_text = str_to_sentence(seasonal_text),
    date_period_text = "Monthly",
    data_measure_text = "Level",
    value = value * 1000,
    `Year-over-year|Percent change` = (value / lead(value, n = 12)) - 1,
    `Month-over-month|Raw` = (value - lead(value, n = 1)),
    `Month-over-month|Percent change;Annualized` = ((value / lead(value, n = 1)) ^ 12) - 1,
    `Current|Raw` = value) %>% 
  ungroup() %>% 
  select(-value) %>% 
  pivot_longer(cols = contains("|"),
               names_to = "date_measure_text-data_transform_text",
               values_to = "value") %>% 
  separate_wider_delim(cols = `date_measure_text-data_transform_text`,
                       delim = "|",
                       names = c("date_measure_text", "data_transform_text"))
  

ces_emp_ttlnf_yoy_mom_momann_df <- ces_emp_all_naics_yoy_mom_momann_df %>% 
  filter(industry_code == "00000000")

ces_emp_ttlnf_yoy_mom_momann_ts_line_df <- ces_emp_ttlnf_yoy_mom_momann_df %>% 
  mutate(viz_type_text = "Time series line") %>% 
  select(all_of(final_cols))

ces_emp_yoy_non_recession_avg <- get_avg_col_val(
  df = filter(ces_emp_ttlnf_yoy_mom_momann_df, date_measure_text == "Year-over-year"),
  dts = recession_dates,
  val_col = value,
  filter_type = "exclusive"
)

ces_emp_yoy_recession_avg <- get_avg_col_val(
  df = filter(ces_emp_ttlnf_yoy_mom_momann_df, date_measure_text == "Year-over-year"),
  dts = recession_dates,
  val_col = value,
  filter_type = "inclusive"
)

ces_emp_ttlnf_yoy_mom_momann_ts_line_last_2_yrs_df <- ces_emp_ttlnf_yoy_mom_momann_ts_line_df %>% 
  filter_recent_dates(24, "month") %>% 
  filter(str_detect(data_transform_text, "Percent change"))

econ_csv_write_out(ces_emp_ttlnf_yoy_mom_momann_ts_line_last_2_yrs_df,
                   "./data")

### TODO: Need to refactor make_ts_line_chart() function so it can dynamically
### handle selection of large line and small line as well as line colors
ces_emp_ttlnf_yoy_momann_ts_line_viz <- make_ts_line_chart(
  viz_df = ces_emp_ttlnf_yoy_mom_momann_ts_line_last_2_yrs_df,
  x_col = date,
  y_col = value,
  rec_avg_line = ces_emp_yoy_recession_avg,
  non_rec_avg_line = ces_emp_yoy_non_recession_avg,
  y_data_type = "percentage",
  viz_title = "Change in Total Nonfarm Payroll Employment",
  viz_subtitle = "<b style=\"color: #a6cee3\">Monthly annualized</b> and <b style = \"color: #1f78b4\">yearly</b>",
  viz_caption = paste("Non-recession average for data since Jan. '39.", base_viz_caption)
)

save_chart(ces_emp_ttlnf_yoy_momann_ts_line_viz, "./charts/")

# Average Hourly Earnings for total private year-over-year and month-over-month annualized
ces_earn_priv_yoy_momann_df <- ces_full %>% 
  filter(!is.na(date),
         data_type_code == "03",
         seasonal_code == "S",
         industry_code == "05000000"
  ) %>% 
  arrange(desc(date)) %>% 
  mutate(
    seas_adj_text = str_to_sentence(seasonal_text),
    date_period_text = "Monthly",
    data_measure_text = "Level",
    value = value * 1000,
    `Year-over-year|Percent change` = (value / lead(value, n = 12)) - 1,
    `Month-over-month|Percent change;Annualized` = ((value / lead(value, n = 1)) ^ 12) - 1,
    viz_type_text = "Time Series Line") %>% 
  ungroup() %>% 
  select(-value) %>% 
  pivot_longer(cols = contains("|"),
               names_to = "date_measure_text-data_transform_text",
               values_to = "value") %>% 
  separate_wider_delim(cols = `date_measure_text-data_transform_text`,
                       delim = "|",
                       names = c("date_measure_text", "data_transform_text")) %>% 
  select(all_of(final_cols))

ces_earn_priv_yoy_momann_last_2_yrs_df <- ces_earn_priv_yoy_momann_df %>% 
  filter_recent_dates(24, "month")

econ_csv_write_out(ces_earn_priv_yoy_momann_last_2_yrs_df,
                   "./data")

ces_earn_priv_yoy_momann_viz <- make_ts_line_chart(
  viz_df = ces_earn_priv_yoy_momann_last_2_yrs_df,
  x_col = date,
  y_col = value,
  y_data_type = "percentage",
  viz_title = "Change in Average Hourly Earnings",
  viz_subtitle = "<b style=\"color: #a6cee3\">Monthly annualized</b> and <b style = \"color: #1f78b4\">yearly</b> for all private sector workers",
  viz_caption = base_viz_caption
)

save_chart(ces_earn_priv_yoy_momann_viz, "./charts/")

## Bar Graphs ##
# Month-over-month raw change in nonfarm payroll employment
ces_emp_ttlnf_yoy_mom_momann_ts_bar_df <- ces_emp_ttlnf_yoy_mom_momann_df %>% 
  mutate(viz_type_text = "Time series bar") %>% 
  filter(date_measure_text == "Month-over-month", data_transform_text == "Raw") %>% 
  select(all_of(final_cols))

ces_emp_mom_non_recession_avg <- get_avg_col_val(
  df = filter(ces_emp_ttlnf_yoy_mom_momann_df, date_measure_text == "Month-over-month", data_transform_text == "Raw"),
  dts = recession_dates,
  val_col = value,
  filter_type = "exclusive"
)

ces_emp_mom_recession_avg <- get_avg_col_val(
  df = filter(ces_emp_ttlnf_yoy_mom_momann_df, date_measure_text == "Month-over-month", data_transform_text == "Raw"),
  dts = recession_dates,
  val_col = value,
  filter_type = "inclusive"
)

ces_emp_ttlnf_yoy_mom_momann_ts_bar_last_2_yrs_df <- ces_emp_ttlnf_yoy_mom_momann_ts_bar_df %>% 
  filter_recent_dates(24, "month")

econ_csv_write_out(ces_emp_ttlnf_yoy_mom_momann_ts_bar_last_2_yrs_df,
                   "./data")

ces_emp_ttlnf_mom_ts_bar_viz <- make_ts_bar_chart(
  viz_df = ces_emp_ttlnf_yoy_mom_momann_ts_bar_last_2_yrs_df,
  x_col = date,
  y_col = value,
  rec_avg_line = ces_emp_mom_recession_avg,
  non_rec_avg_line = ces_emp_mom_non_recession_avg,
  y_data_type = "number",
  viz_title = "Change in Total Nonfarm Payroll Employment",
  viz_subtitle = "Raw month-over-month",
  viz_caption = paste("Non-recession average for data since Jan. '39.", base_viz_caption)
)

save_chart(ces_emp_ttlnf_mom_ts_bar_viz, "./charts/")

# Year-over-year change in payroll employment by NAICS supersector
ces_emp_naics_ss_yoy_df <- ces_full %>% 
  filter(!is.na(date),
         data_type_code == "01",
         seasonal_code == "S",
         industry_code %in% naics_supersectors
  ) %>% 
  arrange(industry_text, desc(date)) %>% 
  filter(date %in% c(max(date, na.rm = T), max(date, na.rm = T) %m-% months(12))) %>%
  group_by(data_element_text, industry_text, 
           geo_entity_type_text, geo_entity_text, seasonal_text) %>% 
  summarize(
    value = (value[date == max(date)] / value[date != max(date)]) - 1,
    date = max(date),
    .groups = "drop",
  ) %>% 
  mutate(
    date_period_text = "Monthly",
    data_measure_text = "Level",
    date_measure_text = "Year-over-year",
    data_transform_text = "Percent change",
    seas_adj_text = str_to_sentence(seasonal_text),
    viz_type_text = "Bar"
    ) %>% 
  arrange(desc(value)) %>% 
  select(all_of(final_cols))

econ_csv_write_out(ces_emp_naics_ss_yoy_df, "./data")

ces_emp_naics_ss_yoy_viz <- make_pct_chg_bar_chart(
  viz_df = ces_emp_naics_ss_yoy_df,
  x_col = value,
  y_col = industry_text,
  viz_title = "Percent Change in Payroll Employment",
  viz_subtitle = "Year-over-year by NAICS Supersector",
  viz_caption = base_viz_caption
)

save_chart(ces_emp_naics_ss_yoy_viz, "./charts/")

# Faceted line graph by NAICS industry
ces_emp_naics_ss_yoy_mom_momann_ts_line_df <- ces_emp_all_naics_yoy_mom_momann_df %>% 
  filter(date_measure_text == "Year-over-year") %>% 
  mutate(viz_type_text = "Time series line") %>% 
  select(all_of(final_cols))

ces_emp_naics_ss_yoy_mom_momann_ts_line_last_2_yrs_df <- ces_emp_naics_ss_yoy_mom_momann_ts_line_df %>% 
  arrange(desc(date), desc(value)) %>% 
  filter_recent_dates(24, "month")

econ_csv_write_out(ces_emp_naics_ss_yoy_mom_momann_ts_line_last_2_yrs_df,
                   "./data")

most_recent_levels <- filter(
  ces_emp_naics_ss_yoy_mom_momann_ts_line_last_2_yrs_df,
  date == max(date)
) %>% 
  pull(industry_text)

ces_emp_naics_ss_yoy_mom_momann_ts_line_last_2_yrs_df <- ces_emp_naics_ss_yoy_mom_momann_ts_line_last_2_yrs_df %>% 
  mutate(industry_text = factor(industry_text, levels = most_recent_levels))

ces_emp_naics_ss_yoy_ts_line_faceted_viz <- make_ts_faceted_line_chart(
  viz_df = ces_emp_naics_ss_yoy_mom_momann_ts_line_last_2_yrs_df,
  x_col = date,
  y_col = value,
  facet_col = industry_text,
  y_data_type = "percentage",
  viz_title = "Change in Total Nonfarm Payroll Employment",
  viz_subtitle = "Year-over-year by NAICS Industry Supersector",
  viz_caption = paste("Non-recession average for data since Jan. '39.", base_viz_caption)
)

save_chart(ces_emp_naics_ss_yoy_ts_line_faceted_viz, "./charts/")

# Functionalize this chart and add the following features:
# 4. How to have lines be one color descending from largest gain/lowest loss to lowest gain/highest
# loss for most recent months of data
# 5. Maybe: How to have non-recession and recession average dashed lines for each facet?
# https://stackoverflow.com/questions/72563684/varying-geom-hline-for-each-facet-wrap-plot
# https://forum.posit.co/t/create-geom-hline-with-different-values-on-each-facet-grid/156627/16
# https://stackoverflow.com/questions/54244009/different-geom-hline-for-each-facet-of-ggplot
# https://stackoverflow.com/questions/50980134/display-a-summary-line-per-facet-rather-than-overall
# https://stackoverflow.com/questions/46327431/facet-wrap-add-geom-hline