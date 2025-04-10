-- Indexes definition for Random Play Video Tape Store

-- Indexes for tapes table
CREATE INDEX IF NOT EXISTS idx_tapes_genre_id ON tapes(genre_id);
CREATE INDEX IF NOT EXISTS idx_tapes_title ON tapes(title);

-- Indexes for rentals table
CREATE INDEX IF NOT EXISTS idx_rentals_customer_id ON rentals(customer_id);
CREATE INDEX IF NOT EXISTS idx_rentals_tape_id ON rentals(tape_id);
CREATE INDEX IF NOT EXISTS idx_rentals_return_date ON rentals(return_date);
CREATE INDEX IF NOT EXISTS idx_rentals_rental_date ON rentals(rental_date);
CREATE INDEX IF NOT EXISTS idx_rentals_due_date ON rentals(due_date);

-- Indexes for customers table
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);

-- Indexes for tape_actors table
CREATE INDEX IF NOT EXISTS idx_tape_actors_actor_id ON tape_actors(actor_id);

-- Indexes for actors table
CREATE INDEX IF NOT EXISTS idx_actors_name ON actors(last_name, first_name);

-- Indexes for audit_log table
CREATE INDEX IF NOT EXISTS idx_audit_log_table_name ON audit_log(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_operation ON audit_log(operation);
CREATE INDEX IF NOT EXISTS idx_audit_log_date ON audit_log(log_date); 