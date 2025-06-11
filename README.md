# BLS Current Employment Statistics Analysis

This project contains code that downloads, analyzes, and visualizes data
from the [Current Employment Statistics Survey](https://www.bls.gov/ces/) (CES) a.k.a the payroll/establishment survey  
that is run monthly by the U.S. Department of Labor's Bureau of Labor Statistics. 

Data analysis and visualization is executed by the [R](https://www.r-project.org/) 
code in the `analysis.R` and `functions.R` files in the top-level directory.
Project libraries and other resources needed to run the code can be managed through 
the [renv](https://rstudio.github.io/renv/) reproducible environment in the `renv`
folder and `renv.lock` and `.Rprofile` files in the top-level directory.

Details about data measures and data and graphics files are provided below.

## Data Measures

This project currently analyzes the following [data estimates](https://www.bls.gov/opub/hom/ces/concepts.htm) from CES:

* __Employment__: Employment is the measure of the number of jobs, as opposed to the number of employees. Specifically, this is persons on _establishment_ payrolls who received pay for any part of the pay period that includes the 12th day of the month.
  * __Establishment__: An establishment is an economic unit, such as a factory, mine, store, office, or government worksite that produces goods or provides services.
* __Average hourly earnings__: (AHE) are the aggregate weekly payroll divided by aggregate weekly hours.
  * __Aggregate payroll__: Aggregate payroll is the total regular pay earned by employees during the reference pay period. Specficially, this is the total amount of money earned by full and part-time employees who received pay for any part of the pay period that includes the 12th day of the month. This includes overtime pay, holiday and vacation pay, sick leave paid directly by the employer, and commissions paid at least monthly. This does not include employee benefits paid by the employer (such as health and other types of insurance, contributions to retirement, etc.), deductions of any kind, such as old-age and unemployment insurance, group insurance, withholding tax, bonds, or union dues, bonuses (unless earned and paid regularly each pay period), retroactive pay, and the value of free rent, fuel, meals, or other payments in kind.
  * __Aggregate hours__: Aggregate hours are the total hours for which employees are paid. For the reference pay period, aggregate hours include all hours worked (including overtime hours), hours paid for standby or reporting time, and equivalent hours for which employees received pay directly from the employer for sick leave, holidays, vacations, and other leave. Overtime and other premium pay hours are not converted to straight-time equivalent hours. 

## Data Files and Graphics

### Data conventions
Every econ analysis data CSV file at minimum will have the following columns:
* `date`: The date associated with the data in the data row. The date will be in `YYYY-MM-DD` format regardless of the time period the date captures. All dates will be the first day of the time period. For example, data for April 2025 will be displayed as `2025-04-01`. Data for Q2 2025 will be `2025-04-01`. Data for the year 2025 will be `2025-01-01`. This will have a data type `double` with a class of `Date`.
* `date_period_text`: The time period that each row of the data captures. The most common formats are `monthly`, `quarterly`, and `annually`. This will have a data type and class of `character`.
* `value`: The value that is being measured in the data. This will have a data type of `double` and a class of `numeric`.
* `data_element_text`: What the data in the `value` column is measuring. This will have a data type and class of `character`.
* `metric_text`: The mathematical expression the data in the `value` column is expressed as. The most common are `level`, `rate`, `ratio`, `percentage`, `proportion`, and `index`. This will have a data type and class of `character`.
* `date_measure_text`: The change in dates measured by the data in the `value` column. The most common are `current`, `year-over-year`, `month-over-month` and `quarter-over-quarter`. This will have a data type and class of `character`.
* `geo_entity_type_text`: The geographic entity _type_ the data in the `value` column is covering. This will have a data type and class of `character`. If the region is in the United States there is a good chance it will be within the [Census Bureau Geographic Entity Hierarchy](https://www2.census.gov/geo/pdfs/reference/geodiagram.pdf).
* `geo_entity_text`: The name(s) geographic entity/entities that are described by the data.
* `viz_type_text`: The type of visualization made by the data in the `value` column. The most common are `time series line`, `bar`, `map`, and `scatter`. This will have a data type and class of `character`.

### Naming conventions
All graphics are PNG files in the `charts` directory. Every data visualization 
has a corresponding CSV file that was used to create it in the `data` directory.
Both CSVs and PNGs are named with the following format where each aspect of the 
data is delimited with a dash `-` and spaces are replaced with underscores `_`.

Data and visualization files will be named in the following order:

1. `date`
2. `data_element_text`
3. `metric_text`
4. `date_period_text`
5. `date_measure_text`
6. `geo_entity_type_text`
7. `geo_entity_text`
8. _Any other aspects of the data specific to the release that are needed to uniquely identify it._ Examples include `industry_text`, `size_class_text`, `seas_adj_text`, among others.
9. `viz_type_text`

#### Examples

_These need to be updated with new data variables_
* CSV file: `2024-11-01-employment-level-monthly-2_date_measure-total_nonfarm-nation-us-seasonally_adjusted-time_series_line.csv`
* PNG file: `2024-11-01-employment-level-monthly-2_date_measure-total_nonfarm-nation-us-seasonally_adjusted-time_series_line.png`

Every column in the dataset with the `_text` suffix will be included in the filename, in addition to the `date` column. Data files will also include columns that have further information that is _not_ needed to uniquely identify the data series. Examples of this include the `value` column or any columns with the `value_` prefix, variables with the `_code` suffix such as `industry_code`, `fips_code`,`preliminary_code`, as well as `moe`, and `moe_level`, among others. 

This specific repository will have data with the following variables:
### Included data

| Variable Name     | Variable Data Class | Variable Description                                                                                                                                                                                                                                                                                                                                       |
| ----------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| date              | Date                | Date associated with data row. Will be in `YYYY-MM-DD` format. Monthly data will automatically be coded as the first day of said month, i.e. January 2025 is `2025-01-01`                                                                                                                                                                                  |
| data_element_text | character           | The [data element](https://download.bls.gov/pub/time.series/jt/jt.dataelement) that is represented by the `value` column. One of `hires`, `job openings`, `labor leverage ratio`, `layoffs and discharges`, `quits`, or `unemployed persons per job opening ratio`.                                                                                        |
| metric_text       | character           | The description of the what the numerical value the data in the `value` column is measuring. One of `rate`, `ratio`, or `level`.                                                                                                                                                                                                                           |
| date_period_text  | character           | The time period that each row of the data captures. This will be `monthly`.                                                                                                                                                                                                                                                                                |
| date_measure_text | character           | The change in dates measured by the data in the value column. These will include `cur` for current, `yoy` for year-over-year change and `mom` for month-over-month change.                                                                                                                                                                                 |
| geo_entity_type_text  | character           | The geographic entity type that is present in the `geo_entity_text` column. This will be either `nation` or `state`.                                                                                                                                                                                                                                                    |
| geo_entity_text       | character           | The name(s) geographic entity/entities that are described by the data. These are defined by the [U.S. Census Bureau](https://www2.census.gov/geo/pdfs/reference/geodiagram.pdf).                                                                                                                                                                                               |
| industry_text     | character           | The [NAICS supersector](https://www.bls.gov/sae/additional-resources/naics-supersectors-for-ces-program.htm) that the data is associated with. If every separate supersector is included, the chart filename will denote `every_industry`.                                                                                                                 |
| size_class_text   | character           | The [firm size class](https://download.bls.gov/pub/time.series/jt/jt.sizeclass) that the data is associated with. If every separate firm size class is included, the chart filename will denote `every_size_class`.                                                                                                                                        |
| seas_adj_text     | character           | Text that will denote if the data in the `value` column is seasonally-adjusted or not.                                                                                                                                                                                                                                                                     |
| viz_type_text     | character           | The visualization type the data is used for. One of `ts_line`, `bar`, `map`, or `scatter` which stand for time series line chart, bar chart map and scatter plot.                                                                                                                                                                                          |
| state_abb         | character           | The two character [USPS state abbreviation](https://www.bls.gov/respondents/mwr/electronic-data-interchange/appendix-d-usps-state-abbreviations-and-fips-codes.htm) that the data is associated with. *This figure is only present in data files with a `viz_type_text` of `cur_scatter`. This figure is __not__ included in the data or chart filenames.* |
| fips_code         | character           | The two digit [FIPS code](https://www.bls.gov/respondents/mwr/electronic-data-interchange/appendix-d-usps-state-abbreviations-and-fips-codes.htm) that the data is associated with. *This figure is only present in data files with a `viz_type_text` of `cur_scatter`. This figure is __not__ included in the data or chart filenames.*                   |
| preliminary_code  | character           | A code that denotes if the data in the `value` column in the row is preliminary. Will be `P` if so and `NA` if not.                                                                                                                                                                                                                                        |
| Layoffs Rate      | numeric             | The actual numeric value of the layoffs rate associated with the data. *This figure is only present in data files with a `viz_type_text` of `cur_scatter`. This figure is __not__ included in the data or chart filenames.*                                                                                                                                |
| Quits Rate        | numeric             | The actual numeric value of the quits rate associated with the data. *This figure is only present in data files with a `viz_type_text` of `cur_scatter`. This figure is __not__ included in the data or chart filenames.*                                                                                                                                  |
| value             | numeric             | The actual numerical value of data that is described by the columns with the `_text` suffix. *This figure is __not__ included in the data or chart filenames.*                                                                                                                                                                                             |
| value_trail_three | numeric             | The trailing three-month average of the `value` column. *This is only present in data files with a `viz_type_text` of `ts_line` since those are the only visualizations that contain __both__ raw and three-month trailing average values. This figure is __not__ included in the data or chart filenames.*                                                |