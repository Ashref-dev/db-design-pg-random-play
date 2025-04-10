-- Trigger to log rental activity to an audit log
-- This trigger records all INSERT, UPDATE, and DELETE operations on the rentals table

-- First, create the rental_audit_log table to store audit records

CREATE TABLE IF NOT EXISTS rental_audit_log (
    log_id SERIAL PRIMARY KEY,
    rental_id INTEGER,
    customer_id INTEGER,
    tape_id INTEGER,
    action_type VARCHAR(50) NOT NULL,
    action_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    action_details JSONB,
    performed_by VARCHAR(100) DEFAULT CURRENT_USER
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_rental_audit_log_rental_id ON rental_audit_log(rental_id);
CREATE INDEX IF NOT EXISTS idx_rental_audit_log_customer_id ON rental_audit_log(customer_id);
CREATE INDEX IF NOT EXISTS idx_rental_audit_log_action_timestamp ON rental_audit_log(action_timestamp);

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trg_rental_audit ON rentals;

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION trg_rental_audit()
RETURNS TRIGGER AS $$
DECLARE
    movie_title TEXT;
    audit_details TEXT;
BEGIN
    -- Get the movie title for better readability in the audit log
    SELECT m.title INTO movie_title
    FROM tapes t
    JOIN movies m ON t.movie_id = m.movie_id
    WHERE t.tape_id = COALESCE(NEW.tape_id, OLD.tape_id);
    
    -- Handle different operations
    IF TG_OP = 'INSERT' THEN
        -- New rental created
        audit_details := 'New rental created. Expected return date: ' || NEW.expected_return_date;
        
        INSERT INTO rental_audit_log (
            action_type, 
            rental_id, 
            customer_id, 
            tape_id, 
            movie_title, 
            details
        ) VALUES (
            'RENT', 
            NEW.rental_id, 
            NEW.customer_id, 
            NEW.tape_id, 
            movie_title, 
            audit_details
        );
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Check if this is a return operation (return_date was NULL and is now set)
        IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
            audit_details := 'Tape returned. Return date: ' || NEW.return_date;
            
            INSERT INTO rental_audit_log (
                action_type, 
                rental_id, 
                customer_id, 
                tape_id, 
                movie_title, 
                details
            ) VALUES (
                'RETURN', 
                NEW.rental_id, 
                NEW.customer_id, 
                NEW.tape_id, 
                movie_title, 
                audit_details
            );
        ELSE
            -- Other update operations
            audit_details := 'Rental record updated';
            
            INSERT INTO rental_audit_log (
                action_type, 
                rental_id, 
                customer_id, 
                tape_id, 
                movie_title, 
                details
            ) VALUES (
                'UPDATE', 
                NEW.rental_id, 
                NEW.customer_id, 
                NEW.tape_id, 
                movie_title, 
                audit_details
            );
        END IF;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Rental record deleted
        audit_details := 'Rental record deleted';
        
        INSERT INTO rental_audit_log (
            action_type, 
            rental_id, 
            customer_id, 
            tape_id, 
            movie_title, 
            details
        ) VALUES (
            'CANCEL', 
            OLD.rental_id, 
            OLD.customer_id, 
            OLD.tape_id, 
            movie_title, 
            audit_details
        );
    END IF;
    
    -- Log message for debugging
    RAISE NOTICE 'Rental audit log entry created: % for rental #%, tape #%, movie "%"',
        TG_OP, COALESCE(NEW.rental_id, OLD.rental_id), COALESCE(NEW.tape_id, OLD.tape_id), movie_title;
    
    -- Return appropriate value based on operation
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the rentals table
CREATE TRIGGER trg_rental_audit
AFTER INSERT OR UPDATE OR DELETE
ON rentals
FOR EACH ROW
EXECUTE FUNCTION trg_rental_audit();

-- Add a comment explaining the trigger
COMMENT ON TRIGGER trg_rental_audit ON rentals IS 'Trigger to log all rental-related activities (rent, return, cancel) to the rental_audit_log table'; 