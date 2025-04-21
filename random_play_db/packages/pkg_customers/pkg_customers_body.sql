-- Customer Package Implementation for Random Play Video Tape Store
-- Contains function implementations for customer management operations

-- Function to add a new customer
CREATE OR REPLACE FUNCTION pkg_customers.add_customer(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_address TEXT
) RETURNS INTEGER AS $$
DECLARE
    v_customer_id INTEGER;
BEGIN
    -- Validate inputs
    IF p_first_name IS NULL OR p_last_name IS NULL OR p_email IS NULL THEN
        RAISE EXCEPTION 'First name, last name, and email are required';
    END IF;
    
    -- Insert the new customer
    INSERT INTO customers (
        first_name,
        last_name,
        email,
        phone,
        address,
        registration_date,
        active
    ) VALUES (
        p_first_name,
        p_last_name,
        p_email,
        p_phone,
        p_address,
        CURRENT_DATE,
        TRUE
    ) RETURNING customer_id INTO v_customer_id;
    
    RETURN v_customer_id;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'A customer with email % already exists', p_email;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding customer: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to update an existing customer
CREATE OR REPLACE FUNCTION pkg_customers.update_customer(
    p_customer_id INTEGER,
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_address TEXT,
    p_active BOOLEAN
) RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- Check if customer exists
    SELECT EXISTS(SELECT 1 FROM customers WHERE customer_id = p_customer_id) INTO v_exists;
    
    IF NOT v_exists THEN
        RAISE EXCEPTION 'Customer with ID % does not exist', p_customer_id;
    END IF;
    
    -- Update the customer
    UPDATE customers
    SET first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        address = COALESCE(p_address, address),
        active = COALESCE(p_active, active)
    WHERE customer_id = p_customer_id;
    
    RETURN TRUE;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'A customer with email % already exists', p_email;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating customer: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to get a customer by ID
CREATE OR REPLACE FUNCTION pkg_customers.get_customer(
    p_customer_id INTEGER
) RETURNS SETOF customers AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM customers WHERE customer_id = p_customer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to get a customer by email
CREATE OR REPLACE FUNCTION pkg_customers.get_customer_by_email(
    p_email VARCHAR
) RETURNS SETOF customers AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM customers WHERE email = p_email;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer with email % not found', p_email;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to find customers by name pattern
CREATE OR REPLACE FUNCTION pkg_customers.find_customers_by_name(
    p_name_pattern VARCHAR
) RETURNS SETOF customers AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM customers 
    WHERE first_name ILIKE '%' || p_name_pattern || '%' 
       OR last_name ILIKE '%' || p_name_pattern || '%'
    ORDER BY last_name, first_name;
END;
$$ LANGUAGE plpgsql;

-- Advanced search function for customers with multiple criteria
CREATE OR REPLACE FUNCTION pkg_customers.search_customers(
    p_name_pattern VARCHAR DEFAULT NULL,
    p_email_pattern VARCHAR DEFAULT NULL,
    p_address_pattern VARCHAR DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL,
    p_registered_after DATE DEFAULT NULL,
    p_registered_before DATE DEFAULT NULL
) RETURNS SETOF customers AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM customers 
    WHERE (p_name_pattern IS NULL OR 
           first_name ILIKE '%' || p_name_pattern || '%' OR 
           last_name ILIKE '%' || p_name_pattern || '%')
      AND (p_email_pattern IS NULL OR 
           email ILIKE '%' || p_email_pattern || '%')
      AND (p_address_pattern IS NULL OR 
           address ILIKE '%' || p_address_pattern || '%')
      AND (p_is_active IS NULL OR 
           active = p_is_active)
      AND (p_registered_after IS NULL OR 
           registration_date >= p_registered_after)
      AND (p_registered_before IS NULL OR 
           registration_date <= p_registered_before)
    ORDER BY last_name, first_name;
END;
$$ LANGUAGE plpgsql;

