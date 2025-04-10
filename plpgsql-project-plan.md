# **Random Play \- Video Tape Store: PL/PGSQL Project Implementation Plan**

This plan outlines the steps, structure, and tasks required to develop the database and PL/PGSQL components for the "Random Play" video tape store project, following common PL/SQL project practices and the requirements from the provided project description\[cite: 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18\].

## **I. Project Structure (Folder Layout)**

A standard directory structure helps maintain organization and clarity:

random\_play\_db/  
├── db\_schema/                \# Database object definitions  
│   ├── 01\_schemas.sql        \# Schema creation (if needed beyond public)  
│   ├── 02\_tables/            \# Table definitions  
│   │   ├── customers.sql  
│   │   ├── tapes.sql  
│   │   ├── rentals.sql  
│   │   └── ... (other tables like genres, actors, tape\_actors)  
│   ├── 03\_sequences.sql      \# Sequence definitions (if any)  
│   ├── 04\_views.sql          \# View definitions (if any)  
│   └── 05\_indexes.sql        \# Index definitions  
├── functions/                \# Standalone functions (if not in packages)  
├── procedures/               \# Standalone procedures (if not in packages)  
├── packages/                 \# PL/PGSQL Packages  
│   ├── pkg\_customers\_spec.sql \# Package specification for customers  
│   ├── pkg\_customers\_body.sql \# Package body for customers  
│   ├── pkg\_tapes\_spec.sql     \# Package specification for tapes  
│   ├── pkg\_tapes\_body.sql     \# Package body for tapes  
│   ├── pkg\_rentals\_spec.sql   \# Package specification for rentals  
│   ├── pkg\_rentals\_body.sql   \# Package body for rentals  
│   └── ... (other packages as needed, e.g., pkg\_reports)  
├── triggers/                 \# Trigger functions and definitions  
│   ├── trg\_update\_tape\_stock.sql \# Trigger function & definition  
│   ├── trg\_log\_rental\_activity.sql  
│   ├── trg\_prevent\_customer\_deletion.sql  
│   └── ... (other triggers)  
├── data/                     \# Data insertion scripts (seed/sample data)  
│   ├── 01\_lookup\_data.sql    \# Initial lookup/static data (e.g., genres)  
│   ├── 02\_sample\_customers.sql  
│   ├── 03\_sample\_tapes.sql  
│   └── 04\_sample\_rentals.sql  
├── tests/                    \# Test scripts and scenarios  
│   ├── test\_crud\_customers.sql  
│   ├── test\_search\_tapes.sql  
│   ├── test\_rental\_logic.sql  
│   └── test\_scenarios.md     \# Description of test cases  
└── docs/                     \# Project documentation  
    ├── erd.md                \# Entity-Relationship Diagram (using Mermaid syntax)  
    ├── relational\_schema.md  \# Description of relational schema (can include Mermaid)  
    └── technical\_report.md   \# Final technical documentation aggregating all info

## **II. Implementation Phases and Tasks**

Here's a breakdown of the tasks required, aligned with the project document\[cite: 9, 10, 11, 12, 13, 14, 15, 16, 17, 18\].

### **Phase 1: Database Design & Setup**

* \[x\] **Task 1.1: Conceptual Data Modeling** 
  * \[x\] Define entities (e.g., Customers, Tapes, Rentals, Genres, Actors, Tape\_Actors).  
  * \[x\] Define attributes for each entity (e.g., Customer: customer\_id, first\_name, last\_name, email, phone, address; Tape: tape\_id, title, genre\_id, release\_year, stock\_available, total\_stock).  
  * \[x\] Define relationships between entities (e.g., one-to-many: Customer \<-\> Rentals; one-to-many: Genre \<-\> Tapes; many-to-many: Tapes \<-\> Actors via Tape\_Actors).  
  * \[x\] Create an Entity-Relationship Diagram (ERD) using **Mermaid syntax** within the erd.md file.  
  * \[x\] *Deliverable:* docs/erd.md containing the Mermaid ERD diagram and explanations.  
