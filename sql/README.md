# Safari Connect SQL Documentation

This folder contains the SQL scripts used to audit, clean, validate, analyze, and prepare the Safari Connect booking dataset for business intelligence reporting.

## SQL Workflow

| File | Purpose |
|---|---|
| `01_staging_and_data_audit.sql` | Creates the staging structure and assesses initial data quality. |
| `02_data_cleaning.sql` | Standardizes fields and addresses data quality issues. |
| `03_validation_and_final_table.sql` | Validates cleaned data and prepares the final bookings table. |
| `04_analytical_queries.sql` | Answers business questions about routes, drivers, revenue, passengers, cancellations, and operations. |
| `05_views_and_indexes.sql` | Creates reusable analytical views and indexes to support reporting and queries. |

## Execution Order

Run the scripts in numerical order, starting with the staging and audit script and ending with the views and indexes script.

**Prerequisites:** The source dataset must be imported into the staging table before cleaning begins. Review the SQL scripts and database state before rerunning any data-modifying statements.

## Key Analytical Areas

- Route and vehicle performance
- Driver performance and customer ratings
- Monthly revenue trends
- Passenger city and seat-class insights
- Booking cancellations and no-shows
- Operational patterns by departure day and time

## Notes

- SQL dialect: PostgreSQL
- Development environment: DBeaver
- The scripts are organized for readability and reproducibility.
- Fares associated with cancelled or no-show bookings should not automatically be interpreted as confirmed financial losses; recovery and refund information would be needed to establish that.
