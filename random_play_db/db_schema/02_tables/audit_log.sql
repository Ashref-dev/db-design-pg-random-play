-- Audit_Log table definition for Random Play Video Tape Store

-- Drop table if it exists (for clean setup)
DROP TABLE IF EXISTS audit_log CASCADE;

-- Create audit_log table
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    log_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id INTEGER NOT NULL,
    details TEXT
);

-- Add table comments
COMMENT ON TABLE audit_log IS 'Stores audit trail information about changes to data';
COMMENT ON COLUMN audit_log.log_id IS 'Unique identifier for log entries';
COMMENT ON COLUMN audit_log.log_date IS 'Date and time when the operation occurred';
COMMENT ON COLUMN audit_log.table_name IS 'Name of the table that was affected';
COMMENT ON COLUMN audit_log.operation IS 'Type of operation (INSERT, UPDATE, DELETE)';
COMMENT ON COLUMN audit_log.record_id IS 'Primary key of the record that was affected';
COMMENT ON COLUMN audit_log.details IS 'Additional details about the operation'; 