-- Function to find customers with active rentals
CREATE OR REPLACE FUNCTION pkg_customers.find_customers_with_active_rentals()
RETURNS TABLE (
    customer_id INTEGER,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    active BOOLEAN,
    active_rentals BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.active,
        COUNT(r.rental_id) AS active_rentals
    FROM customers c
    JOIN rentals r ON c.customer_id = r.customer_id
    WHERE r.return_date IS NULL
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.active
    ORDER BY active_rentals DESC, c.last_name, c.first_name;
END;
$$ LANGUAGE plpgsql;

-- Function to find customers with overdue rentals
CREATE OR REPLACE FUNCTION pkg_customers.find_customers_with_overdue_rentals()
RETURNS TABLE (
    customer_id INTEGER,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    overdue_rentals BIGINT,
    most_overdue_days INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        COUNT(r.rental_id) AS overdue_rentals,
        MAX(EXTRACT(DAY FROM (CURRENT_TIMESTAMP - r.due_date)))::INTEGER AS most_overdue_days
    FROM customers c
    JOIN rentals r ON c.customer_id = r.customer_id
    WHERE r.return_date IS NULL AND r.due_date < CURRENT_TIMESTAMP
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
    ORDER BY most_overdue_days DESC, overdue_rentals DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to find top spending customers
CREATE OR REPLACE FUNCTION pkg_customers.find_top_spending_customers(
    p_limit INTEGER DEFAULT 10,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT current_date
) RETURNS TABLE (
    customer_id INTEGER,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    rental_count BIGINT,
    total_spent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(t.rental_price + r.late_fees), 0) AS total_spent
    FROM customers c
    LEFT JOIN rentals r ON c.customer_id = r.customer_id
    LEFT JOIN tapes t ON r.tape_id = t.tape_id
    WHERE (p_start_date IS NULL OR r.rental_date::DATE >= p_start_date)
      AND (r.rental_date::DATE <= p_end_date)
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
    ORDER BY total_spent DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to get customer rental history
CREATE OR REPLACE FUNCTION pkg_customers.get_customer_rental_history(
    p_customer_id INTEGER
) RETURNS TABLE (
    rental_id INTEGER,
    tape_title VARCHAR,
    rental_date TIMESTAMP,
    due_date TIMESTAMP,
    return_date TIMESTAMP,
    late_fees NUMERIC,
    status TEXT
) AS $$
BEGIN
    -- Check if customer exists
    IF NOT EXISTS(SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer with ID % does not exist', p_customer_id;
    END IF;
    
    RETURN QUERY
    SELECT 
        r.rental_id,
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
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.customer_id = p_customer_id
    ORDER BY r.rental_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to delete a customer
CREATE OR REPLACE FUNCTION pkg_customers.delete_customer(
    p_customer_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_active_rentals INTEGER;
BEGIN
    -- Check if customer has active rentals
    SELECT COUNT(*) INTO v_active_rentals 
    FROM rentals 
    WHERE customer_id = p_customer_id AND return_date IS NULL;
    
    IF v_active_rentals > 0 THEN
        RAISE EXCEPTION 'Cannot delete customer with ID % as they have % active rentals', 
            p_customer_id, v_active_rentals;
    END IF;
    
    -- Delete the customer
    DELETE FROM customers WHERE customer_id = p_customer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Cannot delete customer with ID % as they have rental history', p_customer_id;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting customer: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to activate a customer
CREATE OR REPLACE FUNCTION pkg_customers.activate_customer(
    p_customer_id INTEGER
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE customers SET active = TRUE WHERE customer_id = p_customer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to deactivate a customer
CREATE OR REPLACE FUNCTION pkg_customers.deactivate_customer(
    p_customer_id INTEGER
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE customers SET active = FALSE WHERE customer_id = p_customer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to get all active customers
CREATE OR REPLACE FUNCTION pkg_customers.get_active_customers()
RETURNS SETOF customers AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM customers WHERE active = TRUE ORDER BY last_name, first_name;
END;
$$ LANGUAGE plpgsql; 