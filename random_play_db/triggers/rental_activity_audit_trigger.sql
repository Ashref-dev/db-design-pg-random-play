-- Trigger to log rental activity in an audit log
-- This creates an audit trail of all rental-related actions for future reference
-- and compliance requirements

-- First, create the audit log table if it doesn't exist
CREATE TABLE IF NOT EXISTS rental_audit_log (
    log_id SERIAL PRIMARY KEY,
    action_type VARCHAR(50) NOT NULL, -- 'RENTAL', 'RETURN', 'UPDATE', etc.
    rental_id INTEGER,
    tape_id INTEGER,
    customer_id INTEGER,
    rental_date TIMESTAMP,
    return_date TIMESTAMP,
    rental_fee NUMERIC(10,2),
    late_fee NUMERIC(10,2),
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_by VARCHAR(100) DEFAULT current_user,
    details TEXT
);

-- Create the trigger function for rentals table
CREATE OR REPLACE FUNCTION trg_log_rental_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- Log action based on operation type
    IF TG_OP = 'INSERT' THEN
        -- New rental
        INSERT INTO rental_audit_log (
            action_type, rental_id, tape_id, customer_id,
            rental_date, return_date, rental_fee, late_fee, details
        ) VALUES (
            'RENTAL', NEW.rental_id, NEW.tape_id, NEW.customer_id,
            NEW.rental_date, NEW.return_date, NEW.rental_fee, NEW.late_fee,
            'New rental created'
        );
    ELSIF TG_OP = 'UPDATE' THEN
        -- Return or other update
        IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
            -- Tape return
            INSERT INTO rental_audit_log (
                action_type, rental_id, tape_id, customer_id,
                rental_date, return_date, rental_fee, late_fee, details
            ) VALUES (
                'RETURN', NEW.rental_id, NEW.tape_id, NEW.customer_id,
                NEW.rental_date, NEW.return_date, NEW.rental_fee, NEW.late_fee,
                'Tape returned' || CASE 
                    WHEN NEW.late_fee > 0 
                    THEN ' with late fee of $' || NEW.late_fee::TEXT
                    ELSE ''
                END
            );
        ELSE
            -- Other update
            INSERT INTO rental_audit_log (
                action_type, rental_id, tape_id, customer_id,
                rental_date, return_date, rental_fee, late_fee, details
            ) VALUES (
                'UPDATE', NEW.rental_id, NEW.tape_id, NEW.customer_id,
                NEW.rental_date, NEW.return_date, NEW.rental_fee, NEW.late_fee,
                'Rental record updated'
            );
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        -- Delete (should be rare)
        INSERT INTO rental_audit_log (
            action_type, rental_id, tape_id, customer_id,
            rental_date, return_date, rental_fee, late_fee, details
        ) VALUES (
            'DELETE', OLD.rental_id, OLD.tape_id, OLD.customer_id,
            OLD.rental_date, OLD.return_date, OLD.rental_fee, OLD.late_fee,
            'Rental record deleted'
        );
    END IF;
    
    -- For INSERT and UPDATE operations, return NEW
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_log_rental_activity ON rentals;

CREATE TRIGGER trg_log_rental_activity
AFTER INSERT OR UPDATE OR DELETE
ON rentals
FOR EACH ROW
EXECUTE FUNCTION trg_log_rental_activity();

-- Add a comment to the trigger
COMMENT ON TRIGGER trg_log_rental_activity ON rentals IS
'Trigger to log all rental activity (new rentals, returns, updates, deletions) in rental_audit_log table.';

-- Add comments to the audit log table
COMMENT ON TABLE rental_audit_log IS 'Audit log for tracking all rental-related activities';
COMMENT ON COLUMN rental_audit_log.action_type IS 'Type of action: RENTAL, RETURN, UPDATE, DELETE';
COMMENT ON COLUMN rental_audit_log.action_timestamp IS 'When the action was performed';
COMMENT ON COLUMN rental_audit_log.action_by IS 'Database user who performed the action';
COMMENT ON COLUMN rental_audit_log.details IS 'Additional details about the action'; 