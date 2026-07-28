document.getElementById('userForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('username').value;
    const walletAddress = document.getElementById('walletAddress').value;
    const outputBox = document.getElementById('output');

    outputBox.textContent = 'Connecting to network...';

    try {
        const response = await fetch('/api/user', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, walletAddress })
        });
        const data = await response.json();
        outputBox.textContent = JSON.stringify(data, null, 2);
    } catch (err) {
        outputBox.textContent = 'Error: ' + err.message;
    }
});
