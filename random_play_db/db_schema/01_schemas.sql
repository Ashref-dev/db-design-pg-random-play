-- Schema creation for Random Play Video Tape Store

-- Check if pkg_customers schema exists and create if not
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'pkg_customers') THEN
        CREATE SCHEMA pkg_customers;
    END IF;
END
$$;

-- Check if pkg_tapes schema exists and create if not
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'pkg_tapes') THEN
        CREATE SCHEMA pkg_tapes;
    END IF;
END
$$;

-- Check if pkg_rentals schema exists and create if not
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'pkg_rentals') THEN
        CREATE SCHEMA pkg_rentals;
    END IF;
END
$$;

-- Check if pkg_reports schema exists and create if not
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'pkg_reports') THEN
        CREATE SCHEMA pkg_reports;
    END IF;
END
$$;

-- Set search path to include all schemas
ALTER DATABASE "random-play-db" SET search_path TO public, pkg_customers, pkg_tapes, pkg_rentals, pkg_reports;

-- Set current search path for this session
SET search_path TO public, pkg_customers, pkg_tapes, pkg_rentals, pkg_reports;

-- Comment
COMMENT ON SCHEMA pkg_customers IS 'Functions and procedures for customer management';
COMMENT ON SCHEMA pkg_tapes IS 'Functions and procedures for tape and inventory management';
COMMENT ON SCHEMA pkg_rentals IS 'Functions and procedures for rental operations';
COMMENT ON SCHEMA pkg_reports IS 'Functions and procedures for reporting and analytics'; 