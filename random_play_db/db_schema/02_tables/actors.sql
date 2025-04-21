-- Actors table definition for Random Play Video Tape Store

-- Drop table if it exists (for clean setup)
DROP TABLE IF EXISTS actors CASCADE;

-- Create actors table
CREATE TABLE actors (
    actor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE
);

-- Add table comments
COMMENT ON TABLE actors IS 'Stores information about actors appearing in video tapes';
COMMENT ON COLUMN actors.actor_id IS 'Unique identifier for actors';
COMMENT ON COLUMN actors.first_name IS 'Actor first name';
COMMENT ON COLUMN actors.last_name IS 'Actor last name';
COMMENT ON COLUMN actors.birth_date IS 'Actor birth date'; 