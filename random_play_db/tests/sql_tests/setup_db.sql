-- Setup script to initialize database for tests
-- This script creates the necessary schema, tables, and functions for the Random Play Video Tape Store tests

-- Create schemas if they don't exist
CREATE SCHEMA IF NOT EXISTS pkg_customers;
CREATE SCHEMA IF NOT EXISTS pkg_rentals;
CREATE SCHEMA IF NOT EXISTS pkg_tapes;
CREATE SCHEMA IF NOT EXISTS pkg_reports;

-- Create basic tables if they don't exist
CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS genres (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS tapes (
    tape_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    genre_id INTEGER,
    release_year INTEGER CHECK (release_year > 1900),
    stock_available INTEGER NOT NULL DEFAULT 0 CHECK (stock_available >= 0),
    total_stock INTEGER NOT NULL DEFAULT 0 CHECK (total_stock >= stock_available),
    rental_price NUMERIC(5,2) NOT NULL CHECK (rental_price >= 0),
    rental_duration_days INTEGER NOT NULL DEFAULT 7 CHECK (rental_duration_days > 0)
);

CREATE TABLE IF NOT EXISTS rentals (
    rental_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    tape_id INTEGER NOT NULL REFERENCES tapes(tape_id),
    rental_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP NOT NULL,
    return_date TIMESTAMP,
    late_fees NUMERIC(5,2) DEFAULT 0 CHECK (late_fees >= 0)
);

-- Create rental_audit_log table for trigger tests
CREATE TABLE IF NOT EXISTS rental_audit_log (
    log_id SERIAL PRIMARY KEY,
    action_type VARCHAR(20) NOT NULL, -- 'RENT', 'RETURN', 'UPDATE', 'DELETE'
    rental_id INTEGER,
    customer_id INTEGER,
    tape_id INTEGER,
    movie_title TEXT,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    username TEXT DEFAULT CURRENT_USER,
    details TEXT -- Additional information about the action
);

-- Customer Package Functions

-- Create add_customer function
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
    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM customers WHERE email = p_email) THEN
        RAISE EXCEPTION 'A customer with this email already exists';
    END IF;
    
    -- Insert the new customer
    INSERT INTO customers (
        first_name, last_name, email, phone, address, registration_date, active
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, CURRENT_TIMESTAMP, TRUE
    ) RETURNING customer_id INTO v_customer_id;
    
    RETURN v_customer_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding customer: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Create get_customer function
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

-- Create get_customer_by_email function
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

-- Create update_customer function
CREATE OR REPLACE FUNCTION pkg_customers.update_customer(
    p_customer_id INTEGER,
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_address TEXT,
    p_active BOOLEAN
) RETURNS BOOLEAN AS $$
BEGIN
    -- Check if customer exists
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
    END IF;
    
    -- Check if email already exists for a different customer
    IF EXISTS (SELECT 1 FROM customers WHERE email = p_email AND customer_id <> p_customer_id) THEN
        RAISE EXCEPTION 'A customer with this email already exists';
    END IF;
    
    -- Update the customer
    UPDATE customers SET
        first_name = p_first_name,
        last_name = p_last_name,
        email = p_email,
        phone = p_phone,
        address = p_address,
        active = p_active
    WHERE customer_id = p_customer_id;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating customer: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Create delete_customer function
