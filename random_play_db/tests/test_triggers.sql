-- Test script for Trigger functionality
-- Tests: TG1, TG2, TG3, TG4, TG5, TG6, TG7, TG8, TG9

-- =============================================
-- Test TG1: Verify tape stock decreases when rented
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_stock_before INTEGER;
    v_stock_after INTEGER;
BEGIN
    RAISE NOTICE 'Test TG1: Verify tape stock decreases when rented';
    
    -- Create a test customer
    INSERT INTO customers (
        first_name, last_name, email, phone, address, registration_date, active
    ) VALUES (
        'Trigger', 'TestUser', 'trigger.test@example.com', 
        '555-TRIGGER', '123 Trigger St, Testville', CURRENT_DATE, TRUE
    ) RETURNING customer_id INTO v_customer_id;
    
    -- Get an available tape
    SELECT tape_id, stock_available INTO v_tape_id, v_stock_before
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    -- Create a rental record - this should trigger stock update
    INSERT INTO rentals (
        customer_id, tape_id, rental_date, due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    );
    
    -- Check if stock was updated by the trigger
    SELECT stock_available INTO v_stock_after
    FROM tapes
    WHERE tape_id = v_tape_id;
    
    IF v_stock_after <> (v_stock_before - 1) THEN
        RAISE EXCEPTION 'Test TG1 FAILED: Stock not decremented by trigger. Before: %, After: %', 
            v_stock_before, v_stock_after;
    END IF;
    
    RAISE NOTICE 'Test TG1 PASSED: Stock correctly decreased from % to %', v_stock_before, v_stock_after;
    
    -- Keep everything for next tests
END;
$$;

-- =============================================
-- Test TG2: Verify tape stock increases when returned
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_stock_before INTEGER;
    v_stock_after INTEGER;
BEGIN
    RAISE NOTICE 'Test TG2: Verify tape stock increases when returned';
    
    -- Get the test customer ID
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'trigger.test@example.com';
    
    -- Get an available tape
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    -- Create a rental record
    INSERT INTO rentals (
        customer_id, tape_id, rental_date, due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    ) RETURNING rental_id INTO v_rental_id;
    
    -- Get stock after rental
    SELECT stock_available INTO v_stock_before
    FROM tapes
    WHERE tape_id = v_tape_id;
    
    -- Return the tape - this should trigger stock update
    UPDATE rentals
    SET return_date = CURRENT_TIMESTAMP
    WHERE rental_id = v_rental_id;
    
    -- Check if stock was updated by the trigger
    SELECT stock_available INTO v_stock_after
    FROM tapes
    WHERE tape_id = v_tape_id;
    
    IF v_stock_after <> (v_stock_before + 1) THEN
        RAISE EXCEPTION 'Test TG2 FAILED: Stock not incremented by trigger. Before: %, After: %', 
            v_stock_before, v_stock_after;
    END IF;
    
    RAISE NOTICE 'Test TG2 PASSED: Stock correctly increased from % to %', v_stock_before, v_stock_after;
END;
$$;

-- =============================================
-- Test TG3: Verify tape stock remains unchanged when rental is updated (without return)
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_stock_before INTEGER;
    v_stock_after INTEGER;
BEGIN
    RAISE NOTICE 'Test TG3: Verify tape stock remains unchanged when rental is updated (without return)';
    
    -- Get the test customer ID
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'trigger.test@example.com';
    
    -- Get an available tape
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    -- Create a rental record
    INSERT INTO rentals (
        customer_id, tape_id, rental_date, due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    ) RETURNING rental_id INTO v_rental_id;
    
    -- Get stock after rental
    SELECT stock_available INTO v_stock_before
    FROM tapes
    WHERE tape_id = v_tape_id;
    
    -- Update the rental (but not the return_date) - this should NOT trigger stock update
    UPDATE rentals
    SET due_date = due_date + INTERVAL '3 days'
    WHERE rental_id = v_rental_id;
    
    -- Check if stock remained unchanged
    SELECT stock_available INTO v_stock_after
    FROM tapes
    WHERE tape_id = v_tape_id;
    
    IF v_stock_after <> v_stock_before THEN
        RAISE EXCEPTION 'Test TG3 FAILED: Stock changed incorrectly. Before: %, After: %', 
            v_stock_before, v_stock_after;
    END IF;
    
    RAISE NOTICE 'Test TG3 PASSED: Stock correctly remained at % after rental update', v_stock_after;
    
    -- Clean up - return the tape
    UPDATE rentals
    SET return_date = CURRENT_TIMESTAMP
    WHERE rental_id = v_rental_id;
