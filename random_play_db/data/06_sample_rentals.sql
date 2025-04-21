-- Sample Rentals for Random Play Video Tape Store

-- Clear any existing data
TRUNCATE rentals CASCADE;

-- Function to generate random rentals with varied status
CREATE OR REPLACE FUNCTION generate_sample_rentals() RETURNS VOID AS $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_date TIMESTAMP;
    v_rental_duration INTEGER;
    v_due_date TIMESTAMP;
    v_return_date TIMESTAMP;
    v_late_fee NUMERIC(5,2);
    v_status TEXT;
    v_days_late INTEGER;
    v_customer_cursor CURSOR FOR SELECT customer_id FROM customers WHERE active = TRUE;
BEGIN
    -- For each active customer, create 1-3 rentals
    OPEN v_customer_cursor;
    LOOP
        FETCH v_customer_cursor INTO v_customer_id;
        EXIT WHEN NOT FOUND;
        
        -- Create 1-3 rentals per customer
        FOR i IN 1..floor(random() * 3 + 1)::int LOOP
            -- Get a random tape that has stock available
            SELECT tape_id INTO v_tape_id 
            FROM tapes 
            WHERE stock_available > 0 
            ORDER BY random() 
            LIMIT 1;
            
            -- Skip if no tape available
            CONTINUE WHEN v_tape_id IS NULL;
            
            -- Get rental duration for the tape
            SELECT rental_duration_days INTO v_rental_duration
            FROM tapes
            WHERE tape_id = v_tape_id;
            
            -- Generate rental date (between 30 days ago and today)
            v_rental_date := current_timestamp - (random() * 30 || ' days')::interval;
            
            -- Calculate due date
            v_due_date := v_rental_date + (v_rental_duration || ' days')::interval;
            
            -- Determine rental status randomly
            -- 60% returned, 25% active (not yet due), 15% overdue
            v_status := (ARRAY['returned', 'active', 'overdue'])[1 + floor(random() * 100) / (CASE 
                         WHEN floor(random() * 100) < 60 THEN 1    -- 60% returned
                         WHEN floor(random() * 100) < 85 THEN 2    -- 25% active
                         ELSE 3                                    -- 15% overdue
                     END)];
            
            -- Set return date and late fee based on status
            CASE v_status
                WHEN 'returned' THEN
                    -- Returned tapes have a return date between rental date and now
                    v_days_late := floor(random() * 5) - 2;  -- -2 to 2 days late (negative means early)
                    v_return_date := v_due_date + (v_days_late || ' days')::interval;
                    
                    IF v_days_late > 0 THEN
                        v_late_fee := v_days_late * 1.50;  -- $1.50 per day late
                    ELSE
                        v_late_fee := 0;
                    END IF;
                    
                WHEN 'active' THEN
                    -- Active rentals: not yet returned, due date in the future
                    v_return_date := NULL;
                    v_late_fee := 0;
                    
                    -- Ensure due date is in the future for active rentals
                    IF v_due_date < current_timestamp THEN
                        v_rental_date := current_timestamp - (floor(random() * v_rental_duration) || ' days')::interval;
                        v_due_date := v_rental_date + (v_rental_duration || ' days')::interval;
                    END IF;
                    
                WHEN 'overdue' THEN
                    -- Overdue rentals: not yet returned, due date in the past
                    v_return_date := NULL;
                    
                    -- Ensure due date is in the past for overdue rentals
                    IF v_due_date > current_timestamp THEN
                        v_rental_date := current_timestamp - ((v_rental_duration + floor(random() * 10 + 1)) || ' days')::interval;
                        v_due_date := v_rental_date + (v_rental_duration || ' days')::interval;
                    END IF;
                    
                    -- Calculate current late fee based on days overdue so far
                    v_days_late := EXTRACT(DAY FROM (current_timestamp - v_due_date));
                    v_late_fee := GREATEST(0, v_days_late) * 1.50;  -- $1.50 per day late
                    
                ELSE
                    -- Default case - should not happen but added to fix the CASE error
                    v_return_date := NULL;
                    v_late_fee := 0;
            END CASE;
            
            -- Insert the rental
            INSERT INTO rentals (
                customer_id, tape_id, rental_date, due_date, return_date, late_fees
            ) VALUES (
                v_customer_id, v_tape_id, v_rental_date, v_due_date, v_return_date, v_late_fee
            );
            
            -- Update tape stock (decrement stock_available)
            IF v_return_date IS NULL THEN
                UPDATE tapes SET stock_available = stock_available - 1 WHERE tape_id = v_tape_id;
            END IF;
        END LOOP;
    END LOOP;
    CLOSE v_customer_cursor;
END;
$$ LANGUAGE plpgsql;

-- Execute the function to generate rentals
SELECT generate_sample_rentals();

-- Clean up the function
DROP FUNCTION generate_sample_rentals();

-- Display inserted rentals
SELECT 
    r.rental_id,
    c.first_name || ' ' || c.last_name AS customer,
    t.title,
    r.rental_date,
    r.due_date,
    r.return_date,
    r.late_fees,
    CASE 
        WHEN r.return_date IS NOT NULL THEN 'Returned'
        WHEN r.due_date < CURRENT_TIMESTAMP THEN 'Overdue'
        ELSE 'Active'
    END AS status
FROM 
    rentals r
JOIN 
    customers c ON r.customer_id = c.customer_id
JOIN 
    tapes t ON r.tape_id = t.tape_id
ORDER BY 
    r.rental_date DESC; 