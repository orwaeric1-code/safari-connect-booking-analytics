-- ============================================================
-- SAFARI CONNECT - BUS & MATATU BOOKING PLATFORM
-- File: 04_analytical_queries.sql
-- Purpose: Analyze routes, drivers, revenue, passengers,
--          cancellations and operational patterns.
-- ============================================================

SET search_path TO safari_connect;

-- ============================================================
-- QUESTION 1: ROUTE ANALYSIS
-- ============================================================

-- 1A. Revenue and bookings by route

SELECT
    route_code,
    route_from || ' → ' || route_to AS route,
    COUNT(*) AS total_bookings,
    SUM(seats_booked) AS total_seats,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(fare_per_seat), 2) AS avg_fare,
    ROUND(AVG(trip_rating), 2) AS avg_rating
FROM v_clean_trips
GROUP BY route_code, route_from, route_to
ORDER BY total_revenue DESC;

-- 1B. Revenue per seat by route

SELECT
    route_code,
    route_from || ' → ' || route_to AS route,
    SUM(seats_booked) AS total_seats,
    SUM(total_fare) AS total_revenue,
    ROUND(
        SUM(total_fare) / NULLIF(SUM(seats_booked), 0),
        2
    ) AS revenue_per_seat
FROM v_clean_trips
GROUP BY route_code, route_from, route_to
ORDER BY revenue_per_seat DESC;

-- 1C. Route revenue ranking and share of total revenue

WITH route_rev AS (
    SELECT
        route_code,
        route_from || ' → ' || route_to AS route,
        SUM(total_fare) AS revenue
    FROM v_clean_trips
    GROUP BY route_code, route_from, route_to
)
SELECT
    route,
    revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    ROUND(revenue * 100.0 / NULLIF(SUM(revenue) OVER (), 0), 1)
        AS pct_of_total
FROM route_rev
ORDER BY revenue_rank;

-- 1D. Vehicle type performance

SELECT
    vehicle_type,
    COUNT(*) AS total_bookings,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(trip_rating), 2) AS avg_rating
FROM v_clean_trips
GROUP BY vehicle_type
ORDER BY total_revenue DESC;

-- ============================================================
-- QUESTION 2: DRIVER PERFORMANCE
-- ============================================================

-- 2A. Driver summary

SELECT
    driver_name,
    COUNT(*) AS total_trips,
    SUM(seats_booked) AS total_seats_carried,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(trip_rating), 2) AS avg_trip_rating,
    ROUND(AVG(driver_rating), 2) AS driver_rating
FROM v_clean_trips
GROUP BY driver_name
ORDER BY total_revenue DESC;

-- 2B. Driver ranking overall and within vehicle type

WITH driver_totals AS (
    SELECT
        driver_name,
        vehicle_type,
        COUNT(*) AS total_trips,
        SUM(total_fare) AS total_revenue,
        ROUND(AVG(trip_rating), 2) AS avg_passenger_rating
    FROM v_clean_trips
    GROUP BY driver_name, vehicle_type
)
SELECT
    driver_name,
    vehicle_type,
    total_trips,
    total_revenue,
    avg_passenger_rating,
    RANK() OVER (ORDER BY total_revenue DESC) AS overall_rank,
    RANK() OVER (
        PARTITION BY vehicle_type
        ORDER BY total_revenue DESC
    ) AS vehicle_rank
FROM driver_totals
ORDER BY overall_rank;

-- 2C. Compare passenger ratings by driver-rating group

SELECT
    CASE
        WHEN driver_rating >= 4.5 THEN 'High-Rated'
        ELSE 'Standard'
    END AS driver_group,
    COUNT(*) AS total_trips,
    ROUND(AVG(trip_rating), 2) AS avg_passenger_rating
FROM v_clean_trips
GROUP BY
    CASE
        WHEN driver_rating >= 4.5 THEN 'High-Rated'
        ELSE 'Standard'
    END
ORDER BY avg_passenger_rating DESC;

-- ============================================================
-- QUESTION 3: REVENUE TRENDS
-- ============================================================

-- 3A. Monthly revenue and month-over-month change

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
    revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        1
    ) AS change_pct
FROM monthly
ORDER BY month;

-- 3B. Monthly revenue running total

WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') AS month,
        SUM(total_fare) AS revenue
    FROM v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
    month,
    revenue,
    SUM(revenue) OVER (ORDER BY month) AS running_total
FROM monthly
ORDER BY month;

-- 3C. Best and worst three months by revenue

WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') AS month,
        SUM(total_fare) AS revenue
    FROM v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
),
ranked AS (
    SELECT
        month,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS best_rank,
        RANK() OVER (ORDER BY revenue ASC) AS worst_rank
    FROM monthly
)
SELECT
    month,
    revenue,
    CASE
        WHEN best_rank <= 3 THEN 'Best 3 Months'
        WHEN worst_rank <= 3 THEN 'Worst 3 Months'
    END AS performance
FROM ranked
WHERE best_rank <= 3 OR worst_rank <= 3
ORDER BY revenue DESC;

-- 3D. Monthly revenue by route code

SELECT
    TO_CHAR(departure_date, 'YYYY-MM') AS month,
    SUM(CASE WHEN route_code = 'RT001' THEN total_fare ELSE 0 END)
        AS rt001_revenue,
    SUM(CASE WHEN route_code = 'RT002' THEN total_fare ELSE 0 END)
        AS rt002_revenue,
    SUM(CASE WHEN route_code = 'RT003' THEN total_fare ELSE 0 END)
        AS rt003_revenue
FROM v_clean_trips
GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
ORDER BY month;

