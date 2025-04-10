/**
 * Backend server for the Random Play PL/PGSQL Test Runner.
 * Handles database connections and executes SQL test scripts.
 */

const express = require('express');
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); // Enable CORS for requests from the frontend
app.use(express.json()); // Parse JSON request bodies
app.use(express.static(__dirname)); // Serve static files (HTML, JS) from the tests directory

let pool; // Database connection pool - initialized on first request

/**
 * Initializes the database connection pool based on the provided connection string.
 */
function initializePool(connectionString) {
    if (!connectionString) {
        throw new Error('Connection string is required.');
    }
    console.log('Initializing database pool...');
    try {
        pool = new Pool({
            connectionString: connectionString,
            // Add SSL configuration if needed, especially for cloud databases
            // ssl: { rejectUnauthorized: false } // Use this for simple SSL connections (like Neon free tier)
        });

        // Test the connection
        pool.query('SELECT NOW()', (err, res) => {
            if (err) {
                console.error('Error initializing pool:', err);
                pool = null; // Reset pool if initialization fails
                throw err;
            } else {
                console.log('Database pool initialized successfully.');
            }
        });
    } catch (err) {
        console.error('Failed to create pool:', err);
        pool = null;
        throw err;
    }
}

/**
 * Endpoint to establish/test the database connection.
 * The frontend sends the connection string in the request body.
 */
app.post('/api/connect', async (req, res) => {
    const { connectionString } = req.body;
    console.log('Received connection request.');
    try {
        // Close existing pool if it exists before creating a new one
        if (pool) {
            await pool.end();
            console.log('Existing pool closed.');
            pool = null;
        }
        initializePool(connectionString);
        res.json({ success: true, message: 'Connection pool initialized successfully.' });
    } catch (error) {
        console.error('Connection error:', error);
        res.status(500).json({ success: false, error: error.message || 'Failed to connect to database.' });
    }
});

/**
 * Endpoint to run a specific SQL test script.
 * The frontend sends the script name in the request body.
 */
app.post('/api/run-test', async (req, res) => {
    const { script } = req.body;

    if (!pool) {
        return res.status(400).json({ success: false, error: 'Database connection not established. Please connect first.' });
    }

    if (!script) {
        return res.status(400).json({ success: false, error: 'Script name is required' });
    }

    // Basic sanitization to prevent directory traversal
    const safeScriptName = path.basename(script);
    const scriptPath = path.join(__dirname, safeScriptName);

    console.log(`Executing script: ${safeScriptName}`);

    try {
        if (!fs.existsSync(scriptPath)) {
            console.error(`Script not found: ${scriptPath}`);
            return res.status(404).json({ success: false, error: `Script not found: ${safeScriptName}` });
        }

        const sqlContent = fs.readFileSync(scriptPath, 'utf8');
        const result = await executeSqlScriptWithNotices(sqlContent);

        res.json({ success: result.success, output: result.output, details: result.details });

    } catch (error) {
        console.error(`Error running script ${safeScriptName}:`, error);
        res.status(500).json({ success: false, error: error.message || 'An unexpected error occurred.', output: [{ type: 'error', text: error.message }] });
    }
});

/**
 * Executes a SQL script using a dedicated client from the pool
 * and captures notice messages.
 */
async function executeSqlScriptWithNotices(sqlScript) {
    if (!pool) {
        throw new Error('Database pool is not initialized.');
    }

    const client = await pool.connect();
    console.log('Client checked out from pool.');
    let output = [];
    let details = { passes: 0, failures: 0 };
    let overallSuccess = true;

    // Listener for notice messages (e.g., RAISE NOTICE)
    const noticeListener = (notice) => {
        const message = notice.message ? notice.message.trim() : 'Unknown notice';
        console.log('NOTICE:', message);
        const isPass = message.includes('PASSED');
        const isFail = message.includes('FAILED');
        if (isPass) details.passes++;
        if (isFail) {
            details.failures++;
            overallSuccess = false; // Mark failure if a notice contains FAILED
        }
        output.push({
            type: isFail ? 'error' : (isPass ? 'success' : 'notice'),
            text: message
        });
    };

    client.on('notice', noticeListener);

    try {
        // Execute the entire script content as a single query
        // This is generally safer for scripts containing multiple statements or transaction blocks
        await client.query(sqlScript);
        console.log('Script execution completed.');

    } catch (error) {
        console.error('SQL Execution Error:', error);
        overallSuccess = false;
        details.failures++; // Count SQL errors as failures
        output.push({ type: 'error', text: `SQL Error: ${error.message}` });
        // Rethrow if you want the caller (/api/run-test) to handle it as a 500 error
        // throw error; 
    } finally {
        // Clean up listener and release client
        client.removeListener('notice', noticeListener);
        client.release();
        console.log('Client released back to pool.');
    }

    return { success: overallSuccess, output, details };
}

// Serve the main HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'test_runner.html'));
});

// Start the server
app.listen(PORT, () => {
    console.log(`Test Runner Server listening on http://localhost:${PORT}`);
    console.log('Ensure your PostgreSQL database is running and accessible.');
}); 