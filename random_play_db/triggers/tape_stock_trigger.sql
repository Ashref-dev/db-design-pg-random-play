-- Trigger to update tape stock on rental and return
-- This trigger automatically decrements stock_available when a tape is rented 
-- and increments it when a tape is returned

-- First, create the trigger function
CREATE OR REPLACE FUNCTION trg_update_tape_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- For new rentals (INSERT)
    IF TG_OP = 'INSERT' THEN
        -- Decrement the stock_available for the rented tape
        UPDATE tapes 
        SET stock_available = stock_available - 1
        WHERE tape_id = NEW.tape_id;
        
        -- Verify stock didn't go negative (safety check)
        IF (SELECT stock_available FROM tapes WHERE tape_id = NEW.tape_id) < 0 THEN
            RAISE EXCEPTION 'Tape stock cannot be negative. Invalid rental operation.';
        END IF;
    
    -- For returns (UPDATE where return_date was previously NULL and now has a value)
    ELSIF TG_OP = 'UPDATE' AND OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        -- Increment the stock_available for the returned tape
        UPDATE tapes
        SET stock_available = stock_available + 1
        WHERE tape_id = NEW.tape_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the rentals table
DROP TRIGGER IF EXISTS trg_update_tape_stock ON rentals;

CREATE TRIGGER trg_update_tape_stock
AFTER INSERT OR UPDATE OF return_date
ON rentals
FOR EACH ROW
EXECUTE FUNCTION trg_update_tape_stock();

-- Add a comment to the trigger
COMMENT ON TRIGGER trg_update_tape_stock ON rentals IS 
'Trigger to automatically update tape stock (stock_available) when rentals are created or returned.'; 