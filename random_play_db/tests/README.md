# Random Play Video Tape Store - Test Runner

This folder contains a test runner application for testing PL/SQL functions and procedures for the Random Play Video Tape Store database.

## Folder Structure


- `sql_tests/` - Contains the SQL test scripts
  - `setup_db.sql` - Script to initialize the database schema and functions
  - `test_crud_customers.sql` - Tests for customer CRUD operations
  - `test_rental_operations.sql` - Tests for rental operations
  - `test_triggers.sql` - Tests for database triggers
- `docs/` - Documentation
  - `test_scenarios.md` - Comprehensive list of test scenarios
- `run_all_tests.sh` - Shell script to run all tests and save results
- `view_results.html` - HTML file to view and analyze test results

## Prerequisites

- PostgreSQL database with the Random Play Video Tape Store schema installed

## Running Tests Directly with psql

You can run the tests directly using psql command-line tool:

1. **Initialize your database** with the required schema, tables, and functions:

```bash
psql -U your_username -d your_database -f sql_tests/setup_db.sql
```

2. **Run individual test files**:

```bash
# Run customer tests
psql -U your_username -d your_database -f sql_tests/test_crud_customers.sql

# Run rental tests
psql -U your_username -d your_database -f sql_tests/test_rental_operations.sql

# Run trigger tests
psql -U your_username -d your_database -f sql_tests/test_triggers.sql
```

3. **Save test results to a file**:

```bash
# Save customer test results
psql -U your_username -d your_database -f sql_tests/test_crud_customers.sql > results_customers.txt

# Save rental test results
psql -U your_username -d your_database -f sql_tests/test_rental_operations.sql > results_rentals.txt

# Save trigger test results
psql -U your_username -d your_database -f sql_tests/test_triggers.sql > results_triggers.txt
```

4. **Run all tests and save results in a single file**:

```bash
(
    echo "===== CUSTOMER TESTS =====" &&
    psql -U your_username -d your_database -f sql_tests/test_crud_customers.sql &&
    echo -e "\n\n===== RENTAL TESTS =====" &&
    psql -U your_username -d your_database -f sql_tests/test_rental_operations.sql &&
    echo -e "\n\n===== TRIGGER TESTS =====" &&
    psql -U your_username -d your_database -f sql_tests/test_triggers.sql
) > all_test_results.txt
```

## Using the Test Runner Script

For convenience, a shell script is provided to run all tests and save the results:

1.  **Review Script Configuration:**
    *   Open `run_all_tests.sh` in a text editor.
    *   Verify that the `CONNECTION_STRING` variable points to your target database. The current value is hardcoded for a specific Neon.tech database.
    *   Verify that the `PSQL_PATH` variable points to the correct location of your `psql` executable.

2.  Make the script executable (if you haven't already):

```bash
chmod +x run_all_tests.sh
```

3.  Run the script:

```bash
./run_all_tests.sh
```

4.  The results will be saved to `tests_result.txt` by default.

5.  To specify a different output file name, use the `-o` option:

```bash
./run_all_tests.sh -o custom_results.log
```

## Viewing Test Results

After running the tests and saving the results, you can view them using the HTML viewer:

1. Open the `view_results.html` file in a web browser
2. Click "Choose File" and select your test results file
3. Use the buttons to highlight passed/failed tests and view a summary

Features:
- Highlight passed tests (green)
- Highlight failed tests (red)
- View test summary with passed/failed counts
- List of failed tests for easy debugging

## Test Runner Web Application

Alternatively, you can use the included web-based test runner application:

1. Install dependencies:

```bash
cd random_play_db/tests
npm install
```

2. Start the test runner server:

```bash
npm start
```

3. Open your web browser and navigate to:

```
http://localhost:3000
```

4. In the web interface:
   - Enter your PostgreSQL connection string
   - Click "Connect"
   - Once connected, you can run individual test scripts or all tests

## Connection String Format

```
postgresql://username:password@host:port/database?sslmode=require
```

Example:
```
postgresql://postgres:password@localhost:5432/random_play_db
```

For database hosted services like Neon.tech, make sure to include any required SSL parameters.

## Test Scripts

Each SQL test script contains a series of tests, executed as anonymous PL/pgSQL blocks. The tests use RAISE NOTICE to provide feedback on success or failure.

- `test_crud_customers.sql` - Tests C1-C7 for customer operations
- `test_rental_operations.sql` - Tests R1-R6 for rental operations
- `test_triggers.sql` - Tests TG1-TG9 for database triggers

See `docs/test_scenarios.md` for a complete description of all test scenarios.

## Testing API

You can run a basic API test to ensure the server is functioning properly:

```bash
npm run test:api
```

## Troubleshooting

- Make sure your database is running and accessible with the credentials provided
- If tests fail with errors like "function pkg_customers.add_customer does not exist", run the setup_db.sql script
- The SQL test scripts assume that certain tables and functions exist - make sure your database schema is correctly set up
- Check the server console output for any errors 