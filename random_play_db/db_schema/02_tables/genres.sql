-- Genres table definition for Random Play Video Tape Store

-- Drop table if it exists (for clean setup)
DROP TABLE IF EXISTS genres CASCADE;

-- Create genres table
CREATE TABLE genres (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

-- Add table comments
COMMENT ON TABLE genres IS 'Stores different genres of video tapes';
COMMENT ON COLUMN genres.genre_id IS 'Unique identifier for genres';
COMMENT ON COLUMN genres.name IS 'Genre name (unique)';
COMMENT ON COLUMN genres.description IS 'Description of the genre'; 