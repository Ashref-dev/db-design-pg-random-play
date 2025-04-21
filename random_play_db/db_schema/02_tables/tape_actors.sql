-- Tape_Actors table definition for Random Play Video Tape Store

-- Drop table if it exists (for clean setup)
DROP TABLE IF EXISTS tape_actors CASCADE;

-- Create tape_actors junction table
CREATE TABLE tape_actors (
    tape_id INTEGER NOT NULL,
    actor_id INTEGER NOT NULL,
    role VARCHAR(100),
    PRIMARY KEY (tape_id, actor_id),
    CONSTRAINT fk_tape FOREIGN KEY (tape_id) REFERENCES tapes(tape_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_actor FOREIGN KEY (actor_id) REFERENCES actors(actor_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Add table comments
COMMENT ON TABLE tape_actors IS 'Junction table connecting tapes with their actors';
COMMENT ON COLUMN tape_actors.tape_id IS 'Foreign key to tapes table';
COMMENT ON COLUMN tape_actors.actor_id IS 'Foreign key to actors table';
COMMENT ON COLUMN tape_actors.role IS 'Character/role played by the actor in the tape'; 