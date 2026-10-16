```sql
-- ============================================================
-- Safari Connect: Analytical Views and Database Indexes
-- File: 05_views_and_indexes.sql
-- Purpose: Create reusable analytical views and improve
--          query performance with indexes.
-- ============================================================

SET search_path TO safari_connect;

-- ============================================================
-- 1. Clean Trips View
-- Completed trips used for revenue and performance analysis.
-- ============================================================

CREATE OR REPLACE VIEW v_clean_trips AS
SELECT
    booking_id,
    passenger_name,
    passenger_gender,
    passenger_city,
    route_code,
    route_from,
    route_to,
    route_from || ' → ' || route_to AS route,
    vehicle_plate,
    vehicle_type,
    driver_name,
    driver_rating,
    departure_date,
    departure_time,
    TO_CHAR(departure_date, 'YYYY-MM') AS travel_month,
    TO_CHAR(departure_date, 'Month YYYY') AS month_label,
    TO_CHAR(departure_date, 'Day') AS day_name,
    EXTRACT(MONTH FROM departure_date)::INTEGER AS month_num,
    EXTRACT(ISODOW FROM departure_date)::INTEGER AS day_of_week,
    seat_class,
    seats_booked,
    fare_per_seat,
    total_fare,
    fare_per_seat * seats_booked AS calculated_fare,
    payment_method,
    booking_status,
    trip_rating,
    CASE
        WHEN trip_rating >= 4 THEN 'Satisfied'
        WHEN trip_rating = 3 THEN 'Neutral'
        WHEN trip_rating BETWEEN 1 AND 2 THEN 'Dissatisfied'
        ELSE 'Not Rated'
    END AS satisfaction
FROM bookings
WHERE booking_status = 'Completed';

-- ============================================================
-- 2. Route Performance View
-- ============================================================

CREATE OR REPLACE VIEW v_route_performance AS
SELECT
    route_code,
    route_from || ' → ' || route_to AS route,
    COUNT(*) AS total_bookings,
    SUM(seats_booked) AS total_seats,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(fare_per_seat), 2) AS avg_fare,
    ROUND(AVG(trip_rating), 2) AS avg_rating
FROM v_clean_trips
GROUP BY route_code, route_from, route_to;

-- ============================================================
-- 3. Driver Performance View
-- ============================================================

CREATE OR REPLACE VIEW v_driver_performance AS
SELECT
    driver_name,
    COUNT(*) AS total_trips,
    SUM(seats_booked) AS total_seats_carried,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(trip_rating), 2) AS avg_trip_rating,
    ROUND(AVG(driver_rating), 2) AS driver_rating
FROM v_clean_trips
GROUP BY driver_name;

-- ============================================================
-- 4. Monthly Revenue View
-- ============================================================

CREATE OR REPLACE VIEW v_monthly_revenue AS
WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') AS month,
        COUNT(*) AS bookings,
        SUM(total_fare) AS revenue
    FROM v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
    month,
    bookings,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month,
    revenue - LAG(revenue) OVER (ORDER BY month) AS change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100,
        1
    ) AS change_pct
FROM monthly;

-- ============================================================
-- 5. Cancellation and No-Show Analysis View
-- Includes all booking statuses, not only completed trips.
-- ============================================================

CREATE OR REPLACE VIEW v_cancellation_analysis AS
SELECT
    route_code,
    route_from || ' → ' || route_to AS route,
    COUNT(*) AS total,
    SUM(CASE WHEN booking_status = 'Completed'
        THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN booking_status = 'Cancelled'
        THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN booking_status = 'No Show'
        THEN 1 ELSE 0 END) AS no_show,
    ROUND(
        SUM(CASE
            WHEN booking_status IN ('Cancelled', 'No Show')
            THEN 1 ELSE 0
        END) * 100.0 / COUNT(*),
        1
    ) AS cancel_rate_pct
FROM bookings
GROUP BY route_code, route_from, route_to;

-- ============================================================
-- 6. Passenger City Insights View
-- Based on completed trips, with at least three trips per city.
-- ============================================================

CREATE OR REPLACE VIEW v_passenger_insights AS
SELECT
    passenger_city,
    COUNT(*) AS total_bookings,
    SUM(seats_booked) AS total_seats,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(fare_per_seat), 2) AS avg_fare
FROM v_clean_trips
GROUP BY passenger_city
HAVING COUNT(*) >= 3;

-- ============================================================
-- 7. Indexes
-- IF NOT EXISTS allows this section to be rerun safely.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_bookings_depdate
    ON bookings (departure_date);

CREATE INDEX IF NOT EXISTS idx_bookings_route
    ON bookings (route_code);

CREATE INDEX IF NOT EXISTS idx_bookings_driver
    ON bookings (driver_name);

CREATE INDEX IF NOT EXISTS idx_bookings_status
    ON bookings (booking_status);

CREATE INDEX IF NOT EXISTS idx_bookings_payment
    ON bookings (payment_method);

CREATE INDEX IF NOT EXISTS idx_bookings_vehicle
    ON bookings (vehicle_type);

CREATE INDEX IF NOT EXISTS idx_bookings_passcity
    ON bookings (passenger_city);

-- ============================================================
-- 8. Verification
-- ============================================================

SELECT table_name
FROM information_schema.views
WHERE table_schema = 'safari_connect'
ORDER BY table_name;

SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'safari_connect'
ORDER BY tablename, indexname;
```
