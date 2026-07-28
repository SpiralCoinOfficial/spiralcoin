// Basic Chart.js Integration for SPLC Live Pricing Feed
const ctx = document.getElementById('priceChart').getContext('2d');
const priceChart = new Chart(ctx, {
    type: 'line',
    data: {
        labels: ['10:00', '11:00', '12:00', '13:00', '14:00', '15:00'],
        datasets: [{
            label: 'SPLC / USD',
            data: [1.00, 1.05, 1.02, 1.08, 1.12, 1.15],
            borderColor: '#0ecb81',
            backgroundColor: 'rgba(14, 203, 129, 0.1)',
            borderWidth: 2,
            fill: true,
            tension: 0.1
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: { labels: { color: '#eaecef' } }
        },
        scales: {
            x: { ticks: { color: '#848e9c' }, grid: { color: '#2b313a' } },
            y: { ticks: { color: '#848e9c' }, grid: { color: '#2b313a' } }
        }
    }
});
