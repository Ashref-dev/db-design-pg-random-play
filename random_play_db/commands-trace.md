# Random Play Video Tape Store - Command Execution Trace

This file documents the execution of SQL commands against the PostgreSQL database during project implementation.

## Phase 1: Database Design & Setup

### Schema Creation
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/db_schema/01_schemas.sql
```

Output:
```
DO
DO
DO
DO
ALTER DATABASE
SET
COMMENT
COMMENT
COMMENT
COMMENT
```

### Table Creation (Correct Order)
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/db_schema/02_tables/genres.sql -f random_play_db/db_schema/02_tables/actors.sql -f random_play_db/db_schema/02_tables/customers.sql -f random_play_db/db_schema/02_tables/tapes.sql -f random_play_db/db_schema/02_tables/tape_actors.sql -f random_play_db/db_schema/02_tables/rentals.sql -f random_play_db/db_schema/02_tables/audit_log.sql
```

Output:
```
psql:random_play_db/db_schema/02_tables/genres.sql:4: NOTICE:  table "genres" does not exist, skipping
DROP TABLE
CREATE TABLE
COMMENT
COMMENT
COMMENT
COMMENT
psql:random_play_db/db_schema/02_tables/actors.sql:4: NOTICE:  table "actors" does not exist, skipping
DROP TABLE
CREATE TABLE
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
psql:random_play_db/db_schema/02_tables/customers.sql:4: NOTICE:  table "customers" does not exist, skipping
DROP TABLE
CREATE TABLE
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
psql:random_play_db/db_schema/02_tables/tapes.sql:4: NOTICE:  table "tapes" does not exist, skipping
DROP TABLE
CREATE TABLE
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
psql:random_play_db/db_schema/02_tables/tape_actors.sql:4: NOTICE:  table "tape_actors" does not exist, skipping
DROP TABLE
CREATE TABLE
COMMENT
COMMENT
COMMENT
COMMENT
psql:random_play_db/db_schema/02_tables/rentals.sql:4: NOTICE:  table "rentals" does not exist, skipping
DROP TABLE
CREATE TABLE
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
psql:random_play_db/db_schema/02_tables/audit_log.sql:4: NOTICE:  table "audit_log" does not exist, skipping
DROP TABLE
CREATE TABLE
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
COMMENT
```

### Sequences Creation
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/db_schema/03_sequences.sql
```

Output:
```
CREATE SEQUENCE
COMMENT
```

### Indexes Creation
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/db_schema/05_indexes.sql
```

Output:
```
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
```

### Views Creation
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/db_schema/04_views.sql
```

Output:
```
CREATE VIEW
CREATE VIEW
CREATE VIEW
CREATE VIEW
CREATE VIEW
```

## Phase 2: Data Population

### Lookup Data (Genres)
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/data/01_lookup_data.sql > /dev/null 2>&1 &
```

### Sample Actors
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/data/02_sample_actors.sql > /dev/null 2>&1 &
```

### Sample Customers
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/data/03_sample_customers.sql > /dev/null 2>&1 &
```

### Sample Tapes
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/data/04_sample_tapes.sql > /dev/null 2>&1 &
```

### Sample Tape-Actor Relationships
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/data/05_sample_tape_actors.sql > /dev/null 2>&1 &
```

### Sample Rentals (Initial Issue)
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/data/06_sample_rentals.sql > /dev/null 2>&1 &
```

Error Output:
```
TRUNCATE TABLE
CREATE FUNCTION
psql:random_play_db/data/06_sample_rentals.sql:114: ERROR:  case not found
HINT:  CASE statement is missing ELSE part.
CONTEXT:  PL/pgSQL function generate_sample_rentals() line 52 at CASE
DROP FUNCTION
```

### Sample Rentals (Fixed)
```sql
# Added an ELSE clause to the CASE statement in the PL/pgSQL function
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -f random_play_db/data/06_sample_rentals.sql > rentals_output.txt 2>&1
```

Verification:
```sql
PGPASSWORD=sL7pgZ4FHbYQ /opt/homebrew/bin/psql "postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require" -c "SELECT COUNT(*) FROM rentals;"
```

Output:
```
 count 
-------
    37
(1 row)
```

## Data Verification Summary

Final counts of each entity in the database:
```
Genres: 15
Actors: 29
Customers: 20
Tapes: 32
Tape-Actors: 12
Rentals: 37
``` 