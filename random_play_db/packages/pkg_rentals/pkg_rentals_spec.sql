-- Rentals Package Specification for Random Play Video Tape Store
-- Since PostgreSQL doesn't have native packages like Oracle, we use schemas

-- The following functions will be created in the pkg_rentals schema:

-- rent_tape(p_customer_id, p_tape_id, p_rental_date)
--   Rents a tape to a customer, creating a rental record
--   Checks that the tape is available and the customer is active
--   Returns: rental_id of the new rental

-- return_tape(p_rental_id, p_return_date)
--   Processes the return of a tape, updating the rental record
--   Updates stock_available
--   Calculates and records late fees if applicable
--   Returns: actual return date

-- calculate_late_fees(p_rental_id)
--   Calculates late fees for a rental based on due date and return date
--   Returns: late fee amount

-- get_rental(p_rental_id)
--   Retrieves rental information by ID
--   Returns: rental record

-- find_overdue_rentals()
--   Finds all rentals that are past their due date and not returned
--   Returns: set of overdue rental records

-- search_rentals(p_customer_id, p_tape_id, p_rental_date_from, p_rental_date_to, p_return_status, p_has_late_fees)
--   Advanced search for rentals with multiple criteria
--   All parameters are optional, allowing for flexible search combinations
--   Return status can be 'returned', 'active', 'overdue', or NULL for all
--   Returns: set of matching rental records with detailed information

-- find_rentals_by_date_range(p_start_date, p_end_date)
--   Finds all rentals created within a specific date range
--   Returns: set of rental records within the date range

-- find_high_value_rentals(p_min_amount, p_limit)
--   Finds rentals with high total value (rental price + late fees)
--   Returns: set of high value rental records with financial details

-- find_customer_active_rentals(p_customer_id)
--   Finds all active (not returned) rentals for a specific customer
--   Returns: set of active rental records

-- extend_rental(p_rental_id, p_additional_days)
--   Extends the due date of a rental
--   Checks that the rental is active
--   Returns: new due date

-- get_rental_history(p_from_date, p_to_date)
--   Gets rental history within a date range
--   Returns: set of rental records 

-- bulk_return_tapes(p_rental_ids, p_return_date)
--   Processes the return of multiple tapes in a single transaction
--   Uses return_tape internally for each rental
--   Returns: table with rental_id, tape_title, return_date, and late_fees for each successful return
--   Uses transaction management for atomicity

-- bulk_rent_tapes(p_customer_id, p_tape_ids, p_rental_date)
--   Rents multiple tapes to a customer in a single transaction
--   Uses rent_tape internally for each tape
--   Returns: table with rental_id, tape_title, and due_date for each successful rental
--   Uses transaction management for atomicity

-- check_customer_eligibility(p_customer_id)
--   Checks if a customer is eligible to rent more tapes
--   Evaluates customer status, active rentals, overdue rentals, and unpaid late fees
--   Returns: table with eligibility status, reason, current rentals, overdue rentals, and total due amount
--   Used for business rule enforcement before rental

-- reserve_tape(p_customer_id, p_tape_id, p_notes)
--   Creates a reservation for a tape that is currently out of stock
--   Checks customer and tape validity
--   Returns: table with reservation details including estimated availability
--   Demonstrates temporary table usage for feature extension 