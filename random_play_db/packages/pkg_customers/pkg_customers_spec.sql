-- Customer Package Specification for Random Play Video Tape Store
-- Since PostgreSQL doesn't have native packages like Oracle, we use schemas (similar enough ya madame)

-- The following functions will be created in the pkg_customers schema:

-- add_customer(p_first_name, p_last_name, p_email, p_phone, p_address)
--   Adds a new customer to the database
--   Returns: customer_id of the newly added customer

-- update_customer(p_customer_id, p_first_name, p_last_name, p_email, p_phone, p_address, p_active)
--   Updates an existing customer's information
--   Returns: boolean indicating success or failure

-- get_customer(p_customer_id)
--   Retrieves a customer by ID
--   Returns: customer record

-- get_customer_by_email(p_email)
--   Retrieves a customer by email address
--   Returns: customer record

-- find_customers_by_name(p_name_pattern)
--   Searches for customers by name pattern
--   Returns: set of matching customer records

-- search_customers(p_name_pattern, p_email_pattern, p_address_pattern, p_is_active, p_registered_after, p_registered_before)
--   Advanced search for customers using multiple criteria
--   All parameters are optional, allowing for flexible search combinations
--   Returns: set of matching customer records

-- find_customers_with_active_rentals()
--   Finds all customers who currently have active rentals
--   Returns: set of customers with active rental count

-- find_customers_with_overdue_rentals()
--   Finds all customers who currently have overdue rentals
--   Returns: set of customers with overdue rental information

-- find_top_spending_customers(p_limit, p_start_date, p_end_date)
--   Finds customers who have spent the most within a date range
--   Returns: set of customers with spending information

-- get_customer_rental_history(p_customer_id)
--   Gets rental history for a customer
--   Returns: set of rental records

-- delete_customer(p_customer_id)
--   Deletes a customer if they have no active rentals
--   Returns: boolean indicating success or failure

-- activate_customer(p_customer_id)
--   Sets a customer's status to active
--   Returns: boolean indicating success or failure

-- deactivate_customer(p_customer_id)
--   Sets a customer's status to inactive
--   Returns: boolean indicating success or failure

-- get_active_customers()
--   Gets all active customers
--   Returns: set of active customer records 