END;
$$;

-- =============================================
-- Test TG4: Verify prevention of customer deletion with active rentals
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_error BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE 'Test TG4: Verify prevention of customer deletion with active rentals';
    
    -- Get the test customer ID
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'trigger.test@example.com';
    
    -- Get an available tape
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    -- Create a rental record (active rental)
    INSERT INTO rentals (
        customer_id, tape_id, rental_date, due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    ) RETURNING rental_id INTO v_rental_id;
    
    -- Try to delete the customer - this should be prevented by trigger
    BEGIN
        DELETE FROM customers
        WHERE customer_id = v_customer_id;
        
        -- If we get here, the trigger didn't prevent the deletion
        RAISE EXCEPTION 'Test TG4 FAILED: Customer with active rentals was deleted';
    EXCEPTION
        WHEN OTHERS THEN
            -- This is expected behavior - deletion should be prevented
            v_error := TRUE;
            RAISE NOTICE 'Test TG4 PASSED: Customer deletion was correctly prevented with error: %', SQLERRM;
    END;
    
    IF NOT v_error THEN
        RAISE EXCEPTION 'Test TG4 FAILED: Expected an error but none occurred';
    END IF;
    
    -- Clean up - return all rentals for this customer
    UPDATE rentals
    SET return_date = CURRENT_TIMESTAMP
    WHERE customer_id = v_customer_id
    AND return_date IS NULL;
    
    -- Now delete should succeed
    DELETE FROM customers
    WHERE customer_id = v_customer_id;
    
    IF EXISTS (SELECT 1 FROM customers WHERE customer_id = v_customer_id) THEN
        RAISE EXCEPTION 'Test TG4 Failed cleanup: Customer still exists after deletion';
    END IF;
    
    RAISE NOTICE 'Test TG4 cleanup passed: Customer successfully deleted after returning all tapes';
END;
$$;

