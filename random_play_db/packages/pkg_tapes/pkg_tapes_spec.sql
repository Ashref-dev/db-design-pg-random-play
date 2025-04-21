-- Tapes Package Specification for Random Play Video Tape Store
-- Since PostgreSQL doesn't have native packages like Oracle, we use schemas

-- The following functions will be created in the pkg_tapes schema:

-- add_tape(p_title, p_genre_id, p_release_year, p_total_stock, p_rental_price, p_rental_duration_days)
--   Adds a new tape to the inventory
--   Returns: tape_id of the newly added tape

-- update_tape(p_tape_id, p_title, p_genre_id, p_release_year, p_total_stock, p_stock_available, p_rental_price, p_rental_duration_days)
--   Updates an existing tape's information
--   Returns: boolean indicating success or failure

-- get_tape(p_tape_id)
--   Retrieves a tape by ID
--   Returns: tape record

-- find_tapes_by_title(p_title_pattern)
--   Searches for tapes by title pattern
--   Returns: set of matching tape records

-- search_tapes(p_title_pattern, p_genre_id, p_release_year_from, p_release_year_to, p_available_only, p_price_from, p_price_to)
--   Advanced search for tapes with multiple criteria
--   All parameters are optional, allowing for flexible search combinations
--   Returns: set of matching tape records with genre information

-- find_tapes_by_actor(p_actor_name)
--   Searches for tapes by actor name
--   Returns: set of matching tape records with actor information

-- find_most_popular_tapes(p_limit)
--   Finds tapes that have been rented most frequently
--   Returns: set of tape records with rental counts

-- find_never_rented_tapes()
--   Finds tapes that have never been rented
--   Returns: set of tape records that have no rental history

-- find_tapes_by_genre(p_genre_id)
--   Searches for tapes by genre
--   Returns: set of matching tape records

-- find_available_tapes()
--   Finds all tapes with stock_available > 0
--   Returns: set of available tape records

-- find_available_tapes_by_genre(p_genre_id)
--   Finds all available tapes in a specific genre
--   Returns: set of available tape records in the genre

-- delete_tape(p_tape_id)
--   Deletes a tape if it has no active rentals
--   Returns: boolean indicating success or failure

-- update_stock(p_tape_id, p_additional_stock)
--   Updates the total_stock and stock_available for a tape
--   Returns: boolean indicating success or failure

-- add_actor_to_tape(p_tape_id, p_actor_id, p_role)
--   Associates an actor with a tape, including their role
--   Returns: boolean indicating success or failure

-- get_tape_actors(p_tape_id)
--   Gets all actors associated with a tape
--   Returns: set of actor records with roles 