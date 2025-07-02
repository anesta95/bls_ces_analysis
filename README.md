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
* `date_period_text`: The time period that each row of the data captures. The most common formats are `Monthly`, `Quarterly`, and `Annually`. This will have a data type and class of `character`.
* `value`: The value that is being measured in the data. This will have a data type of `double` and a class of `numeric`.
* `data_element_text`: What the data in the `value` column describes. This will have a data type and class of `character`.
* `data_measure_text`: The mathematical expression the data in the `value` column is expressed as. The most common are `Level`, `Rate`, `Ratio`, `Percentage`, `Proportion`, and `Index`. This will have a data type and class of `character`.
* `date_measure_text`: The change in dates measured by the data in the `value` column. The most common are `Current`, `Year-over-year`, `Month-over-month` and `Quarter-over-quarter`. This will have a data type and class of `character`.
* `data_transform_text`: Any mathematical transformations applied to the data. The most common are `Raw`, `Percent change`, `Annualized`, `Trail N` where `N` is a number of periods in the `date_period_text` column. There can be multiple transformations for each row. Transformations are delimited by semi-colons `;` and are stated _in order of transformation_. For example, `Trail 3;Percent change` will be the percentage change between the trailing 3 period average of the current period — denoted in the `date` column — and the trailing 3 period average of the previous period which is deduced from the `date_measure_text`. Conversely, `Percent change;Trail 3` will be the trailing 3 period average applied to the percentage change between the current period and the previous period. This will have a data type and class of `character`.
* `geo_entity_type_text`: The geographic entity _type_ the data in the `value` column is covering. This will have a data type and class of `character`. If the region is in the United States there is a good chance it will be within the [Census Bureau Geographic Entity Hierarchy](https://www2.census.gov/geo/pdfs/reference/geodiagram.pdf).
* `geo_entity_text`: The name(s) geographic entity/entities that are described by the data.
* `viz_type_text`: The type of visualization made by the data in the `value` column. The most common are `Time series line`, `Bar`, `Map`, and `Scatter`. This will have a data type and class of `character`.

### Naming conventions
All graphics are PNG files in the `charts` directory. Every data visualization 
has a corresponding CSV file that was used to create it in the `data` directory.
Both CSVs and PNGs are named with the following format where each aspect of the 
data is delimited with a dash `-` and spaces are replaced with underscores `_`.

Data and visualization files will be named in the following order:

1. `date`
2. `date_period_text`
3. `data_element_text`
4. `data_measure_text`
5. `date_measure_text`
6. `data_transform_text`
7. `geo_entity_type_text`
8. `geo_entity_text`
9. _Any other aspects of the data specific to the release that are needed to uniquely identify it._ Examples include `industry_text`, `size_class_text`, `seas_adj_text`, among others.
10. `viz_type_text`

#### Examples
* CSV files: 
  * `2025-05-01_2023-05-01-monthly-all_employees-level-2_date_measure-2_data_transform-nation-us-total_nonfarm-seasonally_adjusted-time_series_line.csv`
  * `2025-05-01-monthly-all_employees-level-year-over-year-percent_change-nation-us-12_industry-seasonally_adjusted-bar.csv`
* PNG files: 
  * `2025-05-01_2023-05-01-monthly-all_employees-level-2_date_measure-2_data_transform-nation-us-total_nonfarm-seasonally_adjusted-time_series_line.png`
  * `2025-05-01-monthly-all_employees-level-year-over-year-percent_change-nation-us-12_industry-seasonally_adjusted-bar.png`

Every column in the dataset with the `_text` suffix will be included in the filename, in addition to the `date` column. Data files will also include columns that have further information that is _not_ needed to uniquely identify the data series. Examples of this include the `value` column, variables with the `_code` suffix such as `industry_code`, `fips_code`,`preliminary_code`, as well as `moe`, and `moe_level`, among others. 

This specific repository will have data with the following variables:
### Included data

| Variable Name     | Variable Data Class | Variable Description                                                                                                                                                                                                                                                                                                                                       |
| ----------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| date              | Date                | Date associated with data row. Will be in `YYYY-MM-DD` format. Monthly data will automatically be coded as the first day of said month, i.e. January 2025 is `2025-01-01`                                                                                                                                                                                  |
| date_period_text  | character           | The time period that each row of the data captures. Currently will be `monthly`.                                                                                                                                                                                                                                                                                |
| data_element_text | character           | The [data element](https://download.bls.gov/pub/time.series/ce/ce.datatype) that is represented by the `value` column. Currently one of `All Employees` or `Average hourly earnings`.                                                                                        |
| data_measure_text       | character           | The description of the what the numerical value the data in the `value` column is measuring. Currently `Level`.                                                                                                                                                                                                                           |
| date_measure_text | character           | The change in dates measured by the data in the value column. These currently includes `Year-over-year`, or `Month-over-month`. If multiple date measure are included, the chart filename will denote with `N_date_measure` where `N` is the number of date measures in the data file.                                                                                                                                                                                |
| data_transform_text       | character           | The description of what mathematical transformation(s) have been applied to the data in the `value` column. Multiple transformations delimited by semi-colons `;`. Can be `Raw` or `Percent change`. If multiple data transformations are included, the chart filename will denote with `N_data_transform` where `N` is the number of data transformations in the data file.                                                                                                                                                                                                                           |
| geo_entity_type_text  | character           | The geographic entity type that is present in the `geo_entity_text` column. This is currently `Nation`.                                                                                                                                                                                                                                                    |
| geo_entity_text       | character           | The name(s) geographic entity/entities that are described by the data. These are defined by the [U.S. Census Bureau](https://www2.census.gov/geo/pdfs/reference/geodiagram.pdf).                                                                                                                                                                                               |
| industry_text     | character           | The [NAICS supersector](https://www.bls.gov/sae/additional-resources/naics-supersectors-for-ces-program.htm) that the data is associated with. If multiple supersectors are included, the chart filename will denote with `N_industry` where `N` is the number of industries in the data file.                                                                                                                 |
| seas_adj_text     | character           | Text that will denote if the data in the `value` column is seasonally-adjusted or not.                                                                                                                                                                                                                                                                     |
| viz_type_text     | character           | The visualization type the data is used for. Currently one of `Time series line`, `Bar` which stand for time series line chart or bar chart.                                                                                                                                                                                          |