-- Sample Actors for Random Play Video Tape Store

-- Clear any existing data
TRUNCATE actors CASCADE;

-- Insert actors
INSERT INTO actors (first_name, last_name, birth_date) VALUES
('Tom', 'Hanks', '1956-07-09'),
('Julia', 'Roberts', '1967-10-28'),
('Leonardo', 'DiCaprio', '1974-11-11'),
('Meryl', 'Streep', '1949-06-22'),
('Denzel', 'Washington', '1954-12-28'),
('Nicole', 'Kidman', '1967-06-20'),
('Brad', 'Pitt', '1963-12-18'),
('Jennifer', 'Lawrence', '1990-08-15'),
('Robert', 'De Niro', '1943-08-17'),
('Sandra', 'Bullock', '1964-07-26'),
('Will', 'Smith', '1968-09-25'),
('Kate', 'Winslet', '1975-10-05'),
('Johnny', 'Depp', '1963-06-09'),
('Viola', 'Davis', '1965-08-11'),
('Keanu', 'Reeves', '1964-09-02'),
('Cate', 'Blanchett', '1969-05-14'),
('Morgan', 'Freeman', '1937-06-01'),
('Emma', 'Stone', '1988-11-06'),
('Idris', 'Elba', '1972-09-06'),
('Scarlett', 'Johansson', '1984-11-22'),
('Samuel L.', 'Jackson', '1948-12-21'),
('Charlize', 'Theron', '1975-08-07'),
('Ryan', 'Gosling', '1980-11-12'),
('Octavia', 'Spencer', '1970-05-25'),
('Matthew', 'McConaughey', '1969-11-04');

-- Display inserted data
SELECT * FROM actors ORDER BY last_name, first_name; 