-- Trigger to log rental activity to an audit log
-- This trigger records all INSERT, UPDATE, and DELETE operations on the rentals table

-- First, create the rental_audit_log table to store audit records
-- REMOVED: CREATE TABLE IF NOT EXISTS ... (Should be done in schema setup)

-- REMOVED: CREATE INDEX IF NOT EXISTS ... (Should be done in schema setup)

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trg_rental_audit ON rentals;

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION trg_rental_audit()
RETURNS TRIGGER AS $$
DECLARE
    v_operation VARCHAR(10);
    v_record_id INTEGER;
    v_details TEXT;
BEGIN
    -- Determine operation type and record ID
    IF TG_OP = 'INSERT' THEN
        v_operation := 'INSERT';
        v_record_id := NEW.rental_id;
        v_details := 'Rental created for customer ' || NEW.customer_id || ', tape ' || NEW.tape_id || '. Due: ' || NEW.due_date;
    ELSIF TG_OP = 'UPDATE' THEN
        v_operation := 'UPDATE';
        v_record_id := NEW.rental_id;
        IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
            v_details := 'Rental returned. Customer: ' || NEW.customer_id || ', Tape: ' || NEW.tape_id || '. Return Date: ' || NEW.return_date || '. Late Fees: ' || NEW.late_fees;
        ELSE
            -- Could add more detail here about what changed if needed
            v_details := 'Rental record updated for rental ID ' || NEW.rental_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        v_operation := 'DELETE';
        v_record_id := OLD.rental_id;
        v_details := 'Rental deleted/cancelled. Customer: ' || OLD.customer_id || ', Tape: ' || OLD.tape_id;
    END IF;

    -- Insert into the standard audit_log table
    INSERT INTO audit_log (
        table_name,
        operation,
        record_id,
        details
    ) VALUES (
        'rentals',  -- The table where the operation occurred
        v_operation,
        v_record_id,
        v_details
    );

    -- Log message for debugging
    RAISE NOTICE 'Audit log entry created for % on rentals, record ID: %', v_operation, v_record_id;

    -- Return appropriate value based on operation
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't prevent the original operation
        RAISE WARNING 'Error in rental audit trigger: %', SQLERRM;
        IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the rentals table
CREATE TRIGGER trg_rental_audit
AFTER INSERT OR UPDATE OR DELETE
ON rentals
FOR EACH ROW
EXECUTE FUNCTION trg_rental_audit();

-- Add a comment explaining the trigger
COMMENT ON TRIGGER trg_rental_audit ON rentals IS 'Trigger to log all rental-related activities (INSERT, UPDATE, DELETE) to the main audit_log table'; 