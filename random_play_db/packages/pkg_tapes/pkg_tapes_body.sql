-- Tapes Package Implementation for Random Play Video Tape Store
-- Contains function implementations for tape and inventory management operations

-- Function to add a new tape
CREATE OR REPLACE FUNCTION pkg_tapes.add_tape(
    p_title VARCHAR,
    p_genre_id INTEGER,
    p_release_year INTEGER,
    p_total_stock INTEGER,
    p_rental_price NUMERIC,
    p_rental_duration_days INTEGER DEFAULT 7
) RETURNS INTEGER AS $$
DECLARE
    v_tape_id INTEGER;
BEGIN
    -- Validate inputs
    IF p_title IS NULL OR p_genre_id IS NULL OR p_release_year IS NULL OR p_total_stock IS NULL OR p_rental_price IS NULL THEN
        RAISE EXCEPTION 'Title, genre ID, release year, total stock, and rental price are required';
    END IF;
    
    IF p_total_stock < 0 THEN
        RAISE EXCEPTION 'Total stock cannot be negative';
    END IF;
    
    IF p_rental_price < 0 THEN
        RAISE EXCEPTION 'Rental price cannot be negative';
    END IF;
    
    IF p_rental_duration_days <= 0 THEN
        RAISE EXCEPTION 'Rental duration must be greater than zero';
    END IF;
    
    -- Check if genre exists
    IF NOT EXISTS(SELECT 1 FROM genres WHERE genre_id = p_genre_id) THEN
        RAISE EXCEPTION 'Genre with ID % does not exist', p_genre_id;
    END IF;
    
    -- Insert the new tape
    INSERT INTO tapes (
        title,
        genre_id,
        release_year,
        stock_available,
        total_stock,
        rental_price,
        rental_duration_days
    ) VALUES (
        p_title,
        p_genre_id,
        p_release_year,
        p_total_stock,  -- Initially, stock_available equals total_stock
        p_total_stock,
        p_rental_price,
        p_rental_duration_days
    ) RETURNING tape_id INTO v_tape_id;
    
    RETURN v_tape_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding tape: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to update an existing tape
CREATE OR REPLACE FUNCTION pkg_tapes.update_tape(
    p_tape_id INTEGER,
    p_title VARCHAR,
    p_genre_id INTEGER,
    p_release_year INTEGER,
    p_total_stock INTEGER,
    p_stock_available INTEGER,
    p_rental_price NUMERIC,
    p_rental_duration_days INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
    v_original_stock_available INTEGER;
    v_original_total_stock INTEGER;
BEGIN
    -- Check if tape exists
    SELECT EXISTS(SELECT 1 FROM tapes WHERE tape_id = p_tape_id) INTO v_exists;
    
    IF NOT v_exists THEN
        RAISE EXCEPTION 'Tape with ID % does not exist', p_tape_id;
    END IF;
    
    -- Get current stock values
    SELECT stock_available, total_stock 
    INTO v_original_stock_available, v_original_total_stock
    FROM tapes 
    WHERE tape_id = p_tape_id;
    
    -- Validate stock values
    IF p_stock_available IS NOT NULL AND p_total_stock IS NOT NULL AND p_stock_available > p_total_stock THEN
        RAISE EXCEPTION 'Available stock cannot exceed total stock';
    END IF;
    
    IF p_stock_available IS NOT NULL AND p_total_stock IS NULL AND 
       p_stock_available > v_original_total_stock THEN
        RAISE EXCEPTION 'Available stock cannot exceed total stock';
    END IF;
    
    IF p_stock_available IS NULL AND p_total_stock IS NOT NULL AND 
       v_original_stock_available > p_total_stock THEN
        RAISE EXCEPTION 'Available stock cannot exceed total stock';
    END IF;
    
    -- Check if genre exists if provided
    IF p_genre_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM genres WHERE genre_id = p_genre_id) THEN
        RAISE EXCEPTION 'Genre with ID % does not exist', p_genre_id;
    END IF;
    
    -- Update the tape
    UPDATE tapes
    SET title = COALESCE(p_title, title),
        genre_id = COALESCE(p_genre_id, genre_id),
        release_year = COALESCE(p_release_year, release_year),
        stock_available = COALESCE(p_stock_available, stock_available),
        total_stock = COALESCE(p_total_stock, total_stock),
        rental_price = COALESCE(p_rental_price, rental_price),
        rental_duration_days = COALESCE(p_rental_duration_days, rental_duration_days)
    WHERE tape_id = p_tape_id;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating tape: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to get a tape by ID
CREATE OR REPLACE FUNCTION pkg_tapes.get_tape(
    p_tape_id INTEGER
) RETURNS SETOF tapes AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM tapes WHERE tape_id = p_tape_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tape with ID % not found', p_tape_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to find tapes by title pattern
CREATE OR REPLACE FUNCTION pkg_tapes.find_tapes_by_title(
    p_title_pattern VARCHAR
) RETURNS SETOF tapes AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM tapes 
    WHERE title ILIKE '%' || p_title_pattern || '%'
    ORDER BY title;