* \[x\] **Task 1.2: Relational Schema Design**  
  * \[x\] Convert the ERD into a relational schema.  
  * \[x\] Define tables corresponding to entities.  
  * \[x\] Define columns corresponding to attributes, specifying appropriate PostgreSQL data types (e.g., SERIAL or INT for IDs, VARCHAR, TEXT, DATE, TIMESTAMP, NUMERIC, BOOLEAN).  
  * \[x\] Define primary keys (PKs) for each table (e.g., customer\_id, tape\_id, rental\_id).  
  * \[x\] Define foreign keys (FKs) to enforce relationships with ON DELETE / ON UPDATE actions if applicable.  
  * \[x\] Define UNIQUE, NOT NULL, and CHECK constraints (e.g., CHECK (stock\_available \>= 0), UNIQUE (email) for customers).  
  * \[x\] *Deliverable:* docs/relational\_schema.md describing the tables, columns, types, and constraints. Can optionally include Mermaid diagrams for table structures.  
* \[x\] **Task 1.3: Database & Schema Creation Script**  
  * \[x\] Write SQL script to create the database (if not using default) and any specific schemas (e.g., CREATE SCHEMA random\_play;). Set the search\_path if needed.  
  * \[x\] *Deliverable:* db\_schema/01\_schemas.sql.  
* \[x\] **Task 1.4: Table Creation Scripts**  
  * \[x\] Write SQL scripts (CREATE TABLE) for each table based on the relational schema.  
  * \[x\] Include all constraints (PK, FK, UNIQUE, NOT NULL, CHECK).  
  * \[x\] Define sequences explicitly (CREATE SEQUENCE) if not using SERIAL/BIGSERIAL, or if specific sequence options are needed.  
  * \[x\] Define indexes (CREATE INDEX) for frequently queried columns, especially foreign keys or columns used in WHERE clauses.  
  * \[x\] Organize scripts logically (e.g., one file per table or grouped by dependency).  
  * \[x\] *Deliverable:* SQL files in db\_schema/02\_tables/, db\_schema/03\_sequences.sql, db\_schema/05\_indexes.sql.

### **Phase 2: Data Population**

* \[x\] **Task 2.1: Data Generation/Gathering**  
  * \[x\] Define realistic sample data for all tables (Genres, Actors, Customers, Tapes, Rentals, etc.).  
  * \[x\] Ensure data variety to allow for meaningful testing of searches, reports, and logic. Include cases like tapes with zero stock, customers with multiple rentals, etc.  
* \[x\] **Task 2.2: Data Insertion Scripts**  
  * \[x\] Write SQL INSERT statements to populate the tables.  
  * \[x\] Use COPY FROM for larger datasets if applicable.  
  * \[x\] Respect insertion order based on foreign key dependencies (e.g., insert Genres and Actors before Tapes, insert Customers and Tapes before Rentals).  
  * \[x\] *Deliverable:* SQL files in data/.

### **Phase 3: PL/PGSQL Development**

* [x] **Task 3.1: Package Specification(s)**  
  * [x] Define package specifications (\_spec.sql files) using CREATE OR REPLACE PACKAGE. **Note:** PostgreSQL doesn't have native packages like Oracle. Emulate this using schemas and naming conventions (e.g., functions like pkg\_customers.add\_customer(...)) or by grouping related functions/procedures logically. For this plan, we'll assume grouping functions under schemas or using naming conventions. If actual packages are needed (via extensions like orafce), adjust accordingly. We will use schema-based grouping for this plan.  
  * [x] Create schemas for logical grouping: CREATE SCHEMA pkg\_customers; CREATE SCHEMA pkg\_tapes; CREATE SCHEMA pkg\_rentals;  
  * [x] Define function/procedure signatures within the appropriate schema.  
  * [x] Example Signatures:  
    * pkg\_customers.add\_customer(p\_first\_name VARCHAR, p\_last\_name VARCHAR, ...)  
    * pkg\_tapes.find\_tapes\_by\_title(p\_pattern VARCHAR) RETURNS SETOF tapes  
    * pkg\_rentals.rent\_tape(p\_customer\_id INT, p\_tape\_id INT) RETURNS INT (returns new rental\_id or error)  
  * [x] Define any custom types (CREATE TYPE) needed for return values if not returning table rows directly.  
  * [x] *Deliverable:* SQL files creating schemas and potentially placeholder function/procedure definitions (packages/\*\_spec.sql can contain these definitions or just comments outlining the plan).  
