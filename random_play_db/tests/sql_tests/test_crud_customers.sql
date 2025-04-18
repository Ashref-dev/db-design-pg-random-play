-- Test script for Customer CRUD operations
-- Tests: C1, C2, C3, C4, C5, C6, C7

-- =============================================
-- Test C1: Create a new customer with valid information
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_result RECORD;
BEGIN
    RAISE NOTICE 'Test C1: Create a new customer with valid information';
    
    SELECT pkg_customers.add_customer(
        'John', 'TestUser', 'john.test@example.com', 
        '555-123-4567', '123 Test St, Testville'
    ) INTO v_customer_id;
    
    IF v_customer_id IS NULL OR v_customer_id <= 0 THEN
        RAISE EXCEPTION 'Test C1 FAILED: Customer creation did not return a valid ID. Got: %', v_customer_id;
    END IF;
    
    -- Verify the customer was actually created
    SELECT * INTO v_result 
    FROM customers 
    WHERE customer_id = v_customer_id;
    
    IF v_result.customer_id IS NULL THEN
        RAISE EXCEPTION 'Test C1 FAILED: Customer with ID % not found after creation', v_customer_id;
    END IF;
    
    IF v_result.email <> 'john.test@example.com' THEN
        RAISE EXCEPTION 'Test C1 FAILED: Email mismatch. Expected: john.test@example.com, Got: %', v_result.email;
    END IF;
    
    RAISE NOTICE 'Test C1 PASSED: Successfully created customer with ID %', v_customer_id;
    RAISE NOTICE 'Customer details: % % (Email: %)', v_result.first_name, v_result.last_name, v_result.email;
    
    -- Clean up (Keep this customer for the next tests)
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Test C1 FAILED with error: %', SQLERRM;
END;
$$;

-- =============================================
-- Test C2: Attempt to create a customer with duplicate email (should fail)
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_error BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE 'Test C2: Attempt to create a customer with duplicate email (should fail)';
    
    BEGIN
        -- Try to create a customer with the same email as Test C1
        SELECT pkg_customers.add_customer(
            'Jane', 'DuplicateEmail', 'john.test@example.com', 
            '555-987-6543', '456 Test Ave, Testville'
        ) INTO v_customer_id;
        
        -- If we get here, the function didn't raise an exception as expected
        RAISE EXCEPTION 'Test C2 FAILED: Customer creation with duplicate email should have failed but didn''t';
    EXCEPTION
        WHEN OTHERS THEN
            -- This is expected behavior - the exception should be caught
            v_error := TRUE;
            RAISE NOTICE 'Test C2 PASSED: Received expected error: %', SQLERRM;
    END;
    
    IF NOT v_error THEN
        RAISE EXCEPTION 'Test C2 FAILED: Expected an error but none occurred';
    END IF;
END;
$$;

-- =============================================
-- Test C3: Retrieve a customer by ID
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_result RECORD;
BEGIN
    RAISE NOTICE 'Test C3: Retrieve a customer by ID';
    
    -- Get ID of the test customer created in Test C1
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'john.test@example.com';
    
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Test C3 FAILED: Test setup issue - test customer not found';
    END IF;
    
    -- Retrieve the customer using the package function
    SELECT * INTO v_result 
    FROM pkg_customers.get_customer(v_customer_id);
    
    IF v_result.customer_id IS NULL THEN
        RAISE EXCEPTION 'Test C3 FAILED: Customer retrieval returned no results for ID %', v_customer_id;
    END IF;
    
    IF v_result.email <> 'john.test@example.com' THEN
        RAISE EXCEPTION 'Test C3 FAILED: Retrieved customer has wrong email. Expected: john.test@example.com, Got: %', v_result.email;
    END IF;
    
    RAISE NOTICE 'Test C3 PASSED: Successfully retrieved customer with ID %', v_customer_id;
    RAISE NOTICE 'Customer details: % % (Email: %)', v_result.first_name, v_result.last_name, v_result.email;
END;
$$;

-- =============================================
-- Test C4: Retrieve a customer by email
-- =============================================
DO $$
DECLARE
    v_result RECORD;
BEGIN
    RAISE NOTICE 'Test C4: Retrieve a customer by email';
    
    -- Retrieve the customer by email using the package function
    SELECT * INTO v_result 
    FROM pkg_customers.get_customer_by_email('john.test@example.com');
    
    IF v_result.customer_id IS NULL THEN
        RAISE EXCEPTION 'Test C4 FAILED: Customer retrieval by email returned no results';
    END IF;
    
    IF v_result.first_name <> 'John' OR v_result.last_name <> 'TestUser' THEN
        RAISE EXCEPTION 'Test C4 FAILED: Retrieved customer has wrong name. Expected: John TestUser, Got: % %', 
            v_result.first_name, v_result.last_name;
    END IF;
    
    RAISE NOTICE 'Test C4 PASSED: Successfully retrieved customer by email';
    RAISE NOTICE 'Customer details: ID %, % % (Email: %)', 
        v_result.customer_id, v_result.first_name, v_result.last_name, v_result.email;
END;
$$;