-- =============================================
-- Test TG5-TG8: Verify audit log entries for rental activities
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
BEGIN
    RAISE NOTICE 'Test TG5-TG8: Verify audit log entries for rental activities';
    
    -- Create a new test customer
    INSERT INTO customers (
        first_name, last_name, email, phone, address, registration_date, active
    ) VALUES (
        'Audit', 'TestUser', 'audit.test@example.com', 
        '555-AUDIT', '456 Audit Ave, Testville', CURRENT_DATE, TRUE
    ) RETURNING customer_id INTO v_customer_id;
    
    -- Get an available tape
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    -- TG5: Create a rental record - this should create a 'RENT' audit log
    INSERT INTO rentals (
        customer_id, tape_id, rental_date, due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    ) RETURNING rental_id INTO v_rental_id;
    
    -- Check for audit log entry
    IF NOT EXISTS (
        SELECT 1 FROM rental_audit_log 
        WHERE rental_id = v_rental_id AND action_type = 'RENT'
    ) THEN
        RAISE EXCEPTION 'Test TG5 FAILED: No audit log entry for new rental';
    END IF;
    
    RAISE NOTICE 'Test TG5 PASSED: Audit log entry created for new rental';
    
    -- TG6: Return the tape - this should create a 'RETURN' audit log
    UPDATE rentals
    SET return_date = CURRENT_TIMESTAMP
    WHERE rental_id = v_rental_id;
    
    -- Check for audit log entry
    IF NOT EXISTS (
        SELECT 1 FROM rental_audit_log 
        WHERE rental_id = v_rental_id AND action_type = 'RETURN'
    ) THEN
        RAISE EXCEPTION 'Test TG6 FAILED: No audit log entry for tape return';
    END IF;
    
    RAISE NOTICE 'Test TG6 PASSED: Audit log entry created for tape return';
    
    -- Create another rental for tests TG7 and TG8
    INSERT INTO rentals (
        customer_id, tape_id, rental_date, due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    ) RETURNING rental_id INTO v_rental_id;
    
    -- TG7: Update the rental - this should create an 'UPDATE' audit log
    UPDATE rentals
    SET due_date = due_date + INTERVAL '3 days'
    WHERE rental_id = v_rental_id;
    
    -- Check for audit log entry
    IF NOT EXISTS (
        SELECT 1 FROM rental_audit_log 
        WHERE rental_id = v_rental_id AND action_type = 'UPDATE'
    ) THEN
        RAISE EXCEPTION 'Test TG7 FAILED: No audit log entry for rental update';
    END IF;
    
    RAISE NOTICE 'Test TG7 PASSED: Audit log entry created for rental update';
    
    -- Return the tape before deletion
    UPDATE rentals
    SET return_date = CURRENT_TIMESTAMP
    WHERE rental_id = v_rental_id;
    
    -- TG8: Delete the rental - this should create a 'CANCEL' audit log
    DELETE FROM rentals
    WHERE rental_id = v_rental_id;
    
    -- Check for audit log entry
    IF NOT EXISTS (
        SELECT 1 FROM rental_audit_log 
        WHERE rental_id = v_rental_id AND action_type = 'CANCEL'
    ) THEN
        RAISE EXCEPTION 'Test TG8 FAILED: No audit log entry for rental deletion';
    END IF;
    
    RAISE NOTICE 'Test TG8 PASSED: Audit log entry created for rental deletion';
    
    -- Clean up
    DELETE FROM customers
    WHERE customer_id = v_customer_id;
END;
$$;

-- =============================================
-- Test TG9: Verify prevention of renting unavailable tapes
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_error BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE 'Test TG9: Verify prevention of renting unavailable tapes';
    
    -- Create a new test customer
    INSERT INTO customers (
        first_name, last_name, email, phone, address, registration_date, active
    ) VALUES (
        'Availability', 'TestUser', 'availability.test@example.com', 
        '555-AVAIL', '789 Avail Blvd, Testville', CURRENT_DATE, TRUE
    ) RETURNING customer_id INTO v_customer_id;
    
    -- Find a tape with zero stock
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available = 0
    LIMIT 1;
    
    IF v_tape_id IS NULL THEN
        -- Make a tape unavailable by setting stock to 0
        UPDATE tapes
        SET stock_available = 0
        WHERE stock_available > 0
        LIMIT 1
        RETURNING tape_id INTO v_tape_id;
    END IF;
    
    -- Try to rent the unavailable tape - this should be prevented
    BEGIN
        INSERT INTO rentals (
            customer_id, tape_id, rental_date, due_date
        ) VALUES (
            v_customer_id,
            v_tape_id,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP + INTERVAL '7 days'
        );
        
        -- If we get here, the trigger didn't prevent the rental
        RAISE EXCEPTION 'Test TG9 FAILED: Unavailable tape was rented';
    EXCEPTION
        WHEN OTHERS THEN
            -- This is expected behavior - rental should be prevented
            v_error := TRUE;
            RAISE NOTICE 'Test TG9 PASSED: Rental of unavailable tape was correctly prevented with error: %', SQLERRM;
    END;
    
    IF NOT v_error THEN
        RAISE EXCEPTION 'Test TG9 FAILED: Expected an error but none occurred';
    END IF;
    
    -- Clean up
    DELETE FROM customers
    WHERE customer_id = v_customer_id;
END;
$$; 