/**
 * Frontend script for the Random Play PL/PGSQL Test Runner.
 * Handles UI interactions and communicates with the backend server.
 */

document.addEventListener('DOMContentLoaded', function() {
    
    // Test section accordion functionality
    const headers = document.querySelectorAll('.test-header');
    headers.forEach(header => {
        header.addEventListener('click', function() {
            const section = this.parentElement;
            section.classList.toggle('active');
        });
    });
    
    // Run test button functionality
    const runButtons = document.querySelectorAll('.run-test');
    runButtons.forEach(button => {
        button.addEventListener('click', async function() {
            const scriptName = this.getAttribute('data-script');
            const section = this.closest('.test-section');
            const outputDiv = section.querySelector('.output');
            const statusSpan = section.querySelector('.status');
            
            // Update status to running
            statusSpan.className = 'status status-running';
            statusSpan.textContent = 'Running';
            outputDiv.innerHTML = ''; // Clear previous output
            appendOutput(outputDiv, `Requesting execution for: ${scriptName}...\n`, 'notice');

            try {
                // Call the backend API to run the test
                const response = await fetch('/api/run-test', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ script: scriptName }),
                });

                const result = await response.json();

                if (!response.ok) {
                    // Handle HTTP errors (like 500 Internal Server Error)
                    throw new Error(result.error || `Server error: ${response.status}`);
                }
                
                // Display output from the backend
                if (result.output && Array.isArray(result.output)) {
                    result.output.forEach(line => {
                        appendOutput(outputDiv, `${line.text}\n`, line.type || 'notice');
                    });
                }
                appendOutput(outputDiv, `\nExecution complete.\n`, 'notice');

                // Update status based on backend result
                if (result.success) {
                    statusSpan.className = 'status status-success';
                    statusSpan.textContent = 'Success';
                } else {
                    statusSpan.className = 'status status-failed';
                    statusSpan.textContent = 'Failed';
                }

            } catch (error) {
                console.error('Error running test:', error);
                appendOutput(outputDiv, `\nError communicating with server: ${error.message}\n`, 'error');
                statusSpan.className = 'status status-failed';
                statusSpan.textContent = 'Failed';
            } finally {
                // Update summary regardless of success/failure
                updateTestSummary();
            }
        });
    });
    
    // Run all tests button
    document.getElementById('run-all').addEventListener('click', function() {
        const runButtons = document.querySelectorAll('.run-test');
        // Simple sequential execution with delay
        let delay = 0;
        runButtons.forEach(button => {
            setTimeout(() => button.click(), delay);
            delay += 1000; // Add delay between starting tests
        });
    });
    
    // Clear all results button
    document.getElementById('clear-all').addEventListener('click', function() {
        const outputDivs = document.querySelectorAll('.output');
        outputDivs.forEach(div => {
            div.innerHTML = '';
        });
        
        const statusSpans = document.querySelectorAll('.status');
        statusSpans.forEach(span => {
            span.className = 'status status-pending';
            span.textContent = 'Pending';
        });
        
        document.getElementById('test-summary').innerHTML = '<h2>Test Summary</h2><p>No tests have been run yet.</p>';
    });
    
    // Set up database connection configuration form
    setupConnectionForm();
});

/**
 * Set up database connection configuration form
 */
function setupConnectionForm() {
    const connectionStatus = document.getElementById('connection-status');
    const stringForm = document.getElementById('connection-string-form');
    const connectButton = stringForm.querySelector('button[type="submit"]');
    
    // Handle connection string form submission
    stringForm.addEventListener('submit', async function(e) {
        e.preventDefault(); // Prevent page reload
        
        const connectionString = document.getElementById('connection-string').value;
        connectionStatus.innerHTML = 'Connecting to server...';
        connectButton.disabled = true;
        
        try {
            // Call the backend API to establish the connection
            const response = await fetch('/api/connect', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ connectionString }),
            });
            
            const result = await response.json();
            
            if (!response.ok || !result.success) {
                throw new Error(result.error || 'Failed to connect via server.');
            }
            
            // Update status and enable buttons
            connectionStatus.innerHTML = '<span class="success">✓ Connected via Server!</span>';
            document.querySelectorAll('.run-test').forEach(btn => {
                btn.disabled = false;
            });
            document.getElementById('run-all').disabled = false;
            
        } catch (err) {
            console.error("Connection attempt failed:", err);
            connectionStatus.innerHTML = `<span class="error">✗ Connection failed: ${err.message}</span>`;
            // Disable test buttons if connection failed
            document.querySelectorAll('.run-test').forEach(btn => {
                btn.disabled = true;
            });
            document.getElementById('run-all').disabled = true;
        } finally {
            connectButton.disabled = false; // Re-enable connect button
        }
    });
}

/**
 * Append text to the output div with styling
 */
function appendOutput(outputDiv, text, type) {
    if (!outputDiv) return; // Safety check
    const span = document.createElement('span');
    span.textContent = text;
    span.className = type;
    outputDiv.appendChild(span);
    
    // Auto-scroll to the bottom
    outputDiv.scrollTop = outputDiv.scrollHeight;
}

/**
 * Update the test summary section
 */
function updateTestSummary() {
    const summaryDiv = document.getElementById('test-summary');
    const statuses = document.querySelectorAll('.status');
    
    let pending = 0;
    let running = 0;
    let success = 0;
    let failed = 0;
    
    statuses.forEach(status => {
        if (!status) return; // Safety check
        if (status.textContent === 'Pending') pending++;
        if (status.textContent === 'Running') running++;
        if (status.textContent === 'Success') success++;
        if (status.textContent === 'Failed') failed++;
    });
    
    let html = '<h2>Test Summary</h2>';
    
    if (pending === statuses.length && running === 0 && success === 0 && failed === 0) {
        html += '<p>No tests have been run yet.</p>';
    } else {
        html += `
            <p>
                <strong>Total Sections:</strong> ${statuses.length} | 
                <strong>Pending:</strong> ${pending} | 
                <strong>Running:</strong> ${running} | 
                <strong class="success">Success:</strong> ${success} | 
                <strong class="error">Failed:</strong> ${failed}
            </p>
        `;
    }
    
    if(summaryDiv) summaryDiv.innerHTML = html;
} 