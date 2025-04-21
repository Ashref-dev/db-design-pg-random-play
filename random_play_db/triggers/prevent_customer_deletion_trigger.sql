-- Trigger to prevent deletion of customers with active rentals
-- This ensures data integrity by preventing orphaned rental records

-- First, create the trigger function
CREATE OR REPLACE FUNCTION trg_prevent_customer_deletion()
RETURNS TRIGGER AS $$
DECLARE
    active_rental_count INTEGER;
    rental_ids TEXT;
BEGIN
    -- Count active rentals (where return_date is null)
    SELECT COUNT(*) INTO active_rental_count
    FROM rentals
    WHERE customer_id = OLD.customer_id
    AND return_date IS NULL;
    
    -- If there are active rentals, prevent deletion
    IF active_rental_count > 0 THEN
        -- Get list of rental IDs for the error message
        SELECT string_agg(rental_id::TEXT, ', ') INTO rental_ids
        FROM rentals
        WHERE customer_id = OLD.customer_id
        AND return_date IS NULL;
        
        RAISE EXCEPTION 'Cannot delete customer ID % (% %) because they have % active rental(s). Rental IDs: %', 
            OLD.customer_id, 
            OLD.first_name, 
            OLD.last_name, 
            active_rental_count, 
            rental_ids;
    END IF;
    
    -- If no active rentals, allow the deletion
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the customers table
DROP TRIGGER IF EXISTS trg_prevent_customer_deletion ON customers;

CREATE TRIGGER trg_prevent_customer_deletion
BEFORE DELETE
ON customers
FOR EACH ROW
EXECUTE FUNCTION trg_prevent_customer_deletion();

-- Add a comment to the trigger
COMMENT ON TRIGGER trg_prevent_customer_deletion ON customers IS 
'This trigger prevents the deletion of customers who still have active rentals.
It ensures data integrity by checking if a customer has any unreturned tapes
before allowing their record to be deleted from the database.
If deletion is attempted while active rentals exist, it raises an exception
with details about the active rentals.'; 