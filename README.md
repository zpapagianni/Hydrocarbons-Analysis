# Hydrocarbons Analysis
### Exploratory analysis and Prediction

## Description

This study takes a data-driven approach to explore the degree to which the reactor calibration settings and composition of the feed hydrocarbon mixed influence the yield of hydrocarbon in a target range of densities. 

Hydrocarbons are chemical compounds with molecules consisting of hydrogen and carbon atoms. Hydrocracking is an industrial process in which hydrocarbons with molecules made of long chains of atoms are broken down into smaller molecules. This is done by the addition of hydrogen at high pressures and temperatures in the presence of a chemical catalyst. This process is used in the petrochemical industry to increase the proportion of extracted hydrocarbons that have shorter molecules, which are typically more useful to consumers and attract a higher profit on sale.

The process of hydrocracking can be controlled by adjusting the temperature of the reactor (or equivalently its pressure), the catalyst that is used and the time for which the hydrocarbon mixture is within the reactor. The composition of the effluent hydrocarbon mixture will depend on these settings of the reactor and on the composition of the feed hydrocarbon mixture that entered the reactor.
The most useful and valuable hydrocarbons are not the heaviest (most dense, with longest molecules) or the lightest (least dense, with smallest molecules), but those within a density in a specific, intermediate range. This is known as the target range.

This study uses a qualitative and quantitative approach to assess which of their control variables are most influential on the yield of hydrocarbon in the target range of densities. We will also predict the yield in this range for a given feed composition and reactor calibration. This would allow to not only maximise profits, but to minimise waste by calibrating reactor output to meet but not exceed demand.

The analysis contains parts:

* Exploratory analysis of the data
* Prediction
** Regularisation Methods
** Random Forest
** Gradient Boosting Machines (GBMs)
** Partial Least Squares Regression(PLS)

The data contains observations for 497 days of 44 variables, which detail the reactor settings and feed composition.In particular:

* Date: Dates from 15/10/2020 to 23/02/2022.
* Catalyst:  Which of 3 catalysts were used. Can be 0,1 or 2.
* Temperature:  Reactor temperature in degrees Fahrenheit.
* Through time: Reactor residence time of the mixture in hours. 
* feed fraction:Composition of the feed hydrocarbon mixtures as the proportion of the overall mass in each of 20 density intervals.
* out fraction:Composition of the effluent hydrocarbon mixtures as the proportion of the overall mass in each of 20 density intervals

Here are the different files:
* [Hydrocarbon-Analysis-HTML-Report.Rmd](./US-Energy-Consumption.Rmd):The rmarkdown file that contains the detailed step of the analysis.
* [Hydrocarbon-Analysis-HTML-Report.md](./Hydrocarbon-Analysis-HTML-Report.md): The github friendly document which contain the detailed step of the analysis,.
* [Hydrocabon Analysis.R](./US-Energy-Consumption.R): Contains the code that was used for the analysis.
* [data.csv](./data.csv): Input data.

## Environment

* [Rstudio]([https://www.rstudio.com/])

## Requirements

* [R version 4.1.1 (2021-08-10)](https://www.r-project.org/)

## Dependencies

Choose the latest versions of any of the dependencies below:
* dplyr
* ggplot2
* tidyverse
* tseries
* irlba
* randomForest
* caret
* PerformanceAnalytics
* gbm

## License

MIT. See the LICENSE file for the copyright notice.