END;
$$ LANGUAGE plpgsql;

-- Advanced multi-criteria search function for tapes
CREATE OR REPLACE FUNCTION pkg_tapes.search_tapes(
    p_title_pattern VARCHAR DEFAULT NULL,
    p_genre_id INTEGER DEFAULT NULL,
    p_release_year_from INTEGER DEFAULT NULL,
    p_release_year_to INTEGER DEFAULT NULL,
    p_available_only BOOLEAN DEFAULT FALSE,
    p_price_from NUMERIC DEFAULT NULL,
    p_price_to NUMERIC DEFAULT NULL
) RETURNS TABLE (
    tape_id INTEGER,
    title VARCHAR,
    genre_name VARCHAR,
    release_year INTEGER,
    stock_available INTEGER,
    total_stock INTEGER,
    rental_price NUMERIC,
    rental_duration_days INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tape_id,
        t.title,
        g.name AS genre_name,
        t.release_year,
        t.stock_available,
        t.total_stock,
        t.rental_price,
        t.rental_duration_days
    FROM tapes t
    JOIN genres g ON t.genre_id = g.genre_id
    WHERE (p_title_pattern IS NULL OR 
           t.title ILIKE '%' || p_title_pattern || '%')
      AND (p_genre_id IS NULL OR 
           t.genre_id = p_genre_id)
      AND (p_release_year_from IS NULL OR 
           t.release_year >= p_release_year_from)
      AND (p_release_year_to IS NULL OR 
           t.release_year <= p_release_year_to)
      AND (NOT p_available_only OR 
           t.stock_available > 0)
      AND (p_price_from IS NULL OR 
           t.rental_price >= p_price_from)
      AND (p_price_to IS NULL OR 
           t.rental_price <= p_price_to)
    ORDER BY t.title;
END;
$$ LANGUAGE plpgsql;

-- Function to find tapes by actor name
CREATE OR REPLACE FUNCTION pkg_tapes.find_tapes_by_actor(
    p_actor_name VARCHAR
) RETURNS TABLE (
    tape_id INTEGER,
    title VARCHAR,
    genre_name VARCHAR,
    release_year INTEGER,
    stock_available INTEGER,
    actor_name TEXT,
    role VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tape_id,
        t.title,
        g.name AS genre_name,
        t.release_year,
        t.stock_available,
        a.first_name || ' ' || a.last_name AS actor_name,
        ta.role
    FROM tapes t
    JOIN genres g ON t.genre_id = g.genre_id
    JOIN tape_actors ta ON t.tape_id = ta.tape_id
    JOIN actors a ON ta.actor_id = a.actor_id
    WHERE a.first_name ILIKE '%' || p_actor_name || '%' OR 
          a.last_name ILIKE '%' || p_actor_name || '%'
    ORDER BY t.title, actor_name;
END;
$$ LANGUAGE plpgsql;

-- Function to find tapes by genre
CREATE OR REPLACE FUNCTION pkg_tapes.find_tapes_by_genre(
    p_genre_id INTEGER
) RETURNS SETOF tapes AS $$
BEGIN
    -- Check if genre exists
    IF NOT EXISTS(SELECT 1 FROM genres WHERE genre_id = p_genre_id) THEN
        RAISE EXCEPTION 'Genre with ID % does not exist', p_genre_id;
    END IF;
    
    RETURN QUERY
    SELECT * FROM tapes 
    WHERE genre_id = p_genre_id
    ORDER BY title;
END;
$$ LANGUAGE plpgsql;

-- Function to find available tapes
CREATE OR REPLACE FUNCTION pkg_tapes.find_available_tapes()
RETURNS SETOF tapes AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM tapes 
    WHERE stock_available > 0
    ORDER BY title;
END;
$$ LANGUAGE plpgsql;

-- Function to find available tapes by genre
CREATE OR REPLACE FUNCTION pkg_tapes.find_available_tapes_by_genre(
    p_genre_id INTEGER
) RETURNS SETOF tapes AS $$
BEGIN
    -- Check if genre exists
    IF NOT EXISTS(SELECT 1 FROM genres WHERE genre_id = p_genre_id) THEN
        RAISE EXCEPTION 'Genre with ID % does not exist', p_genre_id;
    END IF;
    
    RETURN QUERY
    SELECT * FROM tapes 
    WHERE genre_id = p_genre_id AND stock_available > 0
    ORDER BY title;
END;
$$ LANGUAGE plpgsql;

-- Function to delete a tape
CREATE OR REPLACE FUNCTION pkg_tapes.delete_tape(
    p_tape_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_active_rentals INTEGER;
BEGIN
    -- Check if tape has active rentals
    SELECT COUNT(*) INTO v_active_rentals 
    FROM rentals 
    WHERE tape_id = p_tape_id AND return_date IS NULL;
    
    IF v_active_rentals > 0 THEN
        RAISE EXCEPTION 'Cannot delete tape with ID % as it has % active rentals', 
            p_tape_id, v_active_rentals;
    END IF;
    
    -- Delete the tape
    DELETE FROM tapes WHERE tape_id = p_tape_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tape with ID % not found', p_tape_id;
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Cannot delete tape with ID % as it has rental history', p_tape_id;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error deleting tape: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to update stock
CREATE OR REPLACE FUNCTION pkg_tapes.update_stock(
    p_tape_id INTEGER,
    p_additional_stock INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- Check if tape exists
    SELECT EXISTS(SELECT 1 FROM tapes WHERE tape_id = p_tape_id) INTO v_exists;
    
    IF NOT v_exists THEN
        RAISE EXCEPTION 'Tape with ID % does not exist', p_tape_id;
    END IF;
    
    -- Update the stock
    UPDATE tapes
    SET total_stock = total_stock + p_additional_stock,
        stock_available = stock_available + p_additional_stock
    WHERE tape_id = p_tape_id;
    
    -- Check if stock_available is now negative
    IF EXISTS(SELECT 1 FROM tapes WHERE tape_id = p_tape_id AND stock_available < 0) THEN
        RAISE EXCEPTION 'Cannot reduce stock_available below zero';
    END IF;
    
    -- Check if stock_available now exceeds total_stock
    IF EXISTS(SELECT 1 FROM tapes WHERE tape_id = p_tape_id AND stock_available > total_stock) THEN
        -- Adjust stock_available to match total_stock if needed
        UPDATE tapes
        SET stock_available = total_stock
        WHERE tape_id = p_tape_id AND stock_available > total_stock;
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating stock: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to add an actor to a tape
CREATE OR REPLACE FUNCTION pkg_tapes.add_actor_to_tape(
    p_tape_id INTEGER,
    p_actor_id INTEGER,
    p_role VARCHAR
) RETURNS BOOLEAN AS $$
BEGIN
    -- Check if tape exists
    IF NOT EXISTS(SELECT 1 FROM tapes WHERE tape_id = p_tape_id) THEN
        RAISE EXCEPTION 'Tape with ID % does not exist', p_tape_id;
    END IF;
    
    -- Check if actor exists
    IF NOT EXISTS(SELECT 1 FROM actors WHERE actor_id = p_actor_id) THEN
        RAISE EXCEPTION 'Actor with ID % does not exist', p_actor_id;
    END IF;
    
    -- Insert the tape-actor relationship
    INSERT INTO tape_actors (tape_id, actor_id, role)
    VALUES (p_tape_id, p_actor_id, p_role)
    ON CONFLICT (tape_id, actor_id) DO UPDATE
    SET role = EXCLUDED.role;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error adding actor to tape: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Function to get actors for a tape
CREATE OR REPLACE FUNCTION pkg_tapes.get_tape_actors(
    p_tape_id INTEGER
) RETURNS TABLE (
    actor_id INTEGER,
    first_name VARCHAR,
    last_name VARCHAR,
    birth_date DATE,
    role VARCHAR
) AS $$
BEGIN
    -- Check if tape exists
    IF NOT EXISTS(SELECT 1 FROM tapes WHERE tape_id = p_tape_id) THEN
        RAISE EXCEPTION 'Tape with ID % does not exist', p_tape_id;
    END IF;
    
    RETURN QUERY
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        a.birth_date,
        ta.role
    FROM actors a
    JOIN tape_actors ta ON a.actor_id = ta.actor_id
    WHERE ta.tape_id = p_tape_id
    ORDER BY a.last_name, a.first_name;
END;
$$ LANGUAGE plpgsql;

-- Function to find most popular tapes
CREATE OR REPLACE FUNCTION pkg_tapes.find_most_popular_tapes(
    p_limit INTEGER DEFAULT 10
) RETURNS TABLE (
    tape_id INTEGER,
    title VARCHAR,
    genre_name VARCHAR,
    rental_count BIGINT,
    available BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tape_id,
        t.title,
        g.name AS genre_name,
        COUNT(r.rental_id) AS rental_count,
        t.stock_available > 0 AS available
    FROM tapes t
    JOIN genres g ON t.genre_id = g.genre_id
    LEFT JOIN rentals r ON t.tape_id = r.tape_id
    GROUP BY t.tape_id, t.title, g.name, t.stock_available
    ORDER BY rental_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function to find tapes that have never been rented
CREATE OR REPLACE FUNCTION pkg_tapes.find_never_rented_tapes()
RETURNS TABLE (
    tape_id INTEGER,
    title VARCHAR,
    genre_name VARCHAR,
    release_year INTEGER,
    stock_available INTEGER,
    rental_price NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tape_id,
        t.title,
        g.name AS genre_name,
        t.release_year,
        t.stock_available,
        t.rental_price
    FROM tapes t
    JOIN genres g ON t.genre_id = g.genre_id
    LEFT JOIN rentals r ON t.tape_id = r.tape_id
    WHERE r.rental_id IS NULL
    ORDER BY t.title;
END;
$$ LANGUAGE plpgsql; 