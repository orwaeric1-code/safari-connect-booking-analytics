-- ============================================================
-- SAFARI CONNECT - BUS & MATATU BOOKING PLATFORM
-- File: 03_validation_and_final_table.sql
-- Purpose: Validate cleaned data and load the final table
-- ============================================================

SET search_path TO safari_connect;

-- ============================================================
-- 1. Validate the cleaned staging data
-- ============================================================

-- Review remaining rows
SELECT COUNT(*) AS staging_row_count
FROM booking_staging;

-- Check departure date format
SELECT booking_id, departure_date
FROM booking_staging
WHERE departure_date IS NOT NULL
  AND departure_date !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

-- Check duplicate booking IDs
SELECT booking_id, COUNT(*) AS duplicate_count
FROM booking_staging
GROUP BY booking_id
HAVING COUNT(*) > 1;

-- Check non-positive seat counts
SELECT booking_id, seats_booked
FROM booking_staging
WHERE NULLIF(
    REGEXP_REPLACE(seats_booked, '[^0-9-]', '', 'g'),
    ''
)::INTEGER < 1;

-- ============================================================
-- 2. Create the final bookings table
-- ============================================================

CREATE TABLE IF NOT EXISTS bookings (
    booking_id       VARCHAR(10) PRIMARY KEY,
    passenger_name   VARCHAR(100),
    passenger_phone  VARCHAR(15),
    passenger_gender VARCHAR(10),
    passenger_city   VARCHAR(60),
    route_code       VARCHAR(10),
    route_from       VARCHAR(60),
    route_to         VARCHAR(60),
    vehicle_plate    VARCHAR(15),
    vehicle_type     VARCHAR(20),
    driver_name      VARCHAR(100),
    driver_rating    NUMERIC(3,1),
    departure_date   DATE,
    departure_time   VARCHAR(10),
    seat_class       VARCHAR(20),
    seats_booked     INTEGER,
    fare_per_seat    NUMERIC(10,2),
    total_fare       NUMERIC(12,2),
    payment_method   VARCHAR(20),
    booking_status   VARCHAR(20),
    trip_rating      INTEGER
);

-- ============================================================
-- 3. Load cleaned records into bookings
-- ============================================================

INSERT INTO bookings
SELECT
    booking_id,
    TRIM(passenger_name),
    NULLIF(TRIM(passenger_phone), ''),
    passenger_gender,
    COALESCE(NULLIF(TRIM(passenger_city), ''), 'Unknown'),
    route_code,
    route_from,
    route_to,
    vehicle_plate,
    INITCAP(TRIM(vehicle_type)),
    TRIM(driver_name),
    NULLIF(REGEXP_REPLACE(driver_rating, '[^0-9.]', '', 'g'), '')::NUMERIC,
    departure_date::DATE,
    departure_time,
    seat_class,
    NULLIF(REGEXP_REPLACE(seats_booked, '[^0-9]', '', 'g'), '')::INTEGER,
    NULLIF(REGEXP_REPLACE(fare_per_seat, '[^0-9.]', '', 'g'), '')::NUMERIC,
    NULLIF(REGEXP_REPLACE(total_fare, '[^0-9.]', '', 'g'), '')::NUMERIC,
    payment_method,
    booking_status,
    NULLIF(trip_rating, '')::INTEGER
FROM booking_staging
WHERE departure_date ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
  AND NULLIF(REGEXP_REPLACE(seats_booked, '[^0-9]', '', 'g'), '')::INTEGER > 0;

-- ============================================================
-- 4. Validate the final table
-- ============================================================

SELECT COUNT(*) AS final_booking_count
FROM bookings;

SELECT booking_status, COUNT(*) AS booking_count
FROM bookings
GROUP BY booking_status
ORDER BY booking_status;

SELECT seat_class, COUNT(*) AS booking_count
FROM bookings
GROUP BY seat_class
ORDER BY seat_class;

SELECT *
FROM bookings
LIMIT 10;

-- End of validation and final table workflow.
-- Analytical queries are documented in File 04.
