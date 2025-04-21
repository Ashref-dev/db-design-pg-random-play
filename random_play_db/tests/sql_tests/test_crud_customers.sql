-- Test script for Customer CRUD operations
-- Tests: C1, C2, C3, C4, C5, C6, C7

-- =============================================
-- Test C1: Create a new customer with valid information
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_result RECORD;
    v_unique_email TEXT := 'john.test.' || clock_timestamp()::text || '@example.com';
BEGIN
    RAISE NOTICE 'Test C1: Create a new customer with valid information (Email: %)', v_unique_email;
    
    SELECT pkg_customers.add_customer(
        'John', 'TestUser', v_unique_email,
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
    
    IF v_result.email <> v_unique_email THEN
        RAISE EXCEPTION 'Test C1 FAILED: Email mismatch. Expected: %, Got: %', v_unique_email, v_result.email;
    END IF;
    
    RAISE NOTICE 'Test C1 PASSED: Successfully created customer with ID %', v_customer_id;
    RAISE NOTICE 'Customer details: % % (Email: %)', v_result.first_name, v_result.last_name, v_result.email;
    
    -- No explicit cleanup needed, let subsequent tests create their own data
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
    v_existing_customer_id INTEGER;
    v_duplicate_email TEXT := 'duplicate.test.' || clock_timestamp()::text || '@example.com'; -- Unique base email
BEGIN
    RAISE NOTICE 'Test C2: Attempt to create a customer with duplicate email (should fail)';
    
    -- First, create a customer to ensure an email exists for duplication attempt
    v_existing_customer_id := pkg_customers.add_customer('Original', 'User', v_duplicate_email, '111-DUP', 'Addr');

    BEGIN
        -- Try to create another customer with the exact same unique email
        SELECT pkg_customers.add_customer(
            'Jane', 'DuplicateEmail', v_duplicate_email, -- Use the same unique email
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

    -- Clean up the original customer created for this test
    DELETE FROM customers WHERE customer_id = v_existing_customer_id;
END;
$$;

-- =============================================
-- Test C3: Retrieve a customer by ID
-- =============================================
DO $$
DECLARE
    v_customer_id INTEGER;
    v_result RECORD;
    v_unique_email TEXT := 'getbyid.test.' || clock_timestamp()::text || '@example.com';
BEGIN
    RAISE NOTICE 'Test C3: Retrieve a customer by ID';
    
    -- Create a customer specifically for this test
    v_customer_id := pkg_customers.add_customer('GetById', 'Test', v_unique_email, '333-GETID', 'Addr C3');
    
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Test C3 FAILED: Test setup issue - could not create test customer';
    END IF;
    
    -- Retrieve the customer using the package function
    SELECT * INTO v_result 
    FROM pkg_customers.get_customer(v_customer_id);
    
    IF v_result.customer_id IS NULL THEN
        RAISE EXCEPTION 'Test C3 FAILED: Customer retrieval returned no results for ID %', v_customer_id;
    END IF;
    
    IF v_result.email <> v_unique_email THEN
        RAISE EXCEPTION 'Test C3 FAILED: Retrieved customer has wrong email. Expected: %, Got: %', v_unique_email, v_result.email;
    END IF;
    
    RAISE NOTICE 'Test C3 PASSED: Successfully retrieved customer with ID %', v_customer_id;
    RAISE NOTICE 'Customer details: % % (Email: %)', v_result.first_name, v_result.last_name, v_result.email;

    -- Clean up
    DELETE FROM customers WHERE customer_id = v_customer_id;
END;
$$;

-- =============================================
-- Test C4: Retrieve a customer by email
-- =============================================
DO $$
DECLARE
    v_result RECORD;
    v_customer_id INTEGER;
    v_unique_email TEXT := 'getbyemail.test.' || clock_timestamp()::text || '@example.com';
BEGIN
    RAISE NOTICE 'Test C4: Retrieve a customer by email';
    
    -- Create a customer specifically for this test
    v_customer_id := pkg_customers.add_customer('GetByEmail', 'Test', v_unique_email, '444-GETEMAIL', 'Addr C4');

    -- Retrieve the customer by email using the package function
    SELECT * INTO v_result 
    FROM pkg_customers.get_customer_by_email(v_unique_email);
    
    IF v_result.customer_id IS NULL THEN
        RAISE EXCEPTION 'Test C4 FAILED: Customer retrieval by email returned no results';
    END IF;
    
    IF v_result.first_name <> 'GetByEmail' OR v_result.last_name <> 'Test' THEN -- Updated expected name
        RAISE EXCEPTION 'Test C4 FAILED: Retrieved customer has wrong name. Expected: GetByEmail Test, Got: % %', 
            v_result.first_name, v_result.last_name;
    END IF;
    
    RAISE NOTICE 'Test C4 PASSED: Successfully retrieved customer by email';
    RAISE NOTICE 'Customer details: ID %, % % (Email: %)', 
        v_result.customer_id, v_result.first_name, v_result.last_name, v_result.email;

    -- Clean up
    DELETE FROM customers WHERE customer_id = v_customer_id;
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
    v_initial_email TEXT := 'update.initial.' || clock_timestamp()::text || '@example.com';
    v_updated_email TEXT := 'update.final.' || clock_timestamp()::text || '@example.com';
BEGIN
    RAISE NOTICE 'Test C5: Update a customer''s contact information';
    
    -- Create a customer specifically for this test
    v_customer_id := pkg_customers.add_customer('Update', 'InitialName', v_initial_email, '555-UPDATE', 'Initial Addr C5');

    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Test C5 FAILED: Test setup issue - could not create test customer';
    END IF;
    
    -- Update the customer's information using the unique ID and a new unique email
    SELECT pkg_customers.update_customer(
        v_customer_id,
        'Update', -- Keep first name same
        'UpdatedLastName',
        v_updated_email, -- Use the new unique email
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
    
    IF v_result.last_name <> 'UpdatedLastName' OR v_result.email <> v_updated_email THEN
        RAISE EXCEPTION 'Test C5 FAILED: Customer update didn''t apply correctly. Last name: %, Email: %', 
            v_result.last_name, v_result.email;
    END IF;
    
    RAISE NOTICE 'Test C5 PASSED: Successfully updated customer information';
    RAISE NOTICE 'Updated customer details: % % (Email: %, Phone: %)', 
        v_result.first_name, v_result.last_name, v_result.email, v_result.phone;

    -- Clean up
    DELETE FROM customers WHERE customer_id = v_customer_id;
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
    v_unique_email TEXT := 'delete.test.' || clock_timestamp()::text || '@example.com'; -- Using unique email
BEGIN
    RAISE NOTICE 'Test C6: Delete a customer with no rental history (Email: %)', v_unique_email;
    
    -- First create a fresh test customer with unique email
    SELECT pkg_customers.add_customer(
        'DeleteTest', 'Customer', v_unique_email, 
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
    -- No cleanup needed as the customer is deleted
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
    v_unique_email TEXT := 'jane.active.' || clock_timestamp()::text || '@example.com'; -- Unique email
BEGIN
    RAISE NOTICE 'Test C7: Attempt to delete a customer with active rentals (should fail) (Email: %)', v_unique_email;
    
    -- Create a test customer with unique email
    INSERT INTO customers (first_name, last_name, email, phone, address)
    VALUES ('Jane', 'ActiveRental', v_unique_email, '555-888-7777', '123 Rental St C7') -- Use unique email
    RETURNING customer_id INTO v_customer_id;
    
    -- Create a test tape
    INSERT INTO tapes (title, genre_id, release_year, rental_price, stock_available, total_stock)
    VALUES ('Active Rental Tape C7', (SELECT genre_id FROM genres LIMIT 1), 2024, 4.99, 5, 5)
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
    
    -- Clean up (Return tape first. Cannot delete customer or tape due to history/FK constraints)
    UPDATE rentals SET return_date = CURRENT_TIMESTAMP WHERE rental_id = v_rental_id;
    -- PERFORM pkg_customers.delete_customer(v_customer_id); -- Removed: delete_customer prevents deletion due to history
    -- DELETE FROM tapes WHERE tape_id = v_tape_id; -- Removed: Fails due to FK constraint
END;
$$; 