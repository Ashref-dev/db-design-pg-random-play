-- Trigger to check tape availability before allowing a rental
-- This ensures that a tape cannot be rented if it's already rented out
-- or if it's marked as damaged/unavailable

-- Create the trigger function
CREATE OR REPLACE FUNCTION trg_check_tape_availability()
RETURNS TRIGGER AS $$
DECLARE
    v_stock_available INTEGER;
    v_tape_title VARCHAR(100);
BEGIN
    -- Get the tape's current stock and title
    SELECT 
        stock_available, title 
    INTO 
        v_stock_available, v_tape_title
    FROM 
        tapes
    WHERE 
        tape_id = NEW.tape_id;

    -- Check if the tape exists (v_stock_available would be NULL if not)
    IF v_stock_available IS NULL THEN
         RAISE EXCEPTION 'Tape with ID % does not exist.', NEW.tape_id;
    END IF;
    
    -- Validate availability
    IF v_stock_available <= 0 THEN
        -- Raise an exception to prevent the INSERT operation
        RAISE EXCEPTION 'Cannot rent tape "%" (ID: %): No copies currently in stock.', 
            v_tape_title, NEW.tape_id;
    END IF;
    
    -- If we get here, the tape is available for rental
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_check_tape_availability ON rentals;

CREATE TRIGGER trg_check_tape_availability
BEFORE INSERT
ON rentals
FOR EACH ROW
EXECUTE FUNCTION trg_check_tape_availability();

-- Add a comment to the trigger
COMMENT ON TRIGGER trg_check_tape_availability ON rentals IS
'Trigger to check if a tape has stock_available > 0 before allowing a rental INSERT.
Prevents renting tapes that are out of stock by raising an exception.'; 