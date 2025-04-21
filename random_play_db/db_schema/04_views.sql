-- Views definition for Random Play Video Tape Store

-- View for customer details with rental counts
CREATE OR REPLACE VIEW vw_customer_rental_stats AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.registration_date,
    c.active,
    COUNT(r.rental_id) AS total_rentals,
    COUNT(CASE WHEN r.return_date IS NULL THEN 1 END) AS active_rentals,
    SUM(CASE WHEN r.return_date IS NOT NULL THEN r.late_fees ELSE 0 END) AS total_late_fees
FROM 
    customers c
LEFT JOIN 
    rentals r ON c.customer_id = r.customer_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name, c.email, c.phone, c.registration_date, c.active;

-- View for tape details with genre and availability
CREATE OR REPLACE VIEW vw_tape_details AS
SELECT 
    t.tape_id,
    t.title,
    g.name AS genre_name,
    t.release_year,
    t.stock_available,
    t.total_stock,
    t.rental_price,
    t.rental_duration_days,
    (SELECT STRING_AGG(a.first_name || ' ' || a.last_name, ', ') 
     FROM tape_actors ta
     JOIN actors a ON ta.actor_id = a.actor_id
     WHERE ta.tape_id = t.tape_id) AS actors
FROM 
    tapes t
JOIN 
    genres g ON t.genre_id = g.genre_id;

-- View for current rentals with customer and tape details
CREATE OR REPLACE VIEW vw_current_rentals AS
SELECT 
    r.rental_id,
    r.rental_date,
    r.due_date,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email AS customer_email,
    t.tape_id,
    t.title AS tape_title,
    g.name AS genre_name,
    CASE 
        WHEN r.due_date < CURRENT_TIMESTAMP AND r.return_date IS NULL 
        THEN 'Overdue'
        WHEN r.return_date IS NULL 
        THEN 'Active'
        ELSE 'Returned'
    END AS rental_status,
    CASE 
        WHEN r.return_date IS NULL AND r.due_date < CURRENT_TIMESTAMP 
        THEN EXTRACT(DAY FROM (CURRENT_TIMESTAMP - r.due_date))
        ELSE 0
    END AS days_overdue
FROM 
    rentals r
JOIN 
    customers c ON r.customer_id = c.customer_id
JOIN 
    tapes t ON r.tape_id = t.tape_id
JOIN 
    genres g ON t.genre_id = g.genre_id
WHERE 
    r.return_date IS NULL;

-- View for rental history
CREATE OR REPLACE VIEW vw_rental_history AS
SELECT 
    r.rental_id,
    r.rental_date,
    r.due_date,
    r.return_date,
    r.late_fees,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    t.tape_id,
    t.title AS tape_title,
    g.name AS genre_name,
    CASE 
        WHEN r.return_date IS NULL AND r.due_date < CURRENT_TIMESTAMP 
        THEN 'Overdue'
        WHEN r.return_date IS NULL 
        THEN 'Active'
        ELSE 'Returned'
    END AS rental_status
FROM 
    rentals r
JOIN 
    customers c ON r.customer_id = c.customer_id
JOIN 
    tapes t ON r.tape_id = t.tape_id
JOIN 
    genres g ON t.genre_id = g.genre_id;

-- View for genre statistics
CREATE OR REPLACE VIEW vw_genre_stats AS
SELECT 
    g.genre_id,
    g.name AS genre_name,
    COUNT(t.tape_id) AS tape_count,
    AVG(t.rental_price) AS avg_rental_price,
    COUNT(r.rental_id) AS total_rentals
FROM 
    genres g
LEFT JOIN 
    tapes t ON g.genre_id = t.genre_id
LEFT JOIN 
    rentals r ON t.tape_id = r.tape_id
GROUP BY 
    g.genre_id, g.name; 