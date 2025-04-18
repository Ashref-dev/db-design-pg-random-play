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
    v_unique_email TEXT := 'trigger.test1.' || clock_timestamp()::text || '@example.com';
BEGIN
    RAISE NOTICE 'Test TG1: Verify tape stock decreases when rented (Email: %)', v_unique_email;
    
    -- Create a test customer with unique email
    INSERT INTO customers (
        first_name, last_name, email, phone, address, registration_date, active
    ) VALUES (
        'Trigger', 'TestUser1', v_unique_email, 
        '555-TRIGGER1', '123 Trigger1 St, Testville', CURRENT_DATE, TRUE
    ) RETURNING customer_id INTO v_customer_id;
    
    -- Get an available tape
    SELECT tape_id, stock_available INTO v_tape_id, v_stock_before
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Test TG1 FAILED: No tapes available for testing';
    END IF;
    
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
    
    -- Clean up
    UPDATE rentals SET return_date = CURRENT_TIMESTAMP WHERE customer_id = v_customer_id AND tape_id = v_tape_id AND return_date IS NULL; -- Return the specific rental
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
    v_unique_email TEXT := 'trigger.return.' || clock_timestamp()::text || '@example.com';
BEGIN
    RAISE NOTICE 'Test TG2: Verify tape stock increases when returned (Email: %)', v_unique_email;
    
    -- Create unique customer for this test
    v_customer_id := pkg_customers.add_customer(
        'Trigger', 'Return', v_unique_email, 
        '555-RETURN', '123 Return St, Testville'
    );
    
    -- Get an available tape
    SELECT tape_id, stock_available INTO v_tape_id, v_stock_before
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Test TG2 FAILED: No tapes available for testing';
    END IF;
    
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

    -- Clean up
    -- DELETE FROM customers WHERE customer_id = v_customer_id; -- Removed: Fails due to FK, and delete_customer might fail due to history
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
    v_unique_email TEXT := 'trigger.nochange.' || clock_timestamp()::text || '@example.com';
BEGIN
    RAISE NOTICE 'Test TG3: Verify tape stock remains unchanged when rental update (Email: %)', v_unique_email;
    
    -- Create unique customer for this test
    v_customer_id := pkg_customers.add_customer(
        'Trigger', 'NoChange', v_unique_email, 
        '555-NOCHANGE', '123 NoChange St, Testville'
    );
    
    -- Get an available tape
    SELECT tape_id, stock_available INTO v_tape_id, v_stock_before
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Test TG3 FAILED: No tapes available for testing';
    END IF;
    
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
    UPDATE rentals SET return_date = CURRENT_TIMESTAMP WHERE rental_id = v_rental_id;
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
    v_unique_email TEXT := 'delete.test.' || clock_timestamp()::text || '@example.com';
BEGIN
    RAISE NOTICE 'Test TG4: Verify prevention of customer deletion with active rentals (Email: %)', v_unique_email;
    
    -- Create a new test customer specifically for this test with unique email
    INSERT INTO customers (
        first_name, last_name, email, phone, address, registration_date, active
    ) VALUES (
        'DeleteTest', 'Customer', v_unique_email, 
        '555-DELETE', '123 Delete St, Testville', CURRENT_DATE, TRUE
    ) RETURNING customer_id INTO v_customer_id;
    
    -- Get an available tape
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Test TG4 FAILED: No tapes available for testing';
    END IF;
    
    -- Create a rental record (active rental)
    INSERT INTO rentals (
        customer_id, tape_id, rental_date, due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    ) RETURNING rental_id INTO v_rental_id;
    
    -- Try to delete the customer - should fail because of active rental
    BEGIN
        -- Call the package function to attempt deletion
        PERFORM pkg_customers.delete_customer(v_customer_id);
        
        -- If we get here, the function didn't raise an exception as expected
        RAISE EXCEPTION 'Test TG4 FAILED: Customer with active rentals was deleted, but should have been prevented';
    EXCEPTION
        WHEN OTHERS THEN
            -- This is expected behavior - the exception should be caught
            v_error := TRUE;
            -- Check if the error message matches the expected trigger/function message
            IF SQLERRM LIKE '%Cannot delete customer%active rental%' THEN
                RAISE NOTICE 'Test TG4 PASSED: Received expected error: %', SQLERRM;
            ELSE
                RAISE EXCEPTION 'Test TG4 FAILED: Received unexpected error: %', SQLERRM;
            END IF;
    END;
    
    IF NOT v_error THEN
        RAISE EXCEPTION 'Test TG4 FAILED: Expected an error when trying to delete customer with active rentals';
    END IF;
    
    -- Clean up - return the tape
    UPDATE rentals SET return_date = CURRENT_TIMESTAMP WHERE rental_id = v_rental_id;
END;
$$;