CREATE OR REPLACE FUNCTION pkg_customers.delete_customer(
    p_customer_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_has_active_rentals BOOLEAN;
BEGIN
    -- Check if customer has active rentals
    SELECT EXISTS(
        SELECT 1 FROM rentals 
        WHERE customer_id = p_customer_id AND return_date IS NULL
    ) INTO v_has_active_rentals;
    
    IF v_has_active_rentals THEN
        RAISE EXCEPTION 'Cannot delete customer with active rentals';
    END IF;
    
    -- Delete the customer
    DELETE FROM customers WHERE customer_id = p_customer_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer with ID % not found', p_customer_id;
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting customer: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Rental Package Functions

-- Create rent_tape function
CREATE OR REPLACE FUNCTION pkg_rentals.rent_tape(
    p_customer_id INTEGER,
    p_tape_id INTEGER,
    p_rental_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) RETURNS INTEGER AS $$
DECLARE
    v_rental_id INTEGER;
    v_due_date TIMESTAMP;
    v_stock_available INTEGER;
    v_rental_duration INTEGER;
BEGIN
    -- Check if tape exists and is available
    SELECT stock_available, rental_duration_days 
    INTO v_stock_available, v_rental_duration
    FROM tapes 
    WHERE tape_id = p_tape_id;
    
    IF v_stock_available IS NULL THEN
        RAISE EXCEPTION 'Tape with ID % does not exist', p_tape_id;
    END IF;
    
    IF v_stock_available <= 0 THEN
        RAISE EXCEPTION 'Tape with ID % is not available for rental (current stock: 0)', p_tape_id;
    END IF;
    
    -- Calculate due date
    v_due_date := p_rental_date + (v_rental_duration || ' days')::interval;
    
    -- Create rental record
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
    
    -- Update tape stock
    UPDATE tapes
    SET stock_available = stock_available - 1
    WHERE tape_id = p_tape_id;
    
    RETURN v_rental_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error renting tape: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Create return_tape function
CREATE OR REPLACE FUNCTION pkg_rentals.return_tape(
    p_rental_id INTEGER,
    p_return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) RETURNS TIMESTAMP AS $$
DECLARE
    v_tape_id INTEGER;
    v_due_date TIMESTAMP;
    v_late_fees NUMERIC(5,2);
BEGIN
    -- Get rental information
    SELECT tape_id, due_date INTO v_tape_id, v_due_date
    FROM rentals 
    WHERE rental_id = p_rental_id;
    
    IF v_tape_id IS NULL THEN
        RAISE EXCEPTION 'Rental with ID % does not exist', p_rental_id;
    END IF;
    
    -- Calculate late fees if applicable
    IF p_return_date > v_due_date THEN
        v_late_fees := pkg_rentals.calculate_late_fees(p_rental_id, p_return_date);
    ELSE
        v_late_fees := 0;
    END IF;
    
    -- Update rental record
    UPDATE rentals
    SET return_date = p_return_date,
        late_fees = v_late_fees
    WHERE rental_id = p_rental_id;
    
    -- Update tape stock
    UPDATE tapes
    SET stock_available = stock_available + 1
    WHERE tape_id = v_tape_id;
    
    RETURN p_return_date;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error returning tape: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Create calculate_late_fees function
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
    -- Get due date and rental price
    SELECT r.due_date, t.rental_price
    INTO v_due_date, v_daily_rate
    FROM rentals r
    JOIN tapes t ON r.tape_id = t.tape_id
    WHERE r.rental_id = p_rental_id;
    
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

-- Create extend_rental function
CREATE OR REPLACE FUNCTION pkg_rentals.extend_rental(
    p_rental_id INTEGER,
    p_additional_days INTEGER
) RETURNS TIMESTAMP AS $$
DECLARE
    v_new_due_date TIMESTAMP;
BEGIN
    -- Check if rental exists and is not already returned
    IF NOT EXISTS (
        SELECT 1 FROM rentals 
        WHERE rental_id = p_rental_id AND return_date IS NULL
    ) THEN
        RAISE EXCEPTION 'Rental with ID % does not exist or is already returned', p_rental_id;
    END IF;
    
    -- Update due date
    UPDATE rentals
    SET due_date = due_date + (p_additional_days || ' days')::interval
    WHERE rental_id = p_rental_id
    RETURNING due_date INTO v_new_due_date;
    
    RETURN v_new_due_date;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error extending rental: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Create trigger functions

-- Create stock decrease trigger
CREATE OR REPLACE FUNCTION update_tape_stock_after_rental() RETURNS TRIGGER AS $$
BEGIN
    -- Only process when a new rental is created
    IF TG_OP = 'INSERT' AND NEW.return_date IS NULL THEN
        UPDATE tapes
        SET stock_available = stock_available - 1
        WHERE tape_id = NEW.tape_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create stock increase trigger
CREATE OR REPLACE FUNCTION update_tape_stock_after_return() RETURNS TRIGGER AS $$
BEGIN
    -- Only process when a rental is updated with a return date
    IF TG_OP = 'UPDATE' AND OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE tapes
        SET stock_available = stock_available + 1
        WHERE tape_id = NEW.tape_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create rental audit trigger
CREATE OR REPLACE FUNCTION log_rental_activity() RETURNS TRIGGER AS $$
DECLARE
    v_action VARCHAR(20);
    v_details TEXT;
    v_movie_title TEXT;
BEGIN
    -- Get movie title
    SELECT title INTO v_movie_title
    FROM tapes
    WHERE tape_id = COALESCE(NEW.tape_id, OLD.tape_id);
    
    -- Determine action type
    IF TG_OP = 'INSERT' THEN
        v_action := 'RENT';
        v_details := 'New rental created. Due date: ' || NEW.due_date;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
            v_action := 'RETURN';
            v_details := 'Tape returned on ' || NEW.return_date || 
                        CASE WHEN NEW.late_fees > 0 
                             THEN '. Late fees: $' || NEW.late_fees 
                             ELSE '. No late fees.' 
                        END;
        ELSE
            v_action := 'UPDATE';
            v_details := 'Rental updated.';
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        v_action := 'DELETE';
        v_details := 'Rental record deleted.';
    END IF;
    
    -- Insert audit log record
    INSERT INTO rental_audit_log (
        action_type,
        rental_id,
        customer_id,
        tape_id,
        movie_title,
        details
    ) VALUES (
        v_action,
        COALESCE(NEW.rental_id, OLD.rental_id),
        COALESCE(NEW.customer_id, OLD.customer_id),
        COALESCE(NEW.tape_id, OLD.tape_id),
        v_movie_title,
        v_details
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create prevent customer deletion trigger
CREATE OR REPLACE FUNCTION prevent_customer_deletion() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM rentals
        WHERE customer_id = OLD.customer_id AND return_date IS NULL
    ) THEN
        RAISE EXCEPTION 'Cannot delete customer with active rentals';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create check tape availability trigger
CREATE OR REPLACE FUNCTION check_tape_availability() RETURNS TRIGGER AS $$
DECLARE
    v_stock_available INTEGER;
BEGIN
    SELECT stock_available INTO v_stock_available
    FROM tapes
    WHERE tape_id = NEW.tape_id;
    
    IF v_stock_available <= 0 THEN
        RAISE EXCEPTION 'Tape is not available for rental (current stock: 0)';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers

-- Trigger for updating tape stock on rental
CREATE TRIGGER trg_decrease_tape_stock_after_rental
AFTER INSERT ON rentals
FOR EACH ROW
EXECUTE FUNCTION update_tape_stock_after_rental();

-- Trigger for updating tape stock on return
CREATE TRIGGER trg_increase_tape_stock_after_return
AFTER UPDATE ON rentals
FOR EACH ROW
EXECUTE FUNCTION update_tape_stock_after_return();

-- Trigger for logging rental activities
CREATE TRIGGER trg_log_rental_activity
AFTER INSERT OR UPDATE OR DELETE ON rentals
FOR EACH ROW
EXECUTE FUNCTION log_rental_activity();

-- Trigger for preventing customer deletion with active rentals
CREATE TRIGGER trg_prevent_customer_deletion
BEFORE DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION prevent_customer_deletion();

-- Trigger for checking tape availability
CREATE TRIGGER trg_check_tape_availability
BEFORE INSERT ON rentals
FOR EACH ROW
EXECUTE FUNCTION check_tape_availability(); 