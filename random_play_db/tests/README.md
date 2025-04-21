# Random Play Video Tape Store - Test Runner

This folder contains a test runner application for testing PL/SQL functions and procedures for the Random Play Video Tape Store database.

## Folder Structure

- `sql_tests/` - Contains the SQL test scripts
  - `test_crud_customers.sql` - Tests for customer CRUD operations
  - `test_rental_operations.sql` - Tests for rental operations
  - `test_triggers.sql` - Tests for database triggers
- `docs/` - Documentation
  - `test_scenarios.md` - Comprehensive list of test scenarios
- `run_all_tests.sh` - Shell script to run all tests and save results
- `view_results.html` - HTML file to view and analyze test results
- `README.md` - This file

## Using the Test Runner Script

A shell script is provided to run all tests against the database and save the results:

1.  **Review Script Configuration:**
    *   Open `run_all_tests.sh` in a text editor.
    *   Verify that the `CONNECTION_STRING` variable points to your target database. It is currently set to:
        ```
        postgresql://username:password@host:port/random-play-db?sslmode=require
        ```
    *   Verify that the `PSQL_PATH` variable points to the correct location of your `psql` executable (e.g., `/opt/homebrew/bin/psql`, `/usr/bin/psql`).

2.  Make the script executable (if you haven't already):

    ```bash
    chmod +x run_all_tests.sh
    ```

3.  Run the script from the `tests` directory:

    ```bash
    ./run_all_tests.sh
    ```

4.  The script will execute all `.sql` files in the `sql_tests` directory and save the combined output to `tests_result.txt` by default.

5.  A summary will be printed to the console, indicating the number of PASSED and FAILED tests found in the output, along with any ERRORS or EXCEPTIONS detected.

    Example Summary Output:
    ```
    ===== TEST SUMMARY =====
    Total Tests Run:   22
    ----------------------
    PASSED:            22
    FAILED:            0
    ERRORS/EXCEPTIONS: 0 (Check tests_result.txt for details)
    ----------------------
    ======================
    ```

6.  To specify a different output file name, use the `-o` option:

    ```bash
    ./run_all_tests.sh -o custom_results.log
    ```

## Browsing the Database

You can connect to the database to browse tables, run queries, or manually test functions using `psql` or a GUI client.

**Using `psql`:**

Open your terminal and use the connection string directly:

```bash
psql "postgresql://username:password@host:port/random-play-db?sslmode=require"
```

Once connected, you can use standard SQL commands and `psql` meta-commands:

-   `\dt`: List tables
-   `\df`: List functions
-   `\l`: List databases
-   `SELECT * FROM customers LIMIT 10;`: Run a query
-   `\q`: Quit `psql`

**Using a GUI Client (e.g., DBeaver, pgAdmin, TablePlus):**

1.  Create a new PostgreSQL connection.
2.  Use the components of the connection string:
    *   **Host:** `host`
    *   **Port:** `5432` (Default PostgreSQL port)
    *   **Database:** `random-play-db`
    *   **Username:** `username`
    *   **Password:** (Enter the password associated with the user)
    *   **SSL Mode:** `require` (or the equivalent setting in your client)
3.  Connect and browse the schema, tables, and data.



## Troubleshooting

- Make sure your database is running and accessible with the credentials provided in the connection string.
- Ensure the `psql` path in `run_all_tests.sh` is correct for your system.
- Check the `tests_result.txt` file for detailed error messages from `psql` if the script fails or tests report errors.
