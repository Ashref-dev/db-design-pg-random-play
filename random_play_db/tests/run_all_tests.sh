#!/bin/bash

# Random Play Video Tape Store - Test Runner Script
# This script runs all tests and saves results to a file

# Connection string for Neon.tech database
CONNECTION_STRING="postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require"
PSQL_PATH="/opt/homebrew/bin/psql"
RESULTS_FILE="tests_result.txt"

# Parse command line arguments
while getopts o: flag
do
    case "${flag}" in
        o) RESULTS_FILE=${OPTARG};;
    esac
done

echo "Running tests with connection to Neon.tech database"
echo "Results will be saved to: $RESULTS_FILE"

# Create timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Run tests and save results
(
    echo "===================================================="
    echo "  RANDOM PLAY VIDEO TAPE STORE - TEST RESULTS"
    echo "  $TIMESTAMP"
    echo "===================================================="
    echo -e "\n\n===== CUSTOMER TESTS =====" &&
    $PSQL_PATH "$CONNECTION_STRING" -f sql_tests/test_crud_customers.sql &&
    echo -e "\n\n===== RENTAL TESTS =====" &&
    $PSQL_PATH "$CONNECTION_STRING" -f sql_tests/test_rental_operations.sql &&
    echo -e "\n\n===== TRIGGER TESTS =====" &&
    $PSQL_PATH "$CONNECTION_STRING" -f sql_tests/test_triggers.sql &&
    echo -e "\n\n===================================================="
    echo "  TEST EXECUTION COMPLETED"
    echo "===================================================="
) > "$RESULTS_FILE" 2>&1

echo "Tests completed. Results saved to $RESULTS_FILE"

# Print summary
echo "Summary of test results:"
grep -E "Test .+ PASSED|Test .+ FAILED" $RESULTS_FILE | sort | uniq -c 