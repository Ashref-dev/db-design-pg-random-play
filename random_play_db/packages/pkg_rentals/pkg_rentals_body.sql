-- Rentals Package Implementation for Random Play Video Tape Store
-- Contains function implementations for rental operations

-- Function to rent a tape
CREATE OR REPLACE FUNCTION pkg_rentals.rent_tape(
    p_customer_id INTEGER,
    p_tape_id INTEGER,
    p_rental_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) RETURNS INTEGER AS $$
DECLARE
    v_rental_id INTEGER;
    v_customer_active BOOLEAN;
    v_stock_available INTEGER;
    v_rental_duration INTEGER;
    v_due_date TIMESTAMP;
BEGIN
    -- Check if customer exists and is active
    SELECT active INTO v_customer_active 
    FROM customers 
    WHERE customer_id = p_customer_id;
    
    IF v_customer_active IS NULL THEN
        RAISE EXCEPTION 'Customer with ID % does not exist', p_customer_id;
    END IF;
    
    IF NOT v_customer_active THEN
        RAISE EXCEPTION 'Customer with ID % is not active', p_customer_id;
    END IF;
    
    -- Check if tape exists and is available (Check is also done by BEFORE trigger)
    SELECT stock_available, rental_duration_days 
    INTO v_stock_available, v_rental_duration
    FROM tapes 
    WHERE tape_id = p_tape_id;
    
    IF v_stock_available IS NULL THEN
        RAISE EXCEPTION 'Tape with ID % does not exist', p_tape_id;
    END IF;
    
    -- Note: The BEFORE INSERT trigger trg_check_tape_availability already verifies stock > 0.
    -- The check below is slightly redundant but provides an earlier exit if stock is 0.
    IF v_stock_available <= 0 THEN
        RAISE EXCEPTION 'Tape with ID % is not available for rental (current stock: 0)', p_tape_id;
    END IF;
    
    -- Calculate due date based on rental duration
    v_due_date := p_rental_date + (v_rental_duration || ' days')::interval;
    
    -- Create the rental record
    -- The AFTER INSERT trigger trg_update_tape_stock will handle decrementing stock
    INSERT INTO rentals (
        customer_id,
        tape_id,
        rental_date,
        due_date,
        return_date,
        late_fees
    ) VALUES (
        p_customer_id,
        p_tape_id,
        p_rental_date,
        v_due_date,
        NULL,
        0.00
    ) RETURNING rental_id INTO v_rental_id;
    
 
    
    RETURN v_rental_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error renting tape: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to return a tape
CREATE OR REPLACE FUNCTION pkg_rentals.return_tape(
    p_rental_id INTEGER,
    p_return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) RETURNS TIMESTAMP AS $$
DECLARE
    v_tape_id INTEGER;
    v_due_date TIMESTAMP;
    v_return_date TIMESTAMP;
    v_late_fees NUMERIC(5,2);
BEGIN
    -- Check if rental exists and is not already returned
    SELECT tape_id, due_date, return_date 
    INTO v_tape_id, v_due_date, v_return_date
    FROM rentals 
    WHERE rental_id = p_rental_id;
    
    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Rental with ID % does not exist', p_rental_id;
    END IF;
    
    IF v_return_date IS NOT NULL THEN
        RAISE EXCEPTION 'Rental with ID % has already been returned on %', p_rental_id, v_return_date;
    END IF;
    
    -- Calculate late fees if applicable
    IF p_return_date > v_due_date THEN
        v_late_fees := pkg_rentals.calculate_late_fees(p_rental_id, p_return_date);
    ELSE
        v_late_fees := 0;
    END IF;
    
    -- Update the rental record
    -- The AFTER UPDATE trigger trg_update_tape_stock will handle incrementing stock
    UPDATE rentals
    SET return_date = p_return_date,
        late_fees = v_late_fees
    WHERE rental_id = p_rental_id;
    
    -- REMOVED: Update tape stock (Handled by AFTER UPDATE trigger trg_update_tape_stock)
    -- UPDATE tapes
    -- SET stock_available = stock_available + 1
    -- WHERE tape_id = v_tape_id;
    
    RETURN p_return_date;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error returning tape: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate late fees