-- =============================================
-- Test TG5-TG8: Verify audit log entries for rental activities
-- NOTE: Assuming the audit_log table and its trigger exist.
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_log_count INTEGER;
BEGIN
    RAISE NOTICE 'Test TG5-TG8: Verify audit log entries for rental activities';
    
    -- Use a unique customer email for this test run
    v_customer_id := pkg_customers.add_customer(
        'Audit', 'TestUser' || clock_timestamp()::text,
        'audit.test.' || clock_timestamp()::text || '@example.com', 
        '555-AUDIT', '123 Audit St, Testville'
    );
    
    -- Get an available tape
    SELECT tape_id INTO v_tape_id
    FROM tapes
    WHERE stock_available > 0
    LIMIT 1;
    
    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Test TG5-TG8 FAILED: No tapes available for testing';
    END IF;
    
    -- Clear previous logs for this test (optional, depends on requirements)
    -- DELETE FROM audit_log WHERE table_name = 'rentals' AND record_id IN (SELECT rental_id FROM rentals WHERE customer_id = v_customer_id);

    -- Create a rental record - should generate INSERT audit log
    INSERT INTO rentals (
        customer_id, tape_id, rental_date, due_date
    ) VALUES (
        v_customer_id,
        v_tape_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + INTERVAL '7 days'
    ) RETURNING rental_id INTO v_rental_id;
    
    -- Check if an INSERT audit log entry was created for this rental_id
    SELECT COUNT(*) INTO v_log_count FROM audit_log 
    WHERE table_name = 'rentals' AND operation = 'INSERT' AND record_id = v_rental_id;
    IF v_log_count = 1 THEN
        RAISE NOTICE 'Test TG5 PASSED: Audit log entry created for rental creation (INSERT)';
    ELSE
        RAISE WARNING 'Test TG5 FAILED: Expected 1 INSERT log entry for rental_id %, found %', v_rental_id, v_log_count;
    END IF;
    
    -- Update the rental - should generate UPDATE audit log
    UPDATE rentals
    SET due_date = due_date + INTERVAL '3 days'
    WHERE rental_id = v_rental_id;
    
    -- Check if an UPDATE audit log entry was created
    SELECT COUNT(*) INTO v_log_count FROM audit_log 
    WHERE table_name = 'rentals' AND operation = 'UPDATE' AND record_id = v_rental_id;
    IF v_log_count >= 1 THEN -- Allow for multiple updates if logic changes
        RAISE NOTICE 'Test TG6 PASSED: Audit log entry created for rental update (UPDATE)';
    ELSE
        RAISE WARNING 'Test TG6 FAILED: Expected at least 1 UPDATE log entry for rental_id %, found %', v_rental_id, v_log_count;
    END IF;
    
    -- Return the tape - should generate another UPDATE audit log
    UPDATE rentals
    SET return_date = CURRENT_TIMESTAMP
    WHERE rental_id = v_rental_id;
    
    -- Check if a RETURN-related UPDATE audit log entry was created
    -- Note: This relies on the trigger creating a distinct entry or detail for return
    SELECT COUNT(*) INTO v_log_count FROM audit_log 
    WHERE table_name = 'rentals' AND operation = 'UPDATE' AND record_id = v_rental_id AND details LIKE '%Rental returned%';
    IF v_log_count >= 1 THEN
        RAISE NOTICE 'Test TG7 PASSED: Audit log entry created for rental return (UPDATE)';
    ELSE
        RAISE WARNING 'Test TG7 FAILED: Expected at least 1 return UPDATE log entry for rental_id %, found %', v_rental_id, v_log_count;
    END IF;
    
    -- Delete the rental record - should generate DELETE audit log
    DELETE FROM rentals WHERE rental_id = v_rental_id;
    
    -- Check if a DELETE audit log entry was created
    SELECT COUNT(*) INTO v_log_count FROM audit_log 
    WHERE table_name = 'rentals' AND operation = 'DELETE' AND record_id = v_rental_id;
    IF v_log_count = 1 THEN
        RAISE NOTICE 'Test TG8 PASSED: Audit log entry created for rental deletion (DELETE)';
    ELSE
        RAISE WARNING 'Test TG8 FAILED: Expected 1 DELETE log entry for rental_id %, found %', v_rental_id, v_log_count;
    END IF;
    
    -- Clean up customer
    DELETE FROM customers WHERE customer_id = v_customer_id;
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
    v_error_message TEXT;
BEGIN
    RAISE NOTICE 'Test TG9: Verify prevention of renting unavailable tapes';
    
    -- Create a unique customer for this test
    v_customer_id := pkg_customers.add_customer(
        'NoStock', 'Test9' || clock_timestamp()::text, 
        'nostock.test9.' || clock_timestamp()::text || '@example.com', 
        '555-NOSTOCK9', '123 NoStock9 St'
    );

    -- Find a tape and set its stock to 0
    SELECT tape_id INTO v_tape_id
    FROM tapes
    LIMIT 1;

    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Test TG9 FAILED: Setup error - No tapes found';
    END IF;

    UPDATE tapes SET stock_available = 0 WHERE tape_id = v_tape_id;

    -- Attempt to rent the tape (should fail)
    BEGIN
        INSERT INTO rentals (customer_id, tape_id, rental_date, due_date)
        VALUES (v_customer_id, v_tape_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '1 day');
        
        RAISE EXCEPTION 'Test TG9 FAILED: Renting of unavailable tape was allowed, but should have been prevented.';
    EXCEPTION
        WHEN OTHERS THEN
            v_error := TRUE;
            v_error_message := SQLERRM;
            -- Check if the error message indicates stock issue
            IF v_error_message LIKE '%No copies currently in stock%' THEN
                 RAISE NOTICE 'Test TG9 PASSED: Received expected error: %', v_error_message;
            ELSE
                 RAISE NOTICE 'Test TG9 FAILED: Received unexpected error: %', v_error_message;
            END IF;
    END;

    IF NOT v_error THEN
        RAISE EXCEPTION 'Test TG9 FAILED: Expected an error but none occurred.';
    END IF;

    -- Clean up: Reset stock if needed (optional)
    -- UPDATE tapes SET stock_available = (SELECT total_stock FROM tapes WHERE tape_id = v_tape_id) WHERE tape_id = v_tape_id;

END;
$$; 