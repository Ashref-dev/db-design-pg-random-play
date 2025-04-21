# Random Play Video Tape Store - Test Scenarios

This document outlines various test scenarios to validate the functionality of the Random Play Video Tape Store database system.

## 1. Customer Management Tests

### 1.1 CRUD Operations
- **C1**: Create a new customer with valid information
- **C2**: Attempt to create a customer with duplicate email (should fail)
- **C3**: Retrieve a customer by ID
- **C4**: Retrieve a customer by email
- **C5**: Update a customer's contact information
- **C6**: Delete a customer with no rental history
- **C7**: Attempt to delete a customer with active rentals (should fail)

### 1.2 Search Functions
- **C8**: Find customers by name pattern (exact match)
- **C9**: Find customers by name pattern (partial match)
- **C10**: Find customers by name pattern (no match)
- **C11**: Search customers with multiple criteria (email and registration date)
- **C12**: Find active customers

### 1.3 Special Operations
- **C13**: Activate a deactivated customer
- **C14**: Deactivate an active customer
- **C15**: Find customers with active rentals
- **C16**: Find customers with overdue rentals
- **C17**: Find top spending customers

## 2. Tape Management Tests

### 2.1 CRUD Operations
- **T1**: Add a new tape with valid information
- **T2**: Retrieve a tape by ID
- **T3**: Update a tape's information (title, price, etc.)
- **T4**: Delete a tape with no rental history
- **T5**: Attempt to delete a tape with active rentals (outcome depends on constraints)

### 2.2 Search Functions
- **T6**: Find tapes by title pattern (exact match)
- **T7**: Find tapes by title pattern (partial match)
- **T8**: Find tapes by title pattern (no match)
- **T9**: Search tapes with multiple criteria (genre and release year)
- **T10**: Find all available tapes
- **T11**: Find available tapes by genre

### 2.3 Special Operations
- **T12**: Add actor to tape
- **T13**: Get tape actors
- **T14**: Update tape stock (increase)
- **T15**: Update tape stock (decrease)
- **T16**: Find most popular tapes
- **T17**: Find never rented tapes

## 3. Rental Management Tests

### 3.1 Core Rental Operations
- **R1**: Rent a tape to a customer (happy path)
- **R2**: Attempt to rent a tape with zero stock available (should fail)
- **R3**: Return a tape (on time)
- **R4**: Return a tape (late, with late fees)
- **R5**: Calculate late fees for an overdue rental
- **R6**: Extend a rental period

### 3.2 Search Functions
- **R7**: Get rental by ID
- **R8**: Find overdue rentals
- **R9**: Find a customer's active rentals
- **R10**: Get rental history within a date range
- **R11**: Search rentals with multiple criteria
- **R12**: Find high-value rentals

### 3.3 Bulk Operations
- **R13**: Bulk rent multiple tapes to a customer
- **R14**: Bulk return multiple tapes
- **R15**: Check customer eligibility for rental

## 4. Reporting Tests

### 4.1 Revenue Reports
- **RP1**: Get revenue by period
- **RP2**: Get monthly revenue report for a specific year

### 4.2 Popularity Reports
- **RP3**: Get popular genres
- **RP4**: Get popular tapes
- **RP5**: Get customer activity (most active customers)

### 4.3 Status Reports
- **RP6**: Get customer spending
- **RP7**: Get overdue summary
- **RP8**: Get inventory status

## 5. Trigger Tests

### 5.1 Stock Management
- **TG1**: Verify tape stock decreases when rented
- **TG2**: Verify tape stock increases when returned
- **TG3**: Verify tape stock remains unchanged when rental is updated (without return)

### 5.2 Customer Protection
- **TG4**: Verify prevention of customer deletion with active rentals

### 5.3 Audit Logging
- **TG5**: Verify audit log entry creation for new rental
- **TG6**: Verify audit log entry creation for tape return
- **TG7**: Verify audit log entry creation for rental record update
- **TG8**: Verify audit log entry creation for rental record deletion

### 5.4 Tape Availability
- **TG9**: Verify prevention of renting unavailable tapes 