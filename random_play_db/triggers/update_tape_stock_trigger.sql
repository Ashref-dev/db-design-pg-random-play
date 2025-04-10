-- Trigger to automatically update tape stock when a rental is created or returned
-- This ensures that the stock count in the tapes table is always accurate

CREATE OR REPLACE FUNCTION trg_update_tape_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle NEW rentals (INSERT)
    IF (TG_OP = 'INSERT') THEN
        -- Decrease the available_copies count for the rented tape
        UPDATE tapes
        SET available_copies = available_copies - 1
        WHERE tape_id = NEW.tape_id;
        
        RAISE NOTICE 'Tape stock updated: Decreased available copies for tape ID % after rental.', NEW.tape_id;
        
        -- Check if we need to update the status to unavailable (when stock hits zero)
        UPDATE tapes
        SET status = 'unavailable'
        WHERE tape_id = NEW.tape_id
        AND available_copies = 0;
        
    -- Handle returns (UPDATE: when return_date changes from NULL to a value)
    ELSIF (TG_OP = 'UPDATE' AND OLD.return_date IS NULL AND NEW.return_date IS NOT NULL) THEN
        -- Increase the available_copies count for the returned tape
        UPDATE tapes
        SET available_copies = available_copies + 1,
            -- Also ensure the status is 'available' if it was previously unavailable
            status = CASE 
                        WHEN status = 'unavailable' THEN 'available'
                        ELSE status
                     END
        WHERE tape_id = NEW.tape_id;
        
        RAISE NOTICE 'Tape stock updated: Increased available copies for tape ID % after return.', NEW.tape_id;
        
    -- Handle rental cancellations (DELETE on an unreturned rental)
    ELSIF (TG_OP = 'DELETE' AND OLD.return_date IS NULL) THEN
        -- Increase the available_copies count for the canceled rental
        UPDATE tapes
        SET available_copies = available_copies + 1,
            -- Also ensure the status is 'available' if it was previously unavailable
            status = CASE 
                        WHEN status = 'unavailable' THEN 'available'
                        ELSE status
                     END
        WHERE tape_id = OLD.tape_id;
        
        RAISE NOTICE 'Tape stock updated: Increased available copies for tape ID % after rental cancellation.', OLD.tape_id;
    END IF;
    
    -- Return the appropriate row based on the operation
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_update_tape_stock ON rentals;

CREATE TRIGGER trg_update_tape_stock
AFTER INSERT OR UPDATE OR DELETE
ON rentals
FOR EACH ROW
EXECUTE FUNCTION trg_update_tape_stock();

-- Add a comment to the trigger
COMMENT ON TRIGGER trg_update_tape_stock ON rentals IS 
'Trigger to automatically update tape stock quantities when rental events occur:
1. When a tape is rented (INSERT): decreases available_copies by 1
2. When a tape is returned (UPDATE with return_date): increases available_copies by 1
3. When a rental is canceled (DELETE of unreturned rental): increases available_copies by 1
4. Additionally updates tape status to "unavailable" when stock reaches 0
5. Updates tape status back to "available" when stock becomes positive after return
This ensures inventory counts stay accurate without manual updates.'; 