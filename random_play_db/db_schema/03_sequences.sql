-- Sequences definition for Random Play Video Tape Store
-- Note: Most sequences are automatically created by SERIAL columns
-- This file is for any additional sequences or sequence modifications

-- If we need to alter the start value of existing sequences
-- Uncomment and adjust as needed:

-- ALTER SEQUENCE customers_customer_id_seq RESTART WITH 1000;
-- ALTER SEQUENCE tapes_tape_id_seq RESTART WITH 1000;
-- ALTER SEQUENCE genres_genre_id_seq RESTART WITH 100;
-- ALTER SEQUENCE actors_actor_id_seq RESTART WITH 1000;
-- ALTER SEQUENCE rentals_rental_id_seq RESTART WITH 10000;
-- ALTER SEQUENCE audit_log_log_id_seq RESTART WITH 1;

-- Define a custom sequence for any additional needs (if required)
-- For example, a sequence for invoice numbers or special codes

CREATE SEQUENCE IF NOT EXISTS rental_code_seq
    START WITH 100001
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

COMMENT ON SEQUENCE rental_code_seq IS 'Used to generate unique rental reference codes'; 