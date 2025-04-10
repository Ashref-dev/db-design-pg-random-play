-- Create a table for rental audit logging
CREATE TABLE IF NOT EXISTS rental_audit_log (
    log_id SERIAL PRIMARY KEY,
    action_type VARCHAR(20) NOT NULL, -- 'RENT', 'RETURN', 'CANCEL', etc.
    rental_id INTEGER,
    customer_id INTEGER,
    tape_id INTEGER,
    movie_title TEXT,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    username TEXT DEFAULT CURRENT_USER,
    details TEXT -- Additional information about the action
);

-- Add comments to the table and its columns
COMMENT ON TABLE rental_audit_log IS 'Audit table for tracking all rental-related activities';
COMMENT ON COLUMN rental_audit_log.log_id IS 'Unique identifier for each audit log entry';
COMMENT ON COLUMN rental_audit_log.action_type IS 'Type of rental action (RENT, RETURN, CANCEL, etc.)';
COMMENT ON COLUMN rental_audit_log.rental_id IS 'Reference to the rental involved in this action';
COMMENT ON COLUMN rental_audit_log.customer_id IS 'Customer who performed or is associated with this action';
COMMENT ON COLUMN rental_audit_log.tape_id IS 'Tape involved in the rental action';
COMMENT ON COLUMN rental_audit_log.movie_title IS 'Title of the movie (denormalized for audit readability)';
COMMENT ON COLUMN rental_audit_log.action_timestamp IS 'When the action occurred';
COMMENT ON COLUMN rental_audit_log.username IS 'Database user who performed the action';
COMMENT ON COLUMN rental_audit_log.details IS 'Additional details about the action'; 