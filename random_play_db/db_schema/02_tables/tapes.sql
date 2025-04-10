-- Tapes table definition for Random Play Video Tape Store

-- Drop table if it exists (for clean setup)
DROP TABLE IF EXISTS tapes CASCADE;

-- Create tapes table
CREATE TABLE tapes (
    tape_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    genre_id INTEGER NOT NULL,
    release_year INTEGER CHECK (release_year > 1900 AND release_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    stock_available INTEGER NOT NULL CHECK (stock_available >= 0),
    total_stock INTEGER NOT NULL CHECK (total_stock >= stock_available),
    rental_price NUMERIC(5,2) NOT NULL CHECK (rental_price >= 0),
    rental_duration_days INTEGER NOT NULL DEFAULT 7 CHECK (rental_duration_days > 0),
    CONSTRAINT fk_genre FOREIGN KEY (genre_id) REFERENCES genres(genre_id) ON UPDATE CASCADE
);

-- Add table comments
COMMENT ON TABLE tapes IS 'Stores information about video tapes available for rental';
COMMENT ON COLUMN tapes.tape_id IS 'Unique identifier for tapes';
COMMENT ON COLUMN tapes.title IS 'Title of the video tape';
COMMENT ON COLUMN tapes.genre_id IS 'Foreign key to genres table';
COMMENT ON COLUMN tapes.release_year IS 'Year when the film was released';
COMMENT ON COLUMN tapes.stock_available IS 'Number of tapes currently available for rental';
COMMENT ON COLUMN tapes.total_stock IS 'Total number of copies the store owns';
COMMENT ON COLUMN tapes.rental_price IS 'Price to rent the tape';
COMMENT ON COLUMN tapes.rental_duration_days IS 'Standard rental period in days'; 