* [x] **Task 3.2: Package Body(ies) \- CRUD Procedures/Functions**  
  * [x] Implement the functions/procedures (\_body.sql files or combined files per schema).  
  * [x] Write PL/PGSQL code for CREATE operations (e.g., pkg\_customers.add\_customer). Use INSERT ... RETURNING id where useful.  
  * [x] Write PL/PGSQL code for READ operations (e.g., pkg\_customers.get\_customer(p\_id INT) RETURNS customers, pkg\_tapes.get\_all\_tapes() RETURNS SETOF tapes).  
  * [x] Write PL/PGSQL code for UPDATE operations (e.g., pkg\_customers.update\_customer\_email(p\_id INT, p\_new\_email VARCHAR)).  
  * [x] Write PL/PGSQL code for DELETE operations (e.g., pkg\_customers.delete\_customer(p\_id INT)).  
  * [x] Include robust error handling using BEGIN...EXCEPTION...END blocks. Raise exceptions for invalid inputs, records not found (NO\_DATA\_FOUND), duplicate keys (UNIQUE\_VIOLATION), etc.  
  * [x] *Deliverable:* Implemented functions/procedures in SQL files (packages/\*\_body.sql or similar).  
* [x] **Task 3.3: Package Body(ies) \- Search Functions**  
  * [x] Implement search functions within the appropriate schemas.  
  * [x] Examples: pkg\_tapes.find\_tapes\_by\_title(p\_pattern VARCHAR) RETURNS SETOF tapes, pkg\_customers.find\_customers\_by\_name(p\_pattern VARCHAR) RETURNS SETOF customers, pkg\_tapes.find\_available\_tapes\_by\_genre(p\_genre\_id INT) RETURNS SETOF tapes.  
  * [x] Use appropriate parameters and return types (SETOF \<table\_type\>, TABLE(...), custom types).  
  * [x] Optimize queries for performance (use indexes).  
  * [x] *Deliverable:* Implemented search functions in SQL files (packages/\*\_body.sql or similar).  
* [x] **Task 3.4: Package Body(ies) \- Custom Procedures/Functions**  
  * [x] Implement custom business logic.  
  * [x] Examples:  
    * pkg\_rentals.rent\_tape(p\_customer\_id INT, p\_tape\_id INT) RETURNS INT: Checks stock, creates rental record, potentially updates stock (or relies on trigger). Returns rental\_id.  
    * pkg\_rentals.return\_tape(p\_rental\_id INT) RETURNS DATE: Updates rental record with return date, potentially updates stock (or relies on trigger). Returns return date.  
    * pkg\_rentals.calculate\_late\_fees(p\_rental\_id INT) RETURNS NUMERIC: Calculates fees based on due date and return date.  
    * pkg\_customers.get\_rental\_history(p\_customer\_id INT) RETURNS SETOF \<rental\_history\_type\>: Retrieves past and current rentals for a customer.  
  * [x] Ensure atomicity where needed (e.g., renting should likely decrease stock and create rental record together). Use transactions if logic spans multiple steps that must succeed or fail together.  
  * [x] *Deliverable:* Implemented custom logic functions/procedures in SQL files (packages/\*\_body.sql or similar).  