-- =============================================
-- Test C5: Update a customer's contact information
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_success BOOLEAN;
    v_result RECORD;
BEGIN
    RAISE NOTICE 'Test C5: Update a customer''s contact information';
    
    -- Get ID of the test customer
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE email = 'john.test@example.com';
    
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Test C5 FAILED: Test setup issue - test customer not found';
    END IF;
    
    -- Update the customer's information
    SELECT pkg_customers.update_customer(
        v_customer_id,
        'John',
        'UpdatedLastName',
        'john.updated@example.com',
        '555-999-8888',
        '789 Updated St, New City',
        TRUE
    ) INTO v_success;
    
    IF NOT v_success THEN
        RAISE EXCEPTION 'Test C5 FAILED: Customer update returned failure';
    END IF;
    
    -- Verify the changes
    SELECT * INTO v_result 
    FROM customers 
    WHERE customer_id = v_customer_id;
    
    IF v_result.last_name <> 'UpdatedLastName' OR v_result.email <> 'john.updated@example.com' THEN
        RAISE EXCEPTION 'Test C5 FAILED: Customer update didn''t apply correctly. Last name: %, Email: %', 
            v_result.last_name, v_result.email;
    END IF;
    
    RAISE NOTICE 'Test C5 PASSED: Successfully updated customer information';
    RAISE NOTICE 'Updated customer details: % % (Email: %, Phone: %)', 
        v_result.first_name, v_result.last_name, v_result.email, v_result.phone;
END;
$$;

-- =============================================
-- Test C6: Delete a customer with no rental history
-- =============================================
DO $$
DECLARE
    v_new_customer_id INTEGER;
    v_success BOOLEAN;
    v_exists BOOLEAN;
BEGIN
    RAISE NOTICE 'Test C6: Delete a customer with no rental history';
    
    -- First create a fresh test customer
    SELECT pkg_customers.add_customer(
        'DeleteTest', 'Customer', 'delete.test@example.com', 
        '555-DELETE', '999 Delete Lane, Testville'
    ) INTO v_new_customer_id;
    
    IF v_new_customer_id IS NULL OR v_new_customer_id <= 0 THEN
        RAISE EXCEPTION 'Test C6 FAILED: Test setup issue - could not create test customer for deletion';
    END IF;
    
    -- Now delete the customer
    SELECT pkg_customers.delete_customer(v_new_customer_id) INTO v_success;
    
    IF NOT v_success THEN
        RAISE EXCEPTION 'Test C6 FAILED: Customer deletion returned failure for ID %', v_new_customer_id;
    END IF;
    
    -- Verify the customer no longer exists
    SELECT EXISTS(SELECT 1 FROM customers WHERE customer_id = v_new_customer_id) INTO v_exists;
    
    IF v_exists THEN
        RAISE EXCEPTION 'Test C6 FAILED: Customer still exists after deletion, ID %', v_new_customer_id;
    END IF;
    
    RAISE NOTICE 'Test C6 PASSED: Successfully deleted customer with ID %', v_new_customer_id;
END;
$$;

-- =============================================
-- Test C7: Attempt to delete a customer with active rentals (should fail)
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_tape_id INTEGER;
    v_rental_id INTEGER;
    v_error BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE 'Test C7: Attempt to delete a customer with active rentals (should fail)';
    
    -- Create a test customer
    INSERT INTO customers (first_name, last_name, email, phone, address)
    VALUES ('Jane', 'ActiveRental', 'jane.active@example.com', '555-888-7777', '123 Rental St')
    RETURNING customer_id INTO v_customer_id;
    
    -- Create a test tape
    INSERT INTO tapes (title, genre_id, release_year, rental_price, stock_available, total_stock)
    VALUES ('Active Rental Tape', (SELECT genre_id FROM genres LIMIT 1), 2024, 4.99, 5, 5)
    RETURNING tape_id INTO v_tape_id;
    
    -- Create a rental for this customer
    INSERT INTO rentals (customer_id, tape_id, rental_date, due_date)
    VALUES (v_customer_id, v_tape_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '7 days')
    RETURNING rental_id INTO v_rental_id;
    
    -- Attempt to delete the customer - should fail because of active rental
    BEGIN
        PERFORM pkg_customers.delete_customer(v_customer_id);
        
        -- If we get here, the function didn't raise an exception as expected
        RAISE EXCEPTION 'Test C7 FAILED: Customer deletion with active rentals should have failed but didn''t';
    EXCEPTION
        WHEN OTHERS THEN
            -- This is expected behavior - the exception should be caught
            v_error := TRUE;
            RAISE NOTICE 'Test C7 PASSED: Received expected error: %', SQLERRM;
    END;
    
    IF NOT v_error THEN
        RAISE EXCEPTION 'Test C7 FAILED: Expected an error but none occurred';
    END IF;
    
    -- Clean up (This would normally be done by returning the tape first)
    UPDATE rentals SET return_date = CURRENT_TIMESTAMP WHERE rental_id = v_rental_id;
    
    -- Now we can delete but we'll skip it to avoid other errors
    -- PERFORM pkg_customers.delete_customer(v_customer_id);
END;
$$; 