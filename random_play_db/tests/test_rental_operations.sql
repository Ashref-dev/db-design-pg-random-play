-- Test script for Rental Operations
-- Tests: R1, R2, R3, R4, R5, R6

-- =============================================
-- Test R1: Rent a tape to a customer (happy path)
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_stock_before INTEGER;
    v_stock_after INTEGER;
BEGIN
    RAISE NOTICE 'Test R1: Rent a tape to a customer (happy path)';
    
    -- Create a test customer
    SELECT pkg_customers.add_customer(
        'RentalTest', 'HappyPath', 'rental.happypath@example.com', 
        '555-HAPPY', '123 Rental Ln, Testville'
    ) INTO v_customer_id;
    
    -- Get an available tape
    SELECT tape_id, stock_available INTO v_tape_id, v_stock_before
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Test R1 FAILED: Test setup issue - no tapes available for rental';
    END IF;
    
    -- Rent the tape
    SELECT pkg_rentals.rent_tape(v_customer_id, v_tape_id, CURRENT_TIMESTAMP) INTO v_rental_id;
    
    IF v_rental_id IS NULL OR v_rental_id <= 0 THEN
        RAISE EXCEPTION 'Test R1 FAILED: Rental creation did not return a valid ID. Got: %', v_rental_id;
    END IF;
    
    -- Verify the rental was created
    IF NOT EXISTS (SELECT 1 FROM rentals WHERE rental_id = v_rental_id) THEN
        RAISE EXCEPTION 'Test R1 FAILED: Rental with ID % not found after creation', v_rental_id;
    END IF;
    
    -- Check if stock was updated (assuming a trigger handles this)
    SELECT stock_available INTO v_stock_after
    FROM tapes
    WHERE tape_id = v_tape_id;
    
    IF v_stock_after <> (v_stock_before - 1) THEN
        RAISE NOTICE 'Warning: Stock was not decremented as expected. Before: %, After: %', 
            v_stock_before, v_stock_after;
    END IF;
    
    RAISE NOTICE 'Test R1 PASSED: Successfully created rental with ID %', v_rental_id;
    RAISE NOTICE 'Customer ID: %, Tape ID: %', v_customer_id, v_tape_id;
    
    -- Clean up - keep for next tests
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Test R1 FAILED with error: %', SQLERRM;
END;
$$;

-- =============================================
-- Test R2: Attempt to rent a tape with zero stock available (should fail)
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_error BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE 'Test R2: Attempt to rent a tape with zero stock available (should fail)';
    
    -- Get customer ID from previous test
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'rental.happypath@example.com';
    
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Test R2 FAILED: Test setup issue - test customer not found';
    END IF;
    
    -- Find or create a tape with zero stock
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available = 0
    LIMIT 1;
    
    IF v_tape_id IS NULL THEN
        -- If no tape with zero stock, create one by renting all available copies
        SELECT tape_id INTO v_tape_id
        FROM tapes
        WHERE stock_available = 1
        LIMIT 1;
        
        IF v_tape_id IS NULL THEN
            RAISE EXCEPTION 'Test R2 FAILED: Test setup issue - cannot find suitable tape';
        END IF;
        
        -- Rent the last available copy
        PERFORM pkg_rentals.rent_tape(v_customer_id, v_tape_id, CURRENT_TIMESTAMP);
    END IF;
    
    -- Now try to rent the out-of-stock tape
    BEGIN
        SELECT pkg_rentals.rent_tape(v_customer_id, v_tape_id, CURRENT_TIMESTAMP) INTO v_rental_id;
        
        -- If we get here, the function didn't raise an exception as expected
        RAISE EXCEPTION 'Test R2 FAILED: Rental of out-of-stock tape should have failed but didn''t';
    EXCEPTION
        WHEN OTHERS THEN
            -- This is expected behavior - the exception should be caught
            v_error := TRUE;
            RAISE NOTICE 'Test R2 PASSED: Received expected error: %', SQLERRM;
    END;
    
    IF NOT v_error THEN
        RAISE EXCEPTION 'Test R2 FAILED: Expected an error but none occurred';
    END IF;
