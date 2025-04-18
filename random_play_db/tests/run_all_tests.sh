#!/bin/bash

# Random Play Video Tape Store - Test Runner Script
# This script runs all tests and saves results to a file

# Connection string for Neon.tech database
CONNECTION_STRING="postgresql://ashref1944:sL7pgZ4FHbYQ@ep-bitter-salad-a2fxuy5k-pooler.eu-central-1.aws.neon.tech/random-play-db?sslmode=require"
PSQL_PATH="/opt/homebrew/bin/psql" # Adjust if your psql is elsewhere
RESULTS_FILE="tests_result.txt"

# Parse command line arguments
while getopts o: flag; do
    case "${flag}" in
    o) RESULTS_FILE=${OPTARG} ;;
    esac
done

echo "Running tests with connection to Neon.tech database..."
# Avoid printing the full connection string with password to console
echo "Results will be saved to: $RESULTS_FILE"

# Create timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Run tests and save results
(
    echo "===================================================="
    echo "  RANDOM PLAY VIDEO TAPE STORE - TEST RESULTS"
    echo "  $TIMESTAMP"
    echo "===================================================="
    echo -e "\\n\\n===== CUSTOMER TESTS =====" &&
        "$PSQL_PATH" "$CONNECTION_STRING" -f sql_tests/test_crud_customers.sql &&
        echo -e "\\n\\n===== RENTAL TESTS =====" &&
        "$PSQL_PATH" "$CONNECTION_STRING" -f sql_tests/test_rental_operations.sql &&
        echo -e "\\n\\n===== TRIGGER TESTS =====" &&
        "$PSQL_PATH" "$CONNECTION_STRING" -f sql_tests/test_triggers.sql &&
        echo -e "\\n\\n===================================================="
    echo "  TEST EXECUTION COMPLETED"
    echo "===================================================="
) >"$RESULTS_FILE" 2>&1

echo "Tests completed. Results saved to $RESULTS_FILE"

# --- New Detailed Summary Section (Portable Version) ---
echo -e "\\n===== DETAILED TEST SUMMARY ====="

# Initialize counters
OVERALL_PASSED_COUNT=0
OVERALL_FAILED_COUNT=0
CUST_PASSED=0
CUST_FAILED=0
RENTAL_PASSED=0
RENTAL_FAILED=0
TRIGGER_PASSED=0
TRIGGER_FAILED=0

# --- Process Customer Tests ---
echo -e "\\n--- Customer Tests (sql_tests/test_crud_customers.sql) ---"
# Extract lines between CUSTOMER and RENTAL markers, then grep for Test C... lines
# Use process substitution and loop for portability
TEMP_CUST_RESULTS=$(sed -n '/===== CUSTOMER TESTS =====/,/===== RENTAL TESTS =====/p' "$RESULTS_FILE" | sed '$d' | grep "NOTICE:.*Test C[0-9]\\+ \\(PASSED\\|FAILED\\)")

if [ -n "$TEMP_CUST_RESULTS" ]; then
    while IFS= read -r line; do
        TEST_INFO=$(echo "$line" | sed 's/^.*NOTICE:  //')
        echo "  - $TEST_INFO" # Print formatted line
        if echo "$line" | grep -q "PASSED"; then
            CUST_PASSED=$((CUST_PASSED + 1))
        elif echo "$line" | grep -q "FAILED"; then
            CUST_FAILED=$((CUST_FAILED + 1))
        fi
    done <<<"$TEMP_CUST_RESULTS" # Use Here String
fi
echo "  PASSED: ${CUST_PASSED}, FAILED: ${CUST_FAILED}"

