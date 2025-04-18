# Random Play Video Store Project

![Video Store Database Banner](img.jpg "Random Play Video Store Database")

## Overview

Random Play is a PostgreSQL-based database schema designed for managing a video rental store's operations. The schema includes comprehensive support for customer management, video tape inventory, actor information, rental transactions, and reporting capabilities.

## Project Structure

```
├── README.md
└── random_play_db
    ├── data                  # Sample data files for database population
    ├── db_schema             # Core database schema definition
    ├── docs                  # Database documentation
    ├── packages              # PL/pgSQL packages for business logic
    ├── tests                 # Testing suite and documentation
    └── triggers              # Database triggers
```

## Documentation

- [Entity Relationship Diagram](random_play_db/docs/erd.md) - Visual representation of database entities and relationships
- [Relational Schema](random_play_db/docs/relational_schema.md) - Detailed database schema documentation
- [Test Documentation](random_play_db/tests/README.md) - Testing strategy, scenarios, and execution guidelines

## Core Features

### Customer Management

- Customer profiles with contact information and rental history
- Integrated customer activity tracking
- Prevent accidental customer deletion with active rentals

### Inventory Management

- Comprehensive tape catalog with genre classification
- Actor database with filmography connections
- Automatic tape availability status updates

### Rental System

- Rental transaction processing and tracking
- Late return management
- Historical rental data for analytics

### Audit System

- Comprehensive audit logging for critical operations
- Rental activity tracking
- Stock level monitoring

## Packages

The database functionality is organized into the following packages:

1. **pkg_customers** - Customer management operations
2. **pkg_rentals** - Rental transaction processing
3. **pkg_reports** - Reporting and analytics functions
4. **pkg_tapes** - Tape inventory management

## I want to see results of the tests, don't waste my time

Of course. You can see the results of the tests in the `tests/tests_result.txt` file.

## I want to run the tests

See the [Testing](#testing) section below for instructions on running tests.

## Getting Started

### Prerequisites

- PostgreSQL 13.0+
- psql command-line client or compatible GUI tool

### Installation

1. Clone this repository
2. Navigate to the project root directory
3. Run the database setup script:

```bash
cd random_play_db/tests
./run_all_tests.sh
```

### Sample Data

The repository includes sample data for testing and development:

- Sample customer records
- Movie catalog entries
- Actor information
- Rental history

Execute the data scripts in numerical order to populate the database:

```sql
\i data/01_lookup_data.sql
\i data/02_sample_actors.sql
...
```

## Testing

The project includes a comprehensive test suite to validate database functionality:

first of all make sure you have the `psql` command-line client installed. (I included the unix systems isntructions below in the readme of the tests folder)

also update the connection strign in the sh file to point to your database (or use mine xD)

```bash
cd tests
./run_all_tests.sh
```

For detailed testing documentation, refer to the [Tests README](tests/README.md).

## License

[MIT License](LICENSE)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Submit a pull request

## Contact

For questions or support, send me an email at ashrefbenabdallah@icloud.com
