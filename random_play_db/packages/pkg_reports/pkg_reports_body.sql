-- Reports Package Implementation for Random Play Video Tape Store
-- Contains function implementations for reporting and analytics operations

-- Function to get revenue by period
CREATE OR REPLACE FUNCTION pkg_reports.get_revenue_by_period(
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE (
    rental_revenue NUMERIC,
    late_fee_revenue NUMERIC,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(t.rental_price), 0) AS rental_revenue,
        COALESCE(SUM(r.late_fees), 0) AS late_fee_revenue,
        COALESCE(SUM(t.rental_price), 0) + COALESCE(SUM(r.late_fees), 0) AS total_revenue
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.rental_date::DATE BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get popular genres
CREATE OR REPLACE FUNCTION pkg_reports.get_popular_genres(
    p_limit INTEGER DEFAULT 10
) RETURNS TABLE (
    genre_name VARCHAR,
    rental_count BIGINT,
    revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.name AS genre_name,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(t.rental_price + r.late_fees), 0) AS revenue
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    JOIN genres g ON t.genre_id = g.genre_id
    GROUP BY g.name
    ORDER BY rental_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to get popular tapes
CREATE OR REPLACE FUNCTION pkg_reports.get_popular_tapes(
    p_limit INTEGER DEFAULT 10
) RETURNS TABLE (
    tape_id INTEGER,
    tape_title VARCHAR,
    genre_name VARCHAR,
    rental_count BIGINT,
    revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tape_id,
        t.title AS tape_title,
        g.name AS genre_name,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(t.rental_price + r.late_fees), 0) AS revenue
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    JOIN genres g ON t.genre_id = g.genre_id
    GROUP BY t.tape_id, t.title, g.name
    ORDER BY rental_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to get customer spending
CREATE OR REPLACE FUNCTION pkg_reports.get_customer_spending(
    p_customer_id INTEGER,
    p_start_date DATE,
    p_end_date DATE
) RETURNS TABLE (
    rental_spending NUMERIC,
    late_fee_spending NUMERIC,
    total_spending NUMERIC
) AS $$
BEGIN
    -- Check if customer exists
    IF NOT EXISTS(SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer with ID % does not exist', p_customer_id;
    END IF;
    
    RETURN QUERY
    SELECT 
        COALESCE(SUM(t.rental_price), 0) AS rental_spending,
        COALESCE(SUM(r.late_fees), 0) AS late_fee_spending,
        COALESCE(SUM(t.rental_price), 0) + COALESCE(SUM(r.late_fees), 0) AS total_spending
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.customer_id = p_customer_id
    AND r.rental_date::DATE BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get overdue summary
CREATE OR REPLACE FUNCTION pkg_reports.get_overdue_summary()
RETURNS TABLE (
    overdue_count BIGINT,
    total_days_overdue BIGINT,
    estimated_late_fees NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) AS overdue_count,
        COALESCE(SUM(EXTRACT(DAY FROM (CURRENT_TIMESTAMP - r.due_date))), 0) AS total_days_overdue,
        COALESCE(SUM(EXTRACT(DAY FROM (CURRENT_TIMESTAMP - r.due_date)) * (t.rental_price * 0.5)), 0) AS estimated_late_fees
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.return_date IS NULL AND r.due_date < CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Function to get inventory status
CREATE OR REPLACE FUNCTION pkg_reports.get_inventory_status()
RETURNS TABLE (
    genre_name VARCHAR,
    total_tapes BIGINT,
    available_tapes BIGINT,
    out_on_rental BIGINT,
    utilization_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.name AS genre_name,
        SUM(t.total_stock) AS total_tapes,
        SUM(t.stock_available) AS available_tapes,
        SUM(t.total_stock - t.stock_available) AS out_on_rental,
        CASE 
            WHEN SUM(t.total_stock) = 0 THEN 0
            ELSE ROUND((SUM(t.total_stock - t.stock_available) * 100.0 / SUM(t.total_stock)), 2)
        END AS utilization_rate
    FROM tapes t
    JOIN genres g ON t.genre_id = g.genre_id
    GROUP BY g.name
    ORDER BY utilization_rate DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get monthly revenue report
CREATE OR REPLACE FUNCTION pkg_reports.get_monthly_revenue_report(
    p_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)
) RETURNS TABLE (
    month INTEGER,
    month_name TEXT,
    rental_revenue NUMERIC,
    late_fee_revenue NUMERIC,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(MONTH FROM r.rental_date)::INTEGER AS month,
        TO_CHAR(r.rental_date, 'Month') AS month_name,
        COALESCE(SUM(t.rental_price), 0) AS rental_revenue,
        COALESCE(SUM(r.late_fees), 0) AS late_fee_revenue,
        COALESCE(SUM(t.rental_price), 0) + COALESCE(SUM(r.late_fees), 0) AS total_revenue
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE EXTRACT(YEAR FROM r.rental_date) = p_year
    GROUP BY month, month_name
    ORDER BY month;
END;
$$ LANGUAGE plpgsql;

-- Function to get customer activity
CREATE OR REPLACE FUNCTION pkg_reports.get_customer_activity(
    p_limit INTEGER DEFAULT 10
) RETURNS TABLE (
    customer_id INTEGER,
    customer_name TEXT,
    rental_count BIGINT,
    total_spending NUMERIC,
    last_rental_date TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(t.rental_price + r.late_fees), 0) AS total_spending,
        MAX(r.rental_date) AS last_rental_date
    FROM customers c
    LEFT JOIN rentals r ON c.customer_id = r.customer_id
    LEFT JOIN tapes t ON r.tape_id = t.tape_id
    GROUP BY c.customer_id, customer_name
    ORDER BY rental_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql; 