# --- Process Rental Tests ---
echo -e "\\n--- Rental Tests (sql_tests/test_rental_operations.sql) ---"
RENTAL_PASSED=0 # Reset counter for this section
RENTAL_FAILED=0 # Reset counter for this section
# Use process substitution instead of pipe to avoid subshell issues
while IFS= read -r line; do
    TEST_INFO=$(echo "$line" | sed 's/^.*NOTICE:  //')
    echo "  - $TEST_INFO" # Print formatted line
    if echo "$line" | grep -q "PASSED"; then
        RENTAL_PASSED=$((RENTAL_PASSED + 1))
    elif echo "$line" | grep -q "FAILED"; then
        RENTAL_FAILED=$((RENTAL_FAILED + 1))
    fi
    # Feed the loop using process substitution
done < <(sed -n '/===== RENTAL TESTS =====/,/===== TRIGGER TESTS =====/p' "$RESULTS_FILE" | sed '$d' | grep "NOTICE:.*Test R[0-9]\\+ \\(PASSED\\|FAILED\\)")
echo "  PASSED: ${RENTAL_PASSED}, FAILED: ${RENTAL_FAILED}"

# --- Process Trigger Tests ---
echo -e "\n--- Trigger Tests (sql_tests/test_triggers.sql) ---"
TEMP_TRIGGER_RESULTS=$(sed -n '/===== TRIGGER TESTS =====/,/===== TEST EXECUTION COMPLETED =====/p' "$RESULTS_FILE" | sed '$d' | grep "NOTICE:.*Test TG[0-9]\+\(-\| \)\(PASSED\|FAILED\)")

if [ -n "$TEMP_TRIGGER_RESULTS" ]; then
    # Print all relevant trigger test lines first
    while IFS= read -r line; do
        TEST_INFO=$(echo "$line" | sed 's/^.*NOTICE:  //')
        echo "  - $TEST_INFO"
    done <<<"$TEMP_TRIGGER_RESULTS"

    # Count unique tests based on "Test TGx PASSED/FAILED" pattern
    TRIGGER_PASSED=$(echo "$TEMP_TRIGGER_RESULTS" | grep -Eo "Test TG[0-9]+ PASSED" | sort -u | wc -l)
    TRIGGER_FAILED=$(echo "$TEMP_TRIGGER_RESULTS" | grep -Eo "Test TG[0-9]+ FAILED" | sort -u | wc -l)
fi
echo "  PASSED: ${TRIGGER_PASSED}, FAILED: ${TRIGGER_FAILED}"

# --- Overall Summary ---
OVERALL_PASSED_COUNT=$((CUST_PASSED + RENTAL_PASSED + TRIGGER_PASSED))
OVERALL_FAILED_COUNT=$((CUST_FAILED + RENTAL_FAILED + TRIGGER_FAILED))

echo -e "\\n===== OVERALL SUMMARY ======"
ERROR_COUNT=$(grep -cE "^(ERROR:|EXCEPTION:)" "$RESULTS_FILE") # Count specific PostgreSQL errors/exceptions

TOTAL_TESTS_PROCESSED=$((OVERALL_PASSED_COUNT + OVERALL_FAILED_COUNT))

echo "Total Tests Processed: $TOTAL_TESTS_PROCESSED"
echo "------------------------"
echo "PASSED:              $OVERALL_PASSED_COUNT"
echo "FAILED:              $OVERALL_FAILED_COUNT"
echo "ERRORS/EXCEPTIONS:   $ERROR_COUNT (Check '$RESULTS_FILE' for details)"
echo "------------------------"

# List errors/exceptions if any
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "\\nErrors/Exceptions Found in '$RESULTS_FILE':"
    grep -E "^(ERROR|EXCEPTION):" "$RESULTS_FILE" | sed 's/CONTEXT:.*$//' | sed 's/HINT:.*$//' | sed 's/LINE [0-9].*FUNCTION.*$//' | sed 's/Query.*$//' | awk '!seen[$0]++{print "  " $0}' # Attempt to show unique, cleaner error messages
    echo ""                                                                                                                                                                                # Extra newline for spacing
fi

echo "========================"
