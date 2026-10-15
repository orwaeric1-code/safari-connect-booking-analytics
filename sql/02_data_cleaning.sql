-- ============================================================
-- SAFARI CONNECT - BUS & MATATU BOOKING PLATFORM
-- File: 02_data_cleaning.sql
-- Purpose: Standardize and clean the staging data
-- ============================================================

SET search_path TO safari_connect;

-- IMPORTANT:
-- Review affected rows with SELECT queries before updates.
-- Run this workflow against a working copy of the staging data.

-- ============================================================
-- 1. Clean passenger names
-- Standardize capitalization and remove surrounding spaces.
-- ============================================================

SELECT booking_id, passenger_name
FROM booking_staging
WHERE passenger_name IS DISTINCT FROM INITCAP(TRIM(passenger_name));

UPDATE booking_staging
SET passenger_name = INITCAP(TRIM(passenger_name))
WHERE passenger_name IS DISTINCT FROM INITCAP(TRIM(passenger_name));

-- ============================================================
-- 2. Clean passenger phone numbers
-- Remove non-numeric characters and normalize +254 numbers.
-- ============================================================

UPDATE booking_staging
SET passenger_phone = REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g')
WHERE passenger_phone LIKE '%-%';

UPDATE booking_staging
SET passenger_phone =
    '0' || SUBSTRING(REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g') FROM 4)
WHERE passenger_phone LIKE '+254%';

UPDATE booking_staging
SET passenger_phone = NULL
WHERE TRIM(passenger_phone) = '';

UPDATE booking_staging
SET passenger_phone = TRIM(passenger_phone)
WHERE passenger_phone IS DISTINCT FROM TRIM(passenger_phone);

-- ============================================================
-- 3. Standardize passenger gender
-- ============================================================

UPDATE booking_staging
SET passenger_gender = CASE
    WHEN UPPER(TRIM(passenger_gender)) IN ('MALE', 'M') THEN 'Male'
    WHEN UPPER(TRIM(passenger_gender)) IN ('FEMALE', 'F') THEN 'Female'
    ELSE TRIM(passenger_gender)
END;

-- ============================================================
-- 4. Standardize passenger city
-- ============================================================

UPDATE booking_staging
SET passenger_city = INITCAP(TRIM(passenger_city))
WHERE passenger_city IS DISTINCT FROM INITCAP(TRIM(passenger_city));

UPDATE booking_staging
SET passenger_city = 'Unknown'
WHERE passenger_city IS NULL OR TRIM(passenger_city) = '';

-- ============================================================
-- 5. Standardize departure dates
-- Check the source formats before running date conversions.
-- These rules assume the formats documented in the project.
-- ============================================================

-- DD/MM/YYYY
UPDATE booking_staging
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'DD/MM/YYYY'), 'YYYY-MM-DD')
WHERE departure_date ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$';

-- DD-MM-YY
UPDATE booking_staging
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'DD-MM-YY'), 'YYYY-MM-DD')
WHERE departure_date ~ '^[0-9]{2}-[0-9]{2}-[0-9]{2}$';

-- DD-MM-YYYY where the day is greater than 12
UPDATE booking_staging
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'DD-MM-YYYY'), 'YYYY-MM-DD')
WHERE departure_date ~ '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
  AND SPLIT_PART(departure_date, '-', 1)::INTEGER > 12;

-- MM-DD-YYYY where the middle part is greater than 12
UPDATE booking_staging
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'MM-DD-YYYY'), 'YYYY-MM-DD')
WHERE departure_date ~ '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
  AND SPLIT_PART(departure_date, '-', 2)::INTEGER > 12;

-- ============================================================
-- 6. Standardize seat class
-- ============================================================

UPDATE booking_staging
SET seat_class = CASE
    WHEN UPPER(TRIM(seat_class)) IN ('ECONOMY', 'ECO', 'ECONOMY CLASS')
        THEN 'Economy'
    WHEN UPPER(TRIM(seat_class)) IN ('BUSINESS', 'BUS', 'BUSINESS CLASS')
        THEN 'Business'
    ELSE TRIM(seat_class)
END;

-- ============================================================
-- 7. Standardize payment methods and booking statuses
-- ============================================================

UPDATE booking_staging
SET payment_method = CASE
    WHEN UPPER(TRIM(payment_method)) IN ('MPESA', 'M-PESA', 'M PESA')
        THEN 'M-Pesa'
    WHEN UPPER(TRIM(payment_method)) = 'CASH' THEN 'Cash'
    WHEN UPPER(TRIM(payment_method)) = 'CARD' THEN 'Card'
    ELSE TRIM(payment_method)
END;

UPDATE booking_staging
SET booking_status = CASE
    WHEN UPPER(TRIM(booking_status)) = 'COMPLETED' THEN 'Completed'
    WHEN UPPER(TRIM(booking_status)) = 'CANCELLED' THEN 'Cancelled'
    WHEN UPPER(TRIM(booking_status)) = 'NO SHOW' THEN 'No Show'
    ELSE TRIM(booking_status)
END;

-- ============================================================
-- 8. Clean fare fields
-- Keep digits and decimal points; clean each column from itself.
-- ============================================================

UPDATE booking_staging
SET total_fare = REGEXP_REPLACE(total_fare, '[^0-9.]', '', 'g')
WHERE total_fare ~ '[^0-9.]';

UPDATE booking_staging
SET fare_per_seat = REGEXP_REPLACE(fare_per_seat, '[^0-9.]', '', 'g')
WHERE fare_per_seat ~ '[^0-9.]';

-- ============================================================
-- 9. Standardize driver and vehicle type
-- ============================================================

UPDATE booking_staging
SET driver_name = INITCAP(TRIM(driver_name))
WHERE driver_name IS DISTINCT FROM INITCAP(TRIM(driver_name));

UPDATE booking_staging
SET vehicle_type = INITCAP(TRIM(vehicle_type))
WHERE vehicle_type IS DISTINCT FROM INITCAP(TRIM(vehicle_type));

-- ============================================================
-- 10. Set invalid trip ratings to NULL
-- ============================================================

UPDATE booking_staging
SET trip_rating = NULL
WHERE NULLIF(TRIM(trip_rating), '') IS NOT NULL
  AND TRIM(trip_rating) NOT IN ('1', '2', '3', '4', '5');

-- ============================================================
-- 11. Remove negative seats and duplicate booking IDs
-- ============================================================
-- Delete rows with invalid or non-positive seat counts
DELETE FROM booking_staging
WHERE NULLIF(
    REGEXP_REPLACE(seats_booked, '[^0-9-]', '', 'g'),
    ''
)::INTEGER < 1;

-- Remove duplicate booking IDs, keeping the first ctid
DELETE FROM booking_staging
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM booking_staging
    GROUP BY booking_id
);

-- ============================================================
-- 12. Final cleaning checks
-- ============================================================

SELECT COUNT(*) AS remaining_staging_rows
FROM booking_staging;

SELECT booking_id, departure_date
FROM booking_staging
WHERE departure_date IS NOT NULL
  AND departure_date !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

-- End of data cleaning workflow.
-- Final table creation and loading are documented separately.