-- ============================================================
-- QUESTION 4: PASSENGER INSIGHTS
-- ============================================================

-- 4A. Passenger cities with at least three completed trips

SELECT
    passenger_city,
    COUNT(*) AS total_bookings,
    SUM(seats_booked) AS total_seats,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(fare_per_seat), 2) AS avg_fare
FROM v_clean_trips
GROUP BY passenger_city
HAVING COUNT(*) >= 3
ORDER BY total_bookings DESC;

-- 4B. Gender split and seat-class preference

SELECT
    passenger_gender,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN seat_class = 'Economy' THEN 1 ELSE 0 END)
        AS economy_bookings,
    SUM(CASE WHEN seat_class = 'Business' THEN 1 ELSE 0 END)
        AS business_bookings,
    SUM(CASE WHEN seat_class = 'Economy' THEN total_fare ELSE 0 END)
        AS economy_revenue,
    SUM(CASE WHEN seat_class = 'Business' THEN total_fare ELSE 0 END)
        AS business_revenue
FROM v_clean_trips
GROUP BY passenger_gender
ORDER BY total_bookings DESC;

-- 4C. Passenger satisfaction breakdown

WITH sat_counts AS (
    SELECT
        satisfaction,
        COUNT(*) AS trip_count
    FROM v_clean_trips
    GROUP BY satisfaction
)
SELECT
    satisfaction,
    trip_count,
    ROUND(trip_count * 100.0 / NULLIF(SUM(trip_count) OVER (), 0), 1)
        AS pct_of_trips
FROM sat_counts
ORDER BY trip_count DESC;

-- 4D. Passenger spend quartiles

WITH passenger_spend AS (
    SELECT
        passenger_name,
        SUM(total_fare) AS total_spent
    FROM v_clean_trips
    GROUP BY passenger_name
),
quartiles AS (
    SELECT
        passenger_name,
        total_spent,
        NTILE(4) OVER (ORDER BY total_spent) AS quartile
    FROM passenger_spend
)
SELECT
    passenger_name,
    total_spent,
    quartile,
    CASE
        WHEN quartile = 4 THEN 'Top Spender'
        ELSE 'Standard'
    END AS spender_category
FROM quartiles
ORDER BY total_spent DESC;

-- ============================================================
-- QUESTION 5: CANCELLATIONS AND NO-SHOWS
-- ============================================================

-- 5A. Overall booking-status breakdown

SELECT
    booking_status,
    COUNT(*) AS total_bookings,
    SUM(seats_booked) AS total_seats,
    SUM(total_fare) AS associated_fares,
    ROUND(
        COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER (), 0),
        1
    ) AS percentage
FROM bookings
GROUP BY booking_status
ORDER BY total_bookings DESC;

-- 5B. Cancellation and no-show rate by route

SELECT
    route_code,
    route_from || ' → ' || route_to AS route,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN booking_status = 'Completed' THEN 1 ELSE 0 END)
        AS completed,
    SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END)
        AS cancelled,
    SUM(CASE WHEN booking_status = 'No Show' THEN 1 ELSE 0 END)
        AS no_show,
    ROUND(
        SUM(
            CASE
                WHEN booking_status IN ('Cancelled', 'No Show') THEN 1
                ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        1
    ) AS cancel_rate_pct
FROM bookings
GROUP BY route_code, route_from, route_to
ORDER BY cancel_rate_pct DESC;

-- 5C. Fares associated with cancellations and no-shows
-- These amounts are not necessarily unrecovered financial losses.

SELECT
    SUM(
        CASE
            WHEN booking_status IN ('Cancelled', 'No Show')
                THEN total_fare
            ELSE 0
        END
    ) AS cancelled_no_show_fares,
    SUM(
        CASE
            WHEN booking_status = 'Completed' THEN total_fare
            ELSE 0
        END
    ) AS completed_revenue,
    ROUND(
        SUM(
            CASE
                WHEN booking_status IN ('Cancelled', 'No Show')
                    THEN total_fare
                ELSE 0
            END
        ) * 100.0 / NULLIF(SUM(total_fare), 0),
        1
    ) AS cancelled_no_show_fare_pct
FROM bookings;

-- ============================================================
-- QUESTION 6: OPERATIONAL PATTERNS
-- ============================================================

-- 6A. Revenue and bookings by day of week
-- ISODOW: Monday = 1, Sunday = 7.

SELECT
    EXTRACT(ISODOW FROM departure_date) AS day_num,
    TRIM(TO_CHAR(departure_date, 'Day')) AS day_name,
    COUNT(*) AS total_bookings,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(total_fare), 2) AS avg_booking_value
FROM v_clean_trips
GROUP BY
    EXTRACT(ISODOW FROM departure_date),
    TRIM(TO_CHAR(departure_date, 'Day'))
ORDER BY day_num;

-- 6B. Busiest departure times

SELECT
    departure_time,
    COUNT(*) AS total_bookings,
    SUM(seats_booked) AS total_passengers,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(total_fare), 2) AS avg_booking_value
FROM v_clean_trips
GROUP BY departure_time
ORDER BY total_passengers DESC;

-- 6C. Seat utilisation by vehicle type

SELECT
    vehicle_type,
    ROUND(AVG(seats_booked), 2) AS avg_seats_booked,
    CASE
        WHEN AVG(seats_booked) > 3 THEN 'High Load'
        WHEN AVG(seats_booked) BETWEEN 2 AND 3 THEN 'Medium Load'
        ELSE 'Low Load'
    END AS load_category
FROM v_clean_trips
GROUP BY vehicle_type
ORDER BY avg_seats_booked DESC;

-- End of analytical queries.
-- Views and indexes are documented in File 05.
