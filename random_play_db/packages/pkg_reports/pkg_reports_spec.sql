-- Reports Package Specification for Random Play Video Tape Store
-- Since PostgreSQL doesn't have native packages like Oracle, we use schemas

-- The following functions will be created in the pkg_reports schema:

-- get_revenue_by_period(p_start_date, p_end_date)
--   Calculates total revenue (rentals + late fees) for a given time period
--   Returns: record with rental revenue, late fee revenue, and total revenue

-- get_popular_genres(p_limit)
--   Gets the most popular genres based on rental count
--   Returns: set of records with genre name and rental count

-- get_popular_tapes(p_limit)
--   Gets the most popular tapes based on rental count
--   Returns: set of records with tape title and rental count

-- get_customer_spending(p_customer_id, p_start_date, p_end_date)
--   Calculates total spending for a customer in a given time period
--   Returns: record with rental spending, late fee spending, and total spending

-- get_overdue_summary()
--   Gets a summary of currently overdue rentals
--   Returns: record with count of overdue rentals, total days overdue, and estimated late fees

-- get_inventory_status()
--   Gets a summary of current inventory status
--   Returns: set of records with genre name, total tapes, available tapes, and out on rental

-- get_monthly_revenue_report(p_year)
--   Gets a breakdown of revenue by month for a given year
--   Returns: set of records with month, rental revenue, late fee revenue, and total revenue

-- get_customer_activity(p_limit)
--   Gets the most active customers based on rental count
--   Returns: set of records with customer name, rental count, and total spending 