CREATE OR REPLACE FUNCTION pkg_rentals.calculate_late_fees(
    p_rental_id INTEGER,
    p_return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) RETURNS NUMERIC AS $$
DECLARE
    v_due_date TIMESTAMP;
    v_days_late INTEGER;
    v_daily_rate NUMERIC(5,2);
    v_late_fees NUMERIC(5,2);
BEGIN
    -- Get due date and rental price (which determines late fee rate)
    SELECT r.due_date, t.rental_price
    INTO v_due_date, v_daily_rate
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.rental_id = p_rental_id;
    
    IF v_due_date IS NULL THEN
        RAISE EXCEPTION 'Rental with ID % does not exist', p_rental_id;
    END IF;
    
    -- Calculate days late
    v_days_late := EXTRACT(DAY FROM (p_return_date - v_due_date));
    
    -- If not late, no fees
    IF v_days_late <= 0 THEN
        RETURN 0;
    END IF;
    
    -- Late fee is 50% of rental price per day late
    v_late_fees := v_days_late * (v_daily_rate * 0.5);
    
    -- Cap late fees at 10 times the rental price
    RETURN LEAST(v_late_fees, v_daily_rate * 10);
END;
$$ LANGUAGE plpgsql;

-- Function to get a rental by ID
CREATE OR REPLACE FUNCTION pkg_rentals.get_rental(
    p_rental_id INTEGER
) RETURNS SETOF rentals AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM rentals WHERE rental_id = p_rental_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Rental with ID % not found', p_rental_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to find overdue rentals
CREATE OR REPLACE FUNCTION pkg_rentals.find_overdue_rentals()
RETURNS TABLE (
    rental_id INTEGER,
    customer_id INTEGER,
    customer_name TEXT,
    tape_id INTEGER,
    tape_title VARCHAR,
    rental_date TIMESTAMP,
    due_date TIMESTAMP,
    days_overdue INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.rental_id,
        r.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        r.tape_id,
        t.title AS tape_title,
        r.rental_date,
        r.due_date,
        EXTRACT(DAY FROM (CURRENT_TIMESTAMP - r.due_date))::INTEGER AS days_overdue
    FROM rentals r
    JOIN customers c ON r.customer_id = c.customer_id
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.return_date IS NULL AND r.due_date < CURRENT_TIMESTAMP
    ORDER BY days_overdue DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to find a customer's active rentals
CREATE OR REPLACE FUNCTION pkg_rentals.find_customer_active_rentals(
    p_customer_id INTEGER
) RETURNS TABLE (
    rental_id INTEGER,
    tape_id INTEGER,
    tape_title VARCHAR,
    rental_date TIMESTAMP,
    due_date TIMESTAMP,
    is_overdue BOOLEAN,
    days_remaining INTEGER
) AS $$
BEGIN
    -- Check if customer exists
    IF NOT EXISTS(SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer with ID % does not exist', p_customer_id;
    END IF;
    
    RETURN QUERY
    SELECT 
        r.rental_id,
        r.tape_id,
        t.title AS tape_title,
        r.rental_date,
        r.due_date,
        r.due_date < CURRENT_TIMESTAMP AS is_overdue,
        CASE 
            WHEN r.due_date < CURRENT_TIMESTAMP THEN -1 * EXTRACT(DAY FROM (CURRENT_TIMESTAMP - r.due_date))::INTEGER
            ELSE EXTRACT(DAY FROM (r.due_date - CURRENT_TIMESTAMP))::INTEGER
        END AS days_remaining
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.customer_id = p_customer_id AND r.return_date IS NULL
    ORDER BY is_overdue DESC, days_remaining;
END;
$$ LANGUAGE plpgsql;

-- Function to extend a rental
CREATE OR REPLACE FUNCTION pkg_rentals.extend_rental(
    p_rental_id INTEGER,
    p_additional_days INTEGER
) RETURNS TIMESTAMP AS $$
DECLARE
    v_due_date TIMESTAMP;
    v_new_due_date TIMESTAMP;
BEGIN
    -- Check if rental exists and is active
    SELECT due_date INTO v_due_date
    FROM rentals
    WHERE rental_id = p_rental_id AND return_date IS NULL;
    
    IF v_due_date IS NULL THEN
        RAISE EXCEPTION 'Rental with ID % does not exist or has already been returned', p_rental_id;
    END IF;
    
    -- Validate input
    IF p_additional_days <= 0 THEN
        RAISE EXCEPTION 'Additional days must be greater than zero';
    END IF;
    
    -- Calculate new due date
    v_new_due_date := v_due_date + (p_additional_days || ' days')::interval;
    
    -- Update the rental
    UPDATE rentals
    SET due_date = v_new_due_date
    WHERE rental_id = p_rental_id;
    
    RETURN v_new_due_date;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error extending rental: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to get rental history within a date range
CREATE OR REPLACE FUNCTION pkg_rentals.get_rental_history(
    p_from_date TIMESTAMP,
    p_to_date TIMESTAMP
) RETURNS TABLE (
    rental_id INTEGER,
    customer_id INTEGER,
    customer_name TEXT,
    tape_id INTEGER,
    tape_title VARCHAR,
    rental_date TIMESTAMP,
    due_date TIMESTAMP,
    return_date TIMESTAMP,
    late_fees NUMERIC,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.rental_id,
        r.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        r.tape_id,
        t.title AS tape_title,
        r.rental_date,
        r.due_date,
        r.return_date,
        r.late_fees,
        CASE 
            WHEN r.return_date IS NOT NULL THEN 'Returned'
            WHEN r.due_date < CURRENT_TIMESTAMP THEN 'Overdue'
            ELSE 'Active'
        END AS status
    FROM rentals r
    JOIN customers c ON r.customer_id = c.customer_id
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.rental_date BETWEEN p_from_date AND p_to_date
    ORDER BY r.rental_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Advanced search function for rentals
CREATE OR REPLACE FUNCTION pkg_rentals.search_rentals(
    p_customer_id INTEGER DEFAULT NULL,
    p_tape_id INTEGER DEFAULT NULL,
    p_rental_date_from TIMESTAMP DEFAULT NULL,
    p_rental_date_to TIMESTAMP DEFAULT NULL,
    p_return_status VARCHAR DEFAULT NULL, -- 'returned', 'active', 'overdue', or NULL for all
    p_has_late_fees BOOLEAN DEFAULT NULL
) RETURNS TABLE (
    rental_id INTEGER,
    customer_name TEXT,
    tape_title VARCHAR,
    rental_date TIMESTAMP,
    due_date TIMESTAMP,
    return_date TIMESTAMP,
    late_fees NUMERIC,
    rental_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.rental_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        t.title AS tape_title,
        r.rental_date,
        r.due_date,
        r.return_date,
        r.late_fees,
        CASE 
            WHEN r.return_date IS NOT NULL THEN 'returned'
            WHEN r.due_date < CURRENT_TIMESTAMP THEN 'overdue'
            ELSE 'active'
        END AS rental_status
    FROM rentals r
    JOIN customers c ON r.customer_id = c.customer_id
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE (p_customer_id IS NULL OR r.customer_id = p_customer_id)
      AND (p_tape_id IS NULL OR r.tape_id = p_tape_id)
      AND (p_rental_date_from IS NULL OR r.rental_date >= p_rental_date_from)
      AND (p_rental_date_to IS NULL OR r.rental_date <= p_rental_date_to)
      AND (p_return_status IS NULL OR 
          (p_return_status = 'returned' AND r.return_date IS NOT NULL) OR
          (p_return_status = 'active' AND r.return_date IS NULL AND r.due_date >= CURRENT_TIMESTAMP) OR
          (p_return_status = 'overdue' AND r.return_date IS NULL AND r.due_date < CURRENT_TIMESTAMP)
      )
      AND (p_has_late_fees IS NULL OR 
          (p_has_late_fees = TRUE AND r.late_fees > 0) OR
          (p_has_late_fees = FALSE AND (r.late_fees = 0 OR r.late_fees IS NULL))
      )
    ORDER BY r.rental_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to find rentals by date range
CREATE OR REPLACE FUNCTION pkg_rentals.find_rentals_by_date_range(
    p_start_date TIMESTAMP,
    p_end_date TIMESTAMP
) RETURNS TABLE (
    rental_id INTEGER,
    customer_name TEXT,
    tape_title VARCHAR,
    rental_date TIMESTAMP,
    due_date TIMESTAMP,
    return_date TIMESTAMP,
    rental_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.rental_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        t.title AS tape_title,
        r.rental_date,
        r.due_date,
        r.return_date,
        CASE 
            WHEN r.return_date IS NOT NULL THEN 'Returned'
            WHEN r.due_date < CURRENT_TIMESTAMP THEN 'Overdue'
            ELSE 'Active'
        END AS rental_status
    FROM rentals r
    JOIN customers c ON r.customer_id = c.customer_id
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.rental_date BETWEEN p_start_date AND p_end_date
    ORDER BY r.rental_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to find high value rentals
CREATE OR REPLACE FUNCTION pkg_rentals.find_high_value_rentals(
    p_min_amount NUMERIC DEFAULT 5.0,
    p_limit INTEGER DEFAULT 10
) RETURNS TABLE (
    rental_id INTEGER,
    customer_name TEXT,
    tape_title VARCHAR,
    rental_date TIMESTAMP,
    return_date TIMESTAMP,
    rental_price NUMERIC,
    late_fees NUMERIC,
    total_amount NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.rental_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        t.title AS tape_title,
        r.rental_date,
        r.return_date,
        t.rental_price,
        r.late_fees,
        (t.rental_price + r.late_fees) AS total_amount
    FROM rentals r
    JOIN customers c ON r.customer_id = c.customer_id
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE (t.rental_price + COALESCE(r.late_fees, 0)) >= p_min_amount
    ORDER BY total_amount DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to process bulk returns of tapes
CREATE OR REPLACE FUNCTION pkg_rentals.bulk_return_tapes(
    p_rental_ids INTEGER[],
    p_return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) RETURNS TABLE (
    rental_id INTEGER,
    tape_title VARCHAR,
    return_date TIMESTAMP,
    late_fees NUMERIC
) AS $$
DECLARE
    v_rental_id INTEGER;
    v_return_results TABLE (
        rental_id INTEGER,
        tape_title VARCHAR,
        return_date TIMESTAMP,
        late_fees NUMERIC
    );
    v_success_count INTEGER := 0;
    v_error_count INTEGER := 0;
    v_error_message TEXT := '';
BEGIN
    -- Use a transaction to ensure all operations succeed or fail together
    BEGIN
        -- Process each rental ID
        FOREACH v_rental_id IN ARRAY p_rental_ids
        LOOP
            BEGIN
                -- Use the individual return_tape function for each rental
                PERFORM pkg_rentals.return_tape(v_rental_id, p_return_date);
                
                -- If successful, collect information for the result
                INSERT INTO v_return_results
                SELECT 
                    r.rental_id,
                    t.title,
                    r.return_date,
                    r.late_fees
                FROM rentals r
                JOIN tapes t ON r.tape_id = t.tape_id
                WHERE r.rental_id = v_rental_id;
                
                v_success_count := v_success_count + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    -- Collect error message but continue processing
                    v_error_count := v_error_count + 1;
                    v_error_message := v_error_message || 'Error returning rental ID ' || v_rental_id || ': ' || SQLERRM || '; ';
            END;
        END LOOP;
        
        -- Raise an exception if no rentals were successfully returned
        IF v_success_count = 0 THEN
            RAISE EXCEPTION 'Failed to return any tapes. Errors: %', v_error_message;
        END IF;
        
        -- Return the results of successful returns
        RETURN QUERY SELECT * FROM v_return_results;
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback the transaction if any unexpected error occurs
            RAISE EXCEPTION 'Bulk return failed: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to process bulk rentals for a customer
CREATE OR REPLACE FUNCTION pkg_rentals.bulk_rent_tapes(
    p_customer_id INTEGER,
    p_tape_ids INTEGER[],
    p_rental_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) RETURNS TABLE (
    rental_id INTEGER,
    tape_title VARCHAR,
    due_date TIMESTAMP
) AS $$
DECLARE
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_tape_title VARCHAR;
    v_due_date TIMESTAMP;
    v_rental_results TABLE (
        rental_id INTEGER,
        tape_title VARCHAR,
        due_date TIMESTAMP
    );
    v_success_count INTEGER := 0;
    v_error_count INTEGER := 0;
    v_error_message TEXT := '';
BEGIN
    -- Check if customer exists and is active
    IF NOT EXISTS(SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer with ID % does not exist', p_customer_id;
    END IF;
    
    IF NOT EXISTS(SELECT 1 FROM customers WHERE customer_id = p_customer_id AND active = TRUE) THEN
        RAISE EXCEPTION 'Customer with ID % is not active', p_customer_id;
    END IF;
    
    -- Start transaction for atomicity
    BEGIN
        -- Process each tape ID
        FOREACH v_tape_id IN ARRAY p_tape_ids
        LOOP
            BEGIN
                -- Check if tape exists and is available
                SELECT title INTO v_tape_title
                FROM tapes 
                WHERE tape_id = v_tape_id AND stock_available > 0;
                
                IF v_tape_title IS NULL THEN
                    v_error_count := v_error_count + 1;
                    v_error_message := v_error_message || 'Tape with ID ' || v_tape_id || ' does not exist or is not available; ';
                    CONTINUE;
                END IF;
                
                -- Create the rental record using the individual rent_tape function
                v_rental_id := pkg_rentals.rent_tape(p_customer_id, v_tape_id, p_rental_date);
                
                -- Get the due date for the result
                SELECT due_date INTO v_due_date
                FROM rentals
                WHERE rental_id = v_rental_id;
                
                -- Store the result
                INSERT INTO v_rental_results VALUES (v_rental_id, v_tape_title, v_due_date);
                
                v_success_count := v_success_count + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    -- Collect error message but continue processing
                    v_error_count := v_error_count + 1;
                    v_error_message := v_error_message || 'Error renting tape ID ' || v_tape_id || ': ' || SQLERRM || '; ';
            END;
        END LOOP;
        
        -- Raise an exception if no tapes were successfully rented
        IF v_success_count = 0 THEN
            RAISE EXCEPTION 'Failed to rent any tapes. Errors: %', v_error_message;
        END IF;
        
        -- Return the results of successful rentals
        RETURN QUERY SELECT * FROM v_rental_results;
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback the transaction if any unexpected error occurs
            RAISE EXCEPTION 'Bulk rental failed: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to check customer rental eligibility
CREATE OR REPLACE FUNCTION pkg_rentals.check_customer_eligibility(
    p_customer_id INTEGER
) RETURNS TABLE (
    is_eligible BOOLEAN,
    reason TEXT,
    current_rentals INTEGER,
    overdue_rentals INTEGER,
    total_due_amount NUMERIC
) AS $$
DECLARE
    v_active BOOLEAN;
    v_current_rentals INTEGER;
    v_overdue_rentals INTEGER;
    v_late_fees NUMERIC;
    v_max_rentals CONSTANT INTEGER := 10; -- Maximum allowed rentals
    v_max_late_fees CONSTANT NUMERIC := 20.00; -- Maximum allowed unpaid late fees
BEGIN
    -- Check if customer exists and is active
    SELECT active INTO v_active
    FROM customers 
    WHERE customer_id = p_customer_id;
    
    IF v_active IS NULL THEN
        RETURN QUERY
        SELECT FALSE AS is_eligible, 'Customer does not exist'::TEXT, 0, 0, 0::NUMERIC;
        RETURN;
    END IF;
    
    IF NOT v_active THEN
        RETURN QUERY
        SELECT FALSE AS is_eligible, 'Customer account is inactive'::TEXT, 0, 0, 0::NUMERIC;
        RETURN;
    END IF;
    
    -- Count current rentals and calculate late fees
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN r.due_date < CURRENT_TIMESTAMP THEN 1 END),
        COALESCE(SUM(r.late_fees), 0)
    INTO 
        v_current_rentals,
        v_overdue_rentals,
        v_late_fees
    FROM rentals r
    WHERE r.customer_id = p_customer_id AND r.return_date IS NULL;
    
    -- Check if customer has too many rentals
    IF v_current_rentals >= v_max_rentals THEN
        RETURN QUERY
        SELECT FALSE AS is_eligible, 
               'Maximum allowed rentals reached (' || v_max_rentals || ')'::TEXT, 
               v_current_rentals, 
               v_overdue_rentals, 
               v_late_fees;
        RETURN;
    END IF;
    
    -- Check if customer has too many overdue rentals
    IF v_overdue_rentals >= 3 THEN
        RETURN QUERY
        SELECT FALSE AS is_eligible, 
               'Too many overdue rentals (' || v_overdue_rentals || ')'::TEXT, 
               v_current_rentals, 
               v_overdue_rentals, 
               v_late_fees;
        RETURN;
    END IF;
    
    -- Check if customer has excessive late fees
    IF v_late_fees > v_max_late_fees THEN
        RETURN QUERY
        SELECT FALSE AS is_eligible, 
               'Excessive unpaid late fees ($' || v_late_fees || ')'::TEXT, 
               v_current_rentals, 
               v_overdue_rentals, 
               v_late_fees;
        RETURN;
    END IF;
    
    -- Customer is eligible
    RETURN QUERY
    SELECT TRUE AS is_eligible, 
           'Customer is eligible to rent'::TEXT, 
           v_current_rentals, 
           v_overdue_rentals, 
           v_late_fees;
END;
$$ LANGUAGE plpgsql;

-- Function to process tape reservation (for when a tape is out of stock)
CREATE OR REPLACE FUNCTION pkg_rentals.reserve_tape(
    p_customer_id INTEGER,
    p_tape_id INTEGER,
    p_notes TEXT DEFAULT NULL
) RETURNS TABLE (
    reservation_id INTEGER,
    tape_title VARCHAR,
    current_stock INTEGER,
    expected_availability TEXT
) AS $$
DECLARE
    v_reservation_id INTEGER;
    v_tape_title VARCHAR;
    v_stock_available INTEGER;
    v_avg_rental_duration INTERVAL;
BEGIN
    -- Check if the customer is active
    IF NOT EXISTS(SELECT 1 FROM customers WHERE customer_id = p_customer_id AND active = TRUE) THEN
        RAISE EXCEPTION 'Customer with ID % does not exist or is not active', p_customer_id;
    END IF;
    
    -- Check if the tape exists
    SELECT title, stock_available INTO v_tape_title, v_stock_available
    FROM tapes
    WHERE tape_id = p_tape_id;
    
    IF v_tape_title IS NULL THEN
        RAISE EXCEPTION 'Tape with ID % does not exist', p_tape_id;
    END IF;
    
    -- Only allow reservation if stock is 0
    IF v_stock_available > 0 THEN
        RAISE EXCEPTION 'Tape "%" is currently available (stock: %). No need for reservation.', v_tape_title, v_stock_available;
    END IF;
    
    -- Create a reservation record in a temporary table (for demonstration purposes)
    -- In a real implementation, we would need a reservations table
    CREATE TEMPORARY TABLE IF NOT EXISTS tape_reservations (
        reservation_id SERIAL PRIMARY KEY,
        customer_id INTEGER NOT NULL,
        tape_id INTEGER NOT NULL,
        reservation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        notes TEXT,
        status VARCHAR(20) DEFAULT 'PENDING'
    ) ON COMMIT PRESERVE ROWS;
    
    -- Insert the reservation
    INSERT INTO tape_reservations (customer_id, tape_id, notes)
    VALUES (p_customer_id, p_tape_id, p_notes)
    RETURNING reservation_id INTO v_reservation_id;
    
    -- Calculate estimated availability based on average rental duration
    -- This is a simplified example - a real implementation would be more sophisticated
    SELECT AVG(COALESCE(return_date, CURRENT_TIMESTAMP) - rental_date) INTO v_avg_rental_duration
    FROM rentals
    WHERE tape_id = p_tape_id AND return_date IS NOT NULL;
    
    IF v_avg_rental_duration IS NULL THEN
        v_avg_rental_duration := INTERVAL '7 days'; -- Default if no historical data
    END IF;
    
    -- Return reservation details
    RETURN QUERY
    SELECT 
        v_reservation_id,
        v_tape_title,
        v_stock_available,
        'Approximately ' || EXTRACT(DAY FROM v_avg_rental_duration)::TEXT || ' days'
    ;
END;
$$ LANGUAGE plpgsql; 