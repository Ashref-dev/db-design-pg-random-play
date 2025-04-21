-- Sample Tapes for Random Play Video Tape Store

-- Clear any existing data
TRUNCATE tapes CASCADE;

-- Insert tapes with references to genres
INSERT INTO tapes (title, genre_id, release_year, stock_available, total_stock, rental_price, rental_duration_days) VALUES
-- Action movies
('Die Hard', (SELECT genre_id FROM genres WHERE name = 'Action'), 1988, 5, 8, 3.99, 5),
('The Matrix', (SELECT genre_id FROM genres WHERE name = 'Action'), 1999, 7, 10, 4.99, 5),
('Mad Max: Fury Road', (SELECT genre_id FROM genres WHERE name = 'Action'), 2015, 3, 5, 4.99, 5),
('John Wick', (SELECT genre_id FROM genres WHERE name = 'Action'), 2014, 4, 6, 4.99, 5),

-- Comedy movies
('Ghostbusters', (SELECT genre_id FROM genres WHERE name = 'Comedy'), 1984, 3, 5, 3.99, 5),
('The Hangover', (SELECT genre_id FROM genres WHERE name = 'Comedy'), 2009, 5, 7, 3.99, 5),
('Dumb and Dumber', (SELECT genre_id FROM genres WHERE name = 'Comedy'), 1994, 2, 3, 2.99, 5),
('Superbad', (SELECT genre_id FROM genres WHERE name = 'Comedy'), 2007, 4, 6, 3.99, 5),

-- Drama movies
('The Godfather', (SELECT genre_id FROM genres WHERE name = 'Drama'), 1972, 2, 4, 3.99, 7),
('The Shawshank Redemption', (SELECT genre_id FROM genres WHERE name = 'Drama'), 1994, 3, 5, 3.99, 7),
('Forrest Gump', (SELECT genre_id FROM genres WHERE name = 'Drama'), 1994, 6, 8, 3.99, 7),
('The Green Mile', (SELECT genre_id FROM genres WHERE name = 'Drama'), 1999, 2, 3, 3.99, 7),

-- Sci-Fi movies
('Star Wars: A New Hope', (SELECT genre_id FROM genres WHERE name = 'Sci-Fi'), 1977, 5, 8, 4.99, 5),
('E.T. the Extra-Terrestrial', (SELECT genre_id FROM genres WHERE name = 'Sci-Fi'), 1982, 2, 4, 3.99, 5),
('Blade Runner', (SELECT genre_id FROM genres WHERE name = 'Sci-Fi'), 1982, 3, 3, 3.99, 5),
('Alien', (SELECT genre_id FROM genres WHERE name = 'Sci-Fi'), 1979, 2, 3, 3.99, 5),

-- Horror movies
('The Exorcist', (SELECT genre_id FROM genres WHERE name = 'Horror'), 1973, 2, 4, 3.99, 3),
('The Shining', (SELECT genre_id FROM genres WHERE name = 'Horror'), 1980, 3, 5, 3.99, 3),
('A Nightmare on Elm Street', (SELECT genre_id FROM genres WHERE name = 'Horror'), 1984, 2, 3, 2.99, 3),
('The Ring', (SELECT genre_id FROM genres WHERE name = 'Horror'), 2002, 3, 5, 3.99, 3),

-- Romance movies
('Titanic', (SELECT genre_id FROM genres WHERE name = 'Romance'), 1997, 4, 6, 3.99, 5),
('The Notebook', (SELECT genre_id FROM genres WHERE name = 'Romance'), 2004, 5, 7, 3.99, 5),
('Pretty Woman', (SELECT genre_id FROM genres WHERE name = 'Romance'), 1990, 3, 4, 2.99, 5),
('When Harry Met Sally', (SELECT genre_id FROM genres WHERE name = 'Romance'), 1989, 2, 3, 2.99, 5),

-- Thriller movies
('The Silence of the Lambs', (SELECT genre_id FROM genres WHERE name = 'Thriller'), 1991, 3, 5, 3.99, 5),
('Se7en', (SELECT genre_id FROM genres WHERE name = 'Thriller'), 1995, 2, 4, 3.99, 5),
('Psycho', (SELECT genre_id FROM genres WHERE name = 'Thriller'), 1960, 1, 2, 2.99, 5),
('Gone Girl', (SELECT genre_id FROM genres WHERE name = 'Thriller'), 2014, 4, 5, 4.99, 5),

-- Family movies
('The Lion King', (SELECT genre_id FROM genres WHERE name = 'Family'), 1994, 7, 10, 3.99, 7),
('Toy Story', (SELECT genre_id FROM genres WHERE name = 'Family'), 1995, 5, 8, 3.99, 7),
('Home Alone', (SELECT genre_id FROM genres WHERE name = 'Family'), 1990, 4, 6, 2.99, 7),
('The Wizard of Oz', (SELECT genre_id FROM genres WHERE name = 'Family'), 1939, 2, 3, 2.99, 7);

-- Display inserted data
SELECT t.tape_id, t.title, g.name AS genre, t.release_year, t.stock_available, t.total_stock, t.rental_price
FROM tapes t
JOIN genres g ON t.genre_id = g.genre_id
ORDER BY g.name, t.title; 