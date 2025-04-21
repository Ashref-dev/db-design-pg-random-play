-- Sample Tape-Actor Relationships for Random Play Video Tape Store

-- Clear any existing data
TRUNCATE tape_actors CASCADE;

-- Insert tape-actor relationships with roles
INSERT INTO tape_actors (tape_id, actor_id, role) VALUES
-- Die Hard
((SELECT tape_id FROM tapes WHERE title = 'Die Hard'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Bruce' AND last_name = 'Willis'), 
 'John McClane'),

-- The Matrix
((SELECT tape_id FROM tapes WHERE title = 'The Matrix'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Keanu' AND last_name = 'Reeves'), 
 'Neo'),

-- Titanic
((SELECT tape_id FROM tapes WHERE title = 'Titanic'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio'), 
 'Jack Dawson'),
((SELECT tape_id FROM tapes WHERE title = 'Titanic'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Kate' AND last_name = 'Winslet'), 
 'Rose DeWitt Bukater'),

-- Forrest Gump
((SELECT tape_id FROM tapes WHERE title = 'Forrest Gump'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Tom' AND last_name = 'Hanks'), 
 'Forrest Gump'),

-- The Silence of the Lambs
((SELECT tape_id FROM tapes WHERE title = 'The Silence of the Lambs'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Jodie' AND last_name = 'Foster'), 
 'Clarice Starling'),

-- Pretty Woman
((SELECT tape_id FROM tapes WHERE title = 'Pretty Woman'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Julia' AND last_name = 'Roberts'), 
 'Vivian Ward'),

-- The Godfather
((SELECT tape_id FROM tapes WHERE title = 'The Godfather'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Marlon' AND last_name = 'Brando'), 
 'Vito Corleone'),
((SELECT tape_id FROM tapes WHERE title = 'The Godfather'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Al' AND last_name = 'Pacino'), 
 'Michael Corleone'),

-- The Shawshank Redemption
((SELECT tape_id FROM tapes WHERE title = 'The Shawshank Redemption'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Morgan' AND last_name = 'Freeman'), 
 'Ellis Boyd "Red" Redding'),

-- Se7en
((SELECT tape_id FROM tapes WHERE title = 'Se7en'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Brad' AND last_name = 'Pitt'), 
 'Detective David Mills'),
((SELECT tape_id FROM tapes WHERE title = 'Se7en'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Morgan' AND last_name = 'Freeman'), 
 'Detective Lt. William Somerset');

-- Add some actors since we're missing a few in our previous list
INSERT INTO actors (first_name, last_name, birth_date) VALUES
('Bruce', 'Willis', '1955-03-19'),
('Jodie', 'Foster', '1962-11-19'),
('Marlon', 'Brando', '1924-04-03'),
('Al', 'Pacino', '1940-04-25');

-- Re-run the tape_actors insertions now that we have all the actors
TRUNCATE tape_actors CASCADE;

-- Insert tape-actor relationships with roles
INSERT INTO tape_actors (tape_id, actor_id, role) VALUES
-- Die Hard
((SELECT tape_id FROM tapes WHERE title = 'Die Hard'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Bruce' AND last_name = 'Willis'), 
 'John McClane'),

-- The Matrix
((SELECT tape_id FROM tapes WHERE title = 'The Matrix'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Keanu' AND last_name = 'Reeves'), 
 'Neo'),

-- Titanic
((SELECT tape_id FROM tapes WHERE title = 'Titanic'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Leonardo' AND last_name = 'DiCaprio'), 
 'Jack Dawson'),
((SELECT tape_id FROM tapes WHERE title = 'Titanic'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Kate' AND last_name = 'Winslet'), 
 'Rose DeWitt Bukater'),

-- Forrest Gump
((SELECT tape_id FROM tapes WHERE title = 'Forrest Gump'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Tom' AND last_name = 'Hanks'), 
 'Forrest Gump'),

-- The Silence of the Lambs
((SELECT tape_id FROM tapes WHERE title = 'The Silence of the Lambs'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Jodie' AND last_name = 'Foster'), 
 'Clarice Starling'),

-- Pretty Woman
((SELECT tape_id FROM tapes WHERE title = 'Pretty Woman'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Julia' AND last_name = 'Roberts'), 
 'Vivian Ward'),

-- The Godfather
((SELECT tape_id FROM tapes WHERE title = 'The Godfather'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Marlon' AND last_name = 'Brando'), 
 'Vito Corleone'),
((SELECT tape_id FROM tapes WHERE title = 'The Godfather'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Al' AND last_name = 'Pacino'), 
 'Michael Corleone'),

-- The Shawshank Redemption
((SELECT tape_id FROM tapes WHERE title = 'The Shawshank Redemption'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Morgan' AND last_name = 'Freeman'), 
 'Ellis Boyd "Red" Redding'),

-- Se7en
((SELECT tape_id FROM tapes WHERE title = 'Se7en'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Brad' AND last_name = 'Pitt'), 
 'Detective David Mills'),
((SELECT tape_id FROM tapes WHERE title = 'Se7en'), 
 (SELECT actor_id FROM actors WHERE first_name = 'Morgan' AND last_name = 'Freeman'), 
 'Detective Lt. William Somerset');

-- Display inserted relationships
SELECT t.title, a.first_name || ' ' || a.last_name AS actor_name, ta.role
FROM tape_actors ta
JOIN tapes t ON ta.tape_id = t.tape_id
JOIN actors a ON ta.actor_id = a.actor_id
ORDER BY t.title, a.last_name, a.first_name; 