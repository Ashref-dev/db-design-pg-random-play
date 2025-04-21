-- Rentals table definition for Random Play Video Tape Store

-- Drop table if it exists (for clean setup)
DROP TABLE IF EXISTS rentals CASCADE;

-- Create rentals table
CREATE TABLE rentals (
    rental_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    tape_id INTEGER NOT NULL,
    rental_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP NOT NULL,
    return_date TIMESTAMP,
    late_fees NUMERIC(5,2) DEFAULT 0.00,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON UPDATE CASCADE,
    CONSTRAINT fk_tape FOREIGN KEY (tape_id) REFERENCES tapes(tape_id) ON UPDATE CASCADE,
    CONSTRAINT check_dates CHECK (return_date IS NULL OR return_date >= rental_date)
);

-- Add table comments
COMMENT ON TABLE rentals IS 'Stores rental transactions between customers and tapes';
COMMENT ON COLUMN rentals.rental_id IS 'Unique identifier for rentals';
COMMENT ON COLUMN rentals.customer_id IS 'Foreign key to customers table';
COMMENT ON COLUMN rentals.tape_id IS 'Foreign key to tapes table';
COMMENT ON COLUMN rentals.rental_date IS 'Date and time when the tape was rented';
COMMENT ON COLUMN rentals.due_date IS 'Date and time when the tape is due to be returned';
COMMENT ON COLUMN rentals.return_date IS 'Date and time when the tape was actually returned (NULL if not yet returned)';
COMMENT ON COLUMN rentals.late_fees IS 'Additional fees charged for late returns'; 