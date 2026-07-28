document.addEventListener('DOMContentLoaded', () => {
    const connectWalletBtn = document.createElement('button');
    connectWalletBtn.id = 'connectWallet';
    connectWalletBtn.textContent = 'Connect Web3 Wallet';
    connectWalletBtn.style.backgroundColor = '#0ecb81';
    connectWalletBtn.style.color = '#0b0e11';
    connectWalletBtn.style.marginBottom = '15px';

    const form = document.getElementById('userForm');
    form.parentNode.insertBefore(connectWalletBtn, form);

    connectWalletBtn.addEventListener('click', async (e) => {
        e.preventDefault();
        if (window.ethereum) {
            try {
                const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
                const account = accounts[0];
                document.getElementById('walletAddress').value = account;
                document.getElementById('output').textContent = `Connected Wallet: ${account}`;
            } catch (err) {
                console.error(err);
            }
        } else {
            alert('No Web3 wallet detected. Please install MetaMask or use a compatible browser.');
        }
    });
});
