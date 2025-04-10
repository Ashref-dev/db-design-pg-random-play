-- Trigger to check tape availability before allowing a rental
-- This ensures that a tape cannot be rented if it's already rented out
-- or if it's marked as damaged/unavailable

-- Create the trigger function
CREATE OR REPLACE FUNCTION trg_check_tape_availability()
RETURNS TRIGGER AS $$
DECLARE
    v_is_available BOOLEAN;
    v_in_stock INTEGER;
    v_status VARCHAR(50);
    v_movie_title VARCHAR(255);
BEGIN
    -- Get the tape's current status and stock
    SELECT 
        t.status, 
        t.in_stock,
        m.title INTO v_status, v_in_stock, v_movie_title
    FROM 
        tapes t
        JOIN movies m ON t.movie_id = m.movie_id
    WHERE 
        t.tape_id = NEW.tape_id;
    
    -- Check if the tape is already rented (not available)
    SELECT 
        CASE WHEN COUNT(*) = 0 THEN TRUE ELSE FALSE END INTO v_is_available
    FROM 
        rentals r
    WHERE 
        r.tape_id = NEW.tape_id 
        AND r.return_date IS NULL;
    
    -- Validate availability
    IF v_in_stock <= 0 THEN
        RAISE EXCEPTION 'Cannot rent tape (ID: %) for movie "%": No copies in stock', 
            NEW.tape_id, v_movie_title;
    END IF;
    
    IF v_status = 'DAMAGED' THEN
        RAISE EXCEPTION 'Cannot rent tape (ID: %) for movie "%": Tape is marked as damaged', 
            NEW.tape_id, v_movie_title;
    END IF;
    
    IF v_status = 'LOST' THEN
        RAISE EXCEPTION 'Cannot rent tape (ID: %) for movie "%": Tape is marked as lost', 
            NEW.tape_id, v_movie_title;
    END IF;
    
    IF NOT v_is_available THEN
        RAISE EXCEPTION 'Cannot rent tape (ID: %) for movie "%": Tape is already rented out', 
            NEW.tape_id, v_movie_title;
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
'Trigger to check if a tape is available for rental before allowing it to be rented out.
Prevents renting tapes that are already rented, damaged, lost, or out of stock.'; 