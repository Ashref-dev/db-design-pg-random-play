# Relational Schema for Random Play Video Tape Store

This document describes the relational schema for the Random Play video tape store database.

## Tables, Columns, and Constraints

### customers
```
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    registration_date DATE DEFAULT CURRENT_DATE,
    active BOOLEAN DEFAULT TRUE
);
```

### genres
```
CREATE TABLE genres (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);
```

### actors
```
CREATE TABLE actors (
    actor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE
);
```

### tapes
```
CREATE TABLE tapes (
    tape_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    genre_id INTEGER NOT NULL REFERENCES genres(genre_id),
    release_year INTEGER CHECK (release_year > 1900 AND release_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    stock_available INTEGER NOT NULL CHECK (stock_available >= 0),
    total_stock INTEGER NOT NULL CHECK (total_stock >= stock_available),
    rental_price NUMERIC(5,2) NOT NULL CHECK (rental_price >= 0),
    rental_duration_days INTEGER NOT NULL DEFAULT 7 CHECK (rental_duration_days > 0),
    CONSTRAINT fk_genre FOREIGN KEY (genre_id) REFERENCES genres(genre_id) ON UPDATE CASCADE
);
```

### tape_actors
```
CREATE TABLE tape_actors (
    tape_id INTEGER NOT NULL,
    actor_id INTEGER NOT NULL,
    role VARCHAR(100),
    PRIMARY KEY (tape_id, actor_id),
    CONSTRAINT fk_tape FOREIGN KEY (tape_id) REFERENCES tapes(tape_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_actor FOREIGN KEY (actor_id) REFERENCES actors(actor_id) ON UPDATE CASCADE ON DELETE CASCADE
);
```

### rentals
```
CREATE TABLE rentals (
    rental_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    tape_id INTEGER NOT NULL,
    rental_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP NOT NULL,
    return_date TIMESTAMP,
    late_fees NUMERIC(5,2) DEFAULT 0.00,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON UPDATE CASCADE,
    CONSTRAINT fk_tape FOREIGN KEY (tape_id) REFERENCES tapes(tape_id) ON UPDATE CASCADE,
    CONSTRAINT check_dates CHECK (return_date IS NULL OR return_date >= rental_date)
);
```

### audit_log
```
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    log_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id INTEGER NOT NULL,
    details TEXT
);
```

## Indexes

```
-- Indexes for foreign keys and commonly searched fields
CREATE INDEX idx_tapes_genre_id ON tapes(genre_id);
CREATE INDEX idx_rentals_customer_id ON rentals(customer_id);
CREATE INDEX idx_rentals_tape_id ON rentals(tape_id);
CREATE INDEX idx_rentals_return_date ON rentals(return_date);
CREATE INDEX idx_tape_actors_actor_id ON tape_actors(actor_id);
CREATE INDEX idx_tapes_title ON tapes(title);
CREATE INDEX idx_customers_name ON customers(last_name, first_name);
CREATE INDEX idx_actors_name ON actors(last_name, first_name);
```

## Data Types

- **SERIAL**: Auto-incrementing integer for primary keys
- **VARCHAR**: Variable-length character strings with specified maximum lengths
- **TEXT**: Unlimited-length text strings
- **INTEGER**: Whole numbers
- **NUMERIC**: Exact numeric values with specified precision and scale
- **DATE**: Calendar dates (year, month, day)
- **TIMESTAMP**: Date and time values
- **BOOLEAN**: True/false values

## Constraints

- **PRIMARY KEY**: Ensures each row is uniquely identifiable
- **FOREIGN KEY**: Maintains referential integrity between tables
- **UNIQUE**: Prevents duplicate values in columns
- **NOT NULL**: Ensures columns cannot contain NULL values
- **CHECK**: Validates data against specific conditions
- **DEFAULT**: Provides default values for columns when not specified in INSERT statements

## Relationships

- **customers to rentals**: One-to-many (One customer can have many rentals)
- **tapes to rentals**: One-to-many (One tape can appear in many rentals)
- **genres to tapes**: One-to-many (One genre can categorize many tapes)
- **tapes to tape_actors**: One-to-many (One tape can have many actors)
- **actors to tape_actors**: One-to-many (One actor can appear in many tapes) 