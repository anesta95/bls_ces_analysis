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
ces_emp_ttlnf_yoy_mom_momann_df <- ces_full %>% 
  filter(!is.na(date),
         data_type_code == "01",
         seasonal_code == "S",
         industry_code == "00000000"
         ) %>% 
  arrange(desc(date)) %>% 
  mutate(
    value = value * 1000,
    yoy_chg = (value / lead(value, n = 12)) - 1,
    mom_chg_raw = (value - lead(value, n = 1)),
    mom_chg_ann = ((value / lead(value, n = 1)) ^ 12) - 1,
    val_type_text = "ts_line"
  ) %>% 
  select(date, value, yoy_chg, mom_chg_raw, mom_chg_ann, 
         data_type_text, industry_text, val_type_text)

ces_emp_yoy_non_recession_avg <- get_avg_col_val(
  df = ces_emp_ttlnf_yoy_mom_momann_df,
  dts = recession_dates,
  val_col = yoy_chg,
  filter_type = "exclusive"
)

ces_emp_yoy_recession_avg <- get_avg_col_val(
  df = ces_emp_ttlnf_yoy_mom_momann_df,
  dts = recession_dates,
  val_col = yoy_chg,
  filter_type = "inclusive"
)

ces_emp_ttlnf_yoy_mom_momann_last_2_yrs_df <- ces_emp_ttlnf_yoy_mom_momann_df %>% 
  filter(date >= max(date) %m-% months(24))

econ_csv_write_out(ces_emp_ttlnf_yoy_mom_momann_last_2_yrs_df,
                   "./data")

ces_emp_ttlnf_yoy_mom_momann_viz <- make_ts_line_chart(
  viz_df = ces_emp_ttlnf_yoy_mom_momann_last_2_yrs_df,
  x_col = date,
  y_col_one = yoy_chg,
  second_y_col = T,
  y_col_two = mom_chg_ann,
  rec_avg_line = ces_emp_yoy_recession_avg,
  non_rec_avg_line = ces_emp_yoy_non_recession_avg,
  y_data_type = "percentage",
  viz_title = "Change in Total Nonfarm Payroll Employment",
  viz_subtitle = "<b style=\"color: #a6cee3\">Monthly annualized</b> and <b style = \"color: #1f78b4\">yearly</b>",
  viz_caption = paste("Non-recession average for data since Jan. '39.", base_viz_caption)
)

save_chart(ces_emp_ttlnf_yoy_mom_momann_viz)

# Average Hourly Earnings for total private year-over-year and month-over-month annualized
ces_earn_ttlnf_yoy_momann_df <- ces_full %>% 
  filter(!is.na(date),
         data_type_code == "03",
         seasonal_code == "S",
         industry_code == "05000000"
  ) %>% 
  arrange(desc(date)) %>% 
  mutate(
    yoy_chg = (value / lead(value, n = 12)) - 1,
    mom_chg_ann = ((value / lead(value, n = 1)) ^ 12) - 1,
    val_type_text = "ts_line"
  ) %>% 
  select(date, yoy_chg, mom_chg_ann, data_type_text, industry_text, val_type_text)

ces_earn_ttlnf_yoy_momann_last_2_yrs_df <- ces_earn_ttlnf_yoy_momann_df %>% 
  filter(date >= max(date) %m-% months(24))

econ_csv_write_out(ces_earn_ttlnf_yoy_momann_last_2_yrs_df,
                   "./data")

ces_earn_ttlnf_yoy_momann_viz <- make_ts_line_chart(
  viz_df = ces_earn_ttlnf_yoy_momann_last_2_yrs_df,
  x_col = date,
  y_col_one = yoy_chg,
  second_y_col = T,
  y_col_two = mom_chg_ann,
  y_data_type = "percentage",
  viz_title = "Change in Average Hourly Earnings",
  viz_subtitle = "<b style=\"color: #a6cee3\">Monthly annualized</b> and <b style = \"color: #1f78b4\">yearly</b> for all private sector workers",
  viz_caption = base_viz_caption
)

save_chart(ces_earn_ttlnf_yoy_momann_viz)

# TODO: Make month-over-month bar chart for payroll employment with raw
# change in jobs for last two years.
ces_emp_mom_non_recession_avg <- get_avg_col_val(
  df = ces_emp_ttlnf_yoy_mom_momann_df,
  dts = recession_dates,
  val_col = mom_chg_raw,
  filter_type = "exclusive"
)

ces_emp_mom_recession_avg <- get_avg_col_val(
  df = ces_emp_ttlnf_yoy_mom_momann_df,
  dts = recession_dates,
  val_col = mom_chg_raw,
  filter_type = "inclusive"
)

ggplot(ces_emp_ttlnf_yoy_mom_momann_last_2_yrs_df, aes(x = date, 
                                                       y = mom_chg_raw, 
                                                       fill = mom_chg_raw)) + 
  coord_cartesian(
    xlim = c(min(ces_emp_ttlnf_yoy_mom_momann_last_2_yrs_df$date), max(ces_emp_ttlnf_yoy_mom_momann_last_2_yrs_df$date)),
    clip = "off") +
  geom_col() + 
  scale_x_date(date_labels = "%b. '%y") +
  geom_hline(yintercept = 0,
             color = "black",
             linewidth = 1.2,
             linetype = "solid"
  ) + 
  geom_text(aes(label = label_number(scale = 1, scale_cut = cut_short_scale())(mom_chg_raw), 
                vjust = if_else(mom_chg_raw > 0, -.15, 1.05)), 
            color = "black", 
            size = 5) + 
  scale_fill_steps2(low = "#8c510a", 
                    mid = "#f5f5f5", 
                    high = "#01665e", midpoint = 0, guide = "none") +
  scale_y_continuous(labels = label_number(scale = 1, big.mark = ",")) + 
  labs(
    title = "Change in Total Nonfarm Payroll Employment",
    subtitle = "Raw month-over-month",
    caption = paste("Non-recession average for data since Jan. '39.", base_viz_caption)
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 36, face = "bold", color = "black"),
    plot.margin = margin(20, 100, 20, 20, "pt"),
    plot.subtitle = element_text(size = 24, color = "black"),
    plot.caption = element_text(size = 10, color = "black"),
    axis.text = element_text(size = 14, color = "black", face = "bold", 
                               margin = margin(b = 15, t = 15, r = 5)),
    axis.title = element_blank()
  ) + geom_hline(yintercept = ces_emp_mom_non_recession_avg,
                 color = "black",
                 linewidth = 0.75,
                 linetype = "dashed"
  ) + annotate("text",
               x = get_x_annotation_val(diff(as.numeric(range(ces_emp_ttlnf_yoy_mom_momann_last_2_yrs_df$date, na.rm = T))), max(ces_emp_ttlnf_yoy_mom_momann_last_2_yrs_df$date)),
               y = ces_emp_mom_non_recession_avg,
               hjust = 0.5,
               label = "Non-recession\navg.",
               color = "black",
               size = 3.5,
               fontface = "bold")

# TODO: Functionalize monthly vertical nonfarm payroll employment bar chart.

# TODO: Make faceted line chart of YoY change in payroll employment and hourly earnings 
# by NAICS supersector with dashed line of non-recession/recession average

# TODO: Make faceted bar chart of MoM change in payroll employment by NAICS
# supersector.

# TODO: Make scatterplot of YoY change in payroll employment and average hourly
# earnings for all detailed industry with dashed lines for national averages
# and points colored by NAICS supersector.

