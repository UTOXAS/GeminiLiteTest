async function loadEnv() {
    try {
        const response = await fetch('/GeminiLiteTest/.env');
        if (!response.ok) {
            throw new Error('Failed to load .env file');
        }
        const text = await response.text();
        const lines = text.split('\n');
        const env = {};
        lines.forEach(line => {
            const [key, value] = line.split('=');
            if (key && value) {
                env[key.trim()] = value.trim();
            }
        });
        return env.APPS_SCRIPT_URL;
    } catch (error) {
        console.error('Error loading .env:', error);
        throw new Error('Unable to load configuration');
    }
}

async function sendQuery() {
    const queryInput = document.getElementById('queryInput').value.trim();
    const responseArea = document.getElementById('responseArea');

    if (!queryInput) {
        responseArea.textContent = 'Please enter a query.';
        responseArea.classList.add('error');
        return;
    }

    responseArea.textContent = 'Loading...';
    responseArea.classList.remove('error');

    try {
        const APPS_SCRIPT_URL = await loadEnv();
        const response = await fetch(APPS_SCRIPT_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ query: queryInput }),
        });

        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }

        const data = await response.json();
        if (data.error) {
            throw new Error(data.error);
        }

        responseArea.textContent = data.response || 'No response received.';
    } catch (error) {
        responseArea.textContent = `Error: ${error.message}`;
        responseArea.classList.add('error');
    }
}

document.getElementById('submitButton').addEventListener('click', sendQuery);