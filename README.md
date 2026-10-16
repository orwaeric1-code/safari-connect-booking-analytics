# Safari Connect | Bus & Matatu Booking Analytics

## Project Overview

Safari Connect is an end-to-end data analytics portfolio project focused on analyzing bus and matatu booking data to generate insights into transportation operations, revenue performance, customer behaviour, and booking outcomes.

The project uses SQL and PostgreSQL for data preparation and analysis, and Microsoft Power BI to develop an interactive dashboard that presents key performance indicators and business insights.

## Power BI Dashboard

![Safari Connect Power BI Dashboard](images/safari-connect-dashboard.png)

The interactive report was developed in Power BI to explore booking performance, completed-trip revenue, route and driver performance, customer ratings, and cancellations.

## Business Problem

Transportation businesses need reliable information to understand which routes generate the most revenue, how drivers and vehicles perform, how customers use booking services, and how cancellations and no-shows affect booking outcomes.

This project explores these questions using booking data to support evidence-based operational and business decisions.

## Project Objectives

- Assess and improve data quality.
- Clean and validate booking data using SQL and PostgreSQL.
- Analyze route, driver, revenue, and passenger performance.
- Investigate cancellations and no-shows.
- Develop an interactive Power BI dashboard.
- Translate analytical results into actionable business recommendations.

## Tools and Technologies

- **PostgreSQL** — Data storage, cleaning, querying, and analysis.
- **SQL** — Data transformation, validation, and business analysis.
- **DBeaver** — Database management and SQL development.
- **Microsoft Power BI** — Data modelling, visualization, and dashboard development.
- **GitHub** — Project documentation and portfolio presentation.

## Project Status

The SQL analysis and Power BI dashboard have been developed. This repository documents the project workflow, analytical findings, dashboard, and business recommendations.

## Dataset Description

The project uses bus and matatu booking data that includes information on bookings, passengers, routes, vehicles, drivers, travel dates, seat selections, fares, payment methods, booking statuses, and trip ratings.

The dataset supports analysis of transportation operations, revenue performance, customer booking patterns, and trip outcomes.

## Data Quality Assessment

Before conducting the analysis, the dataset was assessed for quality issues that could affect the reliability of the results.

The issues identified included:

- **Duplicate records:** A duplicate booking ID was identified during the initial assessment.
- **Missing values:** Some passenger phone numbers, passenger cities, and trip ratings were missing.
- **Inconsistent date formats:** Travel-date values used different formats and required standardization.
- **Inconsistent text values:** Some categorical values, including booking statuses and seat classes, had inconsistent capitalization or formatting.
- **Inconsistent fare formatting:** Some fare values contained currency text such as `KES`.
- **Invalid values:** The initial assessment identified a negative seat-booking value and a trip rating outside the expected range.

These issues were considered during data preparation and validation to improve consistency and support reliable analysis.

## Data Preparation Approach

The project workflow included staging the source data, assessing data quality, cleaning inconsistent values, validating the prepared data, and using SQL queries and analytical views to support business analysis.

The specific cleaning and validation steps are documented in the project's SQL scripts.

## SQL Data Cleaning and Validation

PostgreSQL was used to prepare the booking data for analysis. DBeaver was used as the database development environment for executing SQL statements and inspecting results.

The workflow included the following stages:

1. **Staging:** Load the source data into a staging table before applying cleaning transformations.
2. **Data inspection:** Examine records, column values, missing values, duplicate identifiers, and inconsistent formats.
3. **Data cleaning:** Standardize date formats, text values, fare formatting, and other identified data-quality issues.
4. **Data validation:** Run SQL checks to assess the consistency and validity of the prepared data.
5. **Production table preparation:** Store the prepared booking data in the analytical database table.
6. **Analytical preparation:** Use SQL queries, views, and indexes to support the business analysis.

The validation stage is important because successful execution of a cleaning query does not, by itself, prove that the resulting data is correct.

The detailed SQL statements and validation results will be documented in the repository's SQL scripts.
