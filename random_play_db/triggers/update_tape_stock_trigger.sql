-- Trigger to automatically update tape stock when a rental is created or returned
-- This ensures that the stock count in the tapes table is always accurate

CREATE OR REPLACE FUNCTION trg_update_tape_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle NEW rentals (INSERT)
    IF (TG_OP = 'INSERT') THEN
        -- Decrease the stock_available count for the rented tape
        UPDATE tapes
        SET stock_available = stock_available - 1
        WHERE tape_id = NEW.tape_id;
        
        RAISE NOTICE 'Tape stock updated: Decreased stock_available for tape ID % after rental.', NEW.tape_id;
        
    -- Handle returns (UPDATE: when return_date changes from NULL to a value)
    ELSIF (TG_OP = 'UPDATE' AND OLD.return_date IS NULL AND NEW.return_date IS NOT NULL) THEN
        -- Increase the stock_available count for the returned tape
        UPDATE tapes
        SET stock_available = stock_available + 1
        WHERE tape_id = NEW.tape_id;
        
        RAISE NOTICE 'Tape stock updated: Increased stock_available for tape ID % after return.', NEW.tape_id;
        
    -- Handle rental cancellations (DELETE on an unreturned rental)
    ELSIF (TG_OP = 'DELETE' AND OLD.return_date IS NULL) THEN
        -- Increase the stock_available count for the canceled rental
        UPDATE tapes
        SET stock_available = stock_available + 1
        WHERE tape_id = OLD.tape_id;
        
        RAISE NOTICE 'Tape stock updated: Increased stock_available for tape ID % after rental cancellation.', OLD.tape_id;
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
1. When a tape is rented (INSERT): decreases stock_available by 1
2. When a tape is returned (UPDATE with return_date): increases stock_available by 1
3. When a rental is canceled (DELETE of unreturned rental): increases stock_available by 1
This ensures inventory counts stay accurate without manual updates.'; 