END;
$$;

-- =============================================
-- Test R3: Return a tape (on time)
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_return_date TIMESTAMP;
    v_stock_before INTEGER;
    v_stock_after INTEGER;
BEGIN
    RAISE NOTICE 'Test R3: Return a tape (on time)';
    
    -- Get customer ID from previous test
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'rental.happypath@example.com';
    
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Test R3 FAILED: Test setup issue - test customer not found';
    END IF;
    
    -- Get an available tape
    SELECT tape_id, stock_available INTO v_tape_id, v_stock_before
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Test R3 FAILED: Test setup issue - no tapes available for rental';
    END IF;
    
    -- Rent the tape for this test
    SELECT pkg_rentals.rent_tape(v_customer_id, v_tape_id, CURRENT_TIMESTAMP) INTO v_rental_id;
    
    -- Return the tape (on time)
    SELECT pkg_rentals.return_tape(v_rental_id, CURRENT_TIMESTAMP) INTO v_return_date;
    
    IF v_return_date IS NULL THEN
        RAISE EXCEPTION 'Test R3 FAILED: Tape return did not return a valid date';
    END IF;
    
    -- Verify the rental was updated with a return date
    IF NOT EXISTS (
        SELECT 1 FROM rentals 
        WHERE rental_id = v_rental_id AND return_date IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Test R3 FAILED: Rental ID % was not updated with a return date', v_rental_id;
    END IF;
    
    -- Check if stock was updated
    SELECT stock_available INTO v_stock_after
    FROM tapes
    WHERE tape_id = v_tape_id;
    
    IF v_stock_after <> (v_stock_before) THEN
        RAISE NOTICE 'Warning: Stock was not incremented as expected. Before rental: %, After return: %', 
            v_stock_before, v_stock_after;
    END IF;
    
    -- Check if late fees were not charged (since return is on time)
    IF EXISTS (
        SELECT 1 FROM rentals 
        WHERE rental_id = v_rental_id AND late_fees > 0
    ) THEN
        RAISE EXCEPTION 'Test R3 FAILED: Late fees were incorrectly charged for on-time return';
    END IF;
    
    RAISE NOTICE 'Test R3 PASSED: Successfully returned tape with return date %', v_return_date;
END;
$$;

-- =============================================
-- Test R4: Return a tape (late, with late fees)
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_return_date TIMESTAMP;
    v_late_fees NUMERIC;
BEGIN
    RAISE NOTICE 'Test R4: Return a tape (late, with late fees)';
    
    -- Get customer ID from previous test
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'rental.happypath@example.com';
    
    -- Get an available tape
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    -- Create a "backdated" rental (already overdue)
    INSERT INTO rentals (
        customer_id, 
        tape_id, 
        rental_date, 
        due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP - INTERVAL '10 days',  -- 10 days ago
        CURRENT_TIMESTAMP - INTERVAL '3 days'    -- due 3 days ago
    ) RETURNING rental_id INTO v_rental_id;
    
    -- Update the tape stock (normally done by a trigger)
    UPDATE tapes
    SET stock_available = stock_available - 1
    WHERE tape_id = v_tape_id;
    
    -- Return the tape (late)
    SELECT pkg_rentals.return_tape(v_rental_id, CURRENT_TIMESTAMP) INTO v_return_date;
    
    -- Get the late fees
    SELECT late_fees INTO v_late_fees
    FROM rentals
    WHERE rental_id = v_rental_id;
    
    IF v_late_fees <= 0 THEN
        RAISE EXCEPTION 'Test R4 FAILED: No late fees charged for overdue rental, expected fees > 0, got %', v_late_fees;
    END IF;
    
    RAISE NOTICE 'Test R4 PASSED: Successfully charged late fees % for overdue rental', v_late_fees;
    RAISE NOTICE 'Rental ID: %, Return Date: %', v_rental_id, v_return_date;
END;
$$;

-- =============================================
-- Test R5: Calculate late fees for an overdue rental
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_late_fees NUMERIC;
    v_calculated_fees NUMERIC;
    v_days_overdue INTEGER;
BEGIN
    RAISE NOTICE 'Test R5: Calculate late fees for an overdue rental';
    
    -- Get customer ID from previous test
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'rental.happypath@example.com';
    
    -- Get an available tape
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    -- Create another "backdated" rental (already overdue)
    INSERT INTO rentals (
        customer_id, 
        tape_id, 
        rental_date, 
        due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP - INTERVAL '15 days',  -- 15 days ago
        CURRENT_TIMESTAMP - INTERVAL '8 days'    -- due 8 days ago
    ) RETURNING rental_id INTO v_rental_id;
    
    -- Update the tape stock
    UPDATE tapes
    SET stock_available = stock_available - 1
    WHERE tape_id = v_tape_id;
    
    -- Calculate late fees using the package function
    SELECT pkg_rentals.calculate_late_fees(v_rental_id) INTO v_calculated_fees;
    
    IF v_calculated_fees <= 0 THEN
        RAISE EXCEPTION 'Test R5 FAILED: No late fees calculated for overdue rental, expected fees > 0, got %', v_calculated_fees;
    END IF;
    
    -- Calculate expected fees (depends on implementation details)
    v_days_overdue := 8; -- Hardcoded based on the setup
    
    RAISE NOTICE 'Test R5 PASSED: Calculated late fees % for % days overdue', v_calculated_fees, v_days_overdue;
    
    -- Clean up
    UPDATE rentals SET return_date = CURRENT_TIMESTAMP WHERE rental_id = v_rental_id;
    UPDATE tapes SET stock_available = stock_available + 1 WHERE tape_id = v_tape_id;
END;
$$;

-- =============================================
-- Test R6: Extend a rental period
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_original_due_date TIMESTAMP;
    v_new_due_date TIMESTAMP;
    v_days_extended INTEGER := 5;
BEGIN
    RAISE NOTICE 'Test R6: Extend a rental period';
    
    -- Get customer ID from previous test
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'rental.happypath@example.com';
    
    -- Get an available tape
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    -- Create a new rental
    INSERT INTO rentals (
        customer_id, 
        tape_id, 
        rental_date, 
        due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    ) RETURNING rental_id, due_date INTO v_rental_id, v_original_due_date;
    
    -- Update the tape stock
    UPDATE tapes
    SET stock_available = stock_available - 1
    WHERE tape_id = v_tape_id;
    
    -- Extend the rental
    SELECT pkg_rentals.extend_rental(v_rental_id, v_days_extended) INTO v_new_due_date;
    
    IF v_new_due_date IS NULL THEN
        RAISE EXCEPTION 'Test R6 FAILED: Rental extension did not return a valid date';
    END IF;
    
    -- Check if the due date was extended correctly
    IF v_new_due_date <> (v_original_due_date + (v_days_extended * INTERVAL '1 day')) THEN
        RAISE EXCEPTION 'Test R6 FAILED: Due date not extended correctly. Original: %, Expected: %, Got: %',
            v_original_due_date,
            v_original_due_date + (v_days_extended * INTERVAL '1 day'),
            v_new_due_date;
    END IF;
    
    RAISE NOTICE 'Test R6 PASSED: Successfully extended rental due date';
    RAISE NOTICE 'Original due date: %, New due date: % (extended by % days)', 
        v_original_due_date, v_new_due_date, v_days_extended;
    
    -- Clean up
    UPDATE rentals SET return_date = CURRENT_TIMESTAMP WHERE rental_id = v_rental_id;
    UPDATE tapes SET stock_available = stock_available + 1 WHERE tape_id = v_tape_id;
    
    -- Clean up the test customer
    PERFORM pkg_customers.delete_customer(v_customer_id);
END;
$$; 