* [x] **Task 3.5: Trigger Creation Scripts**  
  * [x] Define at least three triggers as required\[cite: 15\].  
  * [x] Create trigger functions (PL/PGSQL functions returning TRIGGER).  
  * [x] Example Trigger Functions:  
    * fn\_update\_tape\_stock(): Called AFTER INSERT OR DELETE OR UPDATE OF return\_date ON rentals. Increments/decrements tapes.stock\_available. Handles both rental and return.  
    * fn\_prevent\_customer\_deletion(): Called BEFORE DELETE ON customers. Checks if customer has outstanding rentals (where return\_date is NULL in rentals). Raises an exception if outstanding rentals exist.  
    * fn\_log\_rental\_activity(): Called AFTER INSERT OR UPDATE ON rentals. Inserts a record into an audit\_log table detailing the change (who, what, when).  
    * fn\_check\_tape\_availability(): Called BEFORE INSERT ON rentals. Checks if tapes.stock\_available \> 0 for the tape\_id being rented. Raises exception if stock is zero.  
  * [x] Write CREATE TRIGGER statements linking functions to tables and events (BEFORE/AFTER, INSERT/UPDATE/DELETE, FOR EACH ROW/FOR EACH STATEMENT).  
  * [x] *Deliverable:* SQL files in triggers/ containing both CREATE FUNCTION ... RETURNS TRIGGER and CREATE TRIGGER ... statements.

### **Phase 4: Testing**

* \[ \] **Task 4.1: Develop Test Scenarios**  
  * \[ \] Define detailed scenarios covering:  
    * CRUD operations for each entity.  
    * All search functions with various inputs (matching, non-matching, patterns).  
    * Custom logic: successful rental, rental attempt with no stock, successful return, late return, fee calculation.  
    * Trigger actions: verify stock updates, verify delete prevention, check audit log entries.  
    * Edge cases: invalid inputs, boundary conditions, concurrent access issues (if applicable).  
  * \[ \] *Deliverable:* Test scenarios description (tests/test\_scenarios.md).  
* \[ \] **Task 4.2: Write Test Scripts/Queries**  
  * \[ \] Write SQL scripts (psql scripts or individual .sql files) to execute the test scenarios.  
  * \[ \] Use SELECT statements to call functions and procedures.  
  * \[ \] Use DO $$ ... $$ blocks for sequences of operations or checks.  
  * \[ \] Include INSERT, UPDATE, DELETE to set up preconditions and test triggers.  
  * \[ \] Verify results by querying tables, checking return values, or catching expected exceptions. Consider using pgTAP extension for more structured testing if desired.  
  * \[ \] *Deliverable:* SQL files in tests/.  
* \[ \] **Task 4.3: Execute Tests & Document Results**  
  * \[ \] Run the test scripts against the populated database.  
  * \[ \] Document the results: indicate pass/fail for each scenario. Include output logs or screenshots for key tests, especially failures.  
  * \[ \] Identify, debug, and fix any issues found in the code (tables, functions, triggers).  
  * \[ \] Re-run tests after fixes.  
  * \[ \] *Deliverable:* Documented test results, in the form of a simple html and js file that contains the pgsql client thta runs and documents all the tests with their traces and outputs in a simple html interface.

### **Phase 5: Documentation**

* \[ \] **Task 5.1: Finalize Technical Documentation**  
  * \[ \] Compile all documentation components into a coherent report (docs/technical\_report.md).  
  * \[ \] Include:  
    * Project Overview and Objectives.  
    * Conceptual Model (link to or embed docs/erd.md).  
    * Relational Schema (link to or embed docs/relational\_schema.md).  
    * Description of Schemas, Tables, Sequences, Indexes.  
    * Description of PL/PGSQL Functions, Procedures, and Triggers (explain logic and usage).  
    * Data Population Strategy.  
    * Test Plan and Results Summary (link to details).  
    * Instructions on how to set up and run the project.  
  * \[ \] Ensure all scripts (.sql files) are well-commented.  
  * \[ \] *Deliverable:* Final docs/technical\_report.md and all supporting files within the docs/ directory.

## **III. Final Deliverable**

* \[ \] **Task D.1: Package the Project**  
  * \[ \] Ensure all code (.sql files), documentation (.md files, including Mermaid diagrams), and test scripts are organized according to the defined project structure within the random\_play\_db/ root folder.  
  * \[ \] Add a README.md file at the root (random\_play\_db/README.md) explaining the project, the folder structure, and how to set up the database, populate data, and run tests.  
  * \[ \] Create a compressed archive (e.g., .zip or .tar.gz) of the entire random\_play\_db/ folder.  
  * \[ \] *Deliverable:* The final compressed project package containing all source code, documentation, and scripts in the specified structure.