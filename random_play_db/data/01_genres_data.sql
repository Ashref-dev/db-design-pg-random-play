-- Lookup Data for Random Play Video Tape Store
-- This file contains static/reference data that should be loaded first

-- Clear any existing data
TRUNCATE genres CASCADE;

-- Insert genres
INSERT INTO genres (name, description) VALUES 
('Action', 'Films with emphasis on exciting action sequences'),
('Adventure', 'Films with exciting stories, often with new experiences or exotic locales'),
('Comedy', 'Films intended to make audience laugh'),
('Drama', 'Films with serious, non-comedic plots and realistic characters'),
('Horror', 'Films that seek to elicit fear from the audience'),
('Sci-Fi', 'Films based on speculative scientific discoveries or developments'),
('Romance', 'Films focused on love stories and romantic relationships'),
('Thriller', 'Films designed to excite and maintain high levels of suspense'),
('Documentary', 'Films that document real events and people'),
('Animation', 'Films created using animation techniques'),
('Musical', 'Films where songs sung by the characters are interwoven into the narrative'),
('Western', 'Films set in the American Old West'),
('Fantasy', 'Films with fantastic elements, usually including magic'),
('Crime', 'Films focusing on criminal acts and law enforcement'),
('Family', 'Films suitable for families and children');

-- Display inserted data
SELECT * FROM genres ORDER BY genre_id; 