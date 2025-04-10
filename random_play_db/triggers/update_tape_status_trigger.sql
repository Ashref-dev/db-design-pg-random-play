-- Create or replace the trigger function for updating tape status
CREATE OR REPLACE FUNCTION trg_update_tape_status()
RETURNS TRIGGER AS $$
DECLARE
    tape_title TEXT;
BEGIN
    -- Handle rentals - set tape as unavailable when rented
    IF TG_OP = 'INSERT' THEN
        -- Get the tape title for logging
        SELECT m.title INTO tape_title
        FROM tapes t
        JOIN movies m ON t.movie_id = m.movie_id
        WHERE t.tape_id = NEW.tape_id;
        
        -- Update the tape status to 'Rented'
        UPDATE tapes
        SET status = 'Rented',
            last_update = CURRENT_TIMESTAMP
        WHERE tape_id = NEW.tape_id;
        
        RAISE NOTICE 'Tape ID % (%) marked as Rented due to new rental (Rental ID: %)', 
            NEW.tape_id, tape_title, NEW.rental_id;
            
        RETURN NEW;
        
    -- Handle returns - set tape as available when returned
    ELSIF TG_OP = 'UPDATE' THEN
        -- Only process when a return date is being set (null to date)
        IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
            -- Get the tape title for logging
            SELECT m.title INTO tape_title
            FROM tapes t
            JOIN movies m ON t.movie_id = m.movie_id
            WHERE t.tape_id = NEW.tape_id;
            
            -- Update the tape status to 'Available'
            UPDATE tapes
            SET status = 'Available',
                last_update = CURRENT_TIMESTAMP
            WHERE tape_id = NEW.tape_id;
            
            RAISE NOTICE 'Tape ID % (%) marked as Available due to return (Rental ID: %)', 
                NEW.tape_id, tape_title, NEW.rental_id;
        END IF;
        
        RETURN NEW;
        
    -- Handle rental cancellations (deletions) - set tape back to available
    ELSIF TG_OP = 'DELETE' THEN
        -- Only process active rentals (those without a return date)
        IF OLD.return_date IS NULL THEN
            -- Get the tape title for logging
            SELECT m.title INTO tape_title
            FROM tapes t
            JOIN movies m ON t.movie_id = m.movie_id
            WHERE t.tape_id = OLD.tape_id;
            
            -- Update the tape status to 'Available'
            UPDATE tapes
            SET status = 'Available',
                last_update = CURRENT_TIMESTAMP
            WHERE tape_id = OLD.tape_id;
            
            RAISE NOTICE 'Tape ID % (%) marked as Available due to rental cancellation (Rental ID: %)', 
                OLD.tape_id, tape_title, OLD.rental_id;
        END IF;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_update_tape_status ON rentals;

CREATE TRIGGER trg_update_tape_status
AFTER INSERT OR UPDATE OR DELETE ON rentals
FOR EACH ROW
EXECUTE FUNCTION trg_update_tape_status();

-- Add a comment to the trigger
COMMENT ON TRIGGER trg_update_tape_status ON rentals IS 
'This trigger automatically updates tape availability status when rental events occur:
1. When a tape is rented (INSERT), it sets the tape status to "Rented"
2. When a tape is returned (UPDATE with return_date), it sets the tape status to "Available"
3. When a rental is canceled (DELETE), it sets the tape status back to "Available"
This ensures tape inventory status is always synchronized with rental activity.'; 