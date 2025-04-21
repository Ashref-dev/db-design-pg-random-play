-- Customers table definition for Random Play Video Tape Store

-- Drop table if it exists (for clean setup)
DROP TABLE IF EXISTS customers CASCADE;

-- Create customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    registration_date DATE DEFAULT CURRENT_DATE,
    active BOOLEAN DEFAULT TRUE
);

-- Add table comments
COMMENT ON TABLE customers IS 'Stores information about customers who rent tapes';
COMMENT ON COLUMN customers.customer_id IS 'Unique identifier for customers';
COMMENT ON COLUMN customers.first_name IS 'Customer first name';
COMMENT ON COLUMN customers.last_name IS 'Customer last name';
COMMENT ON COLUMN customers.email IS 'Customer email address (unique)';
COMMENT ON COLUMN customers.phone IS 'Customer phone number';
COMMENT ON COLUMN customers.address IS 'Customer physical address';
COMMENT ON COLUMN customers.registration_date IS 'Date when customer registered';
COMMENT ON COLUMN customers.active IS 'Whether customer account is active'; 