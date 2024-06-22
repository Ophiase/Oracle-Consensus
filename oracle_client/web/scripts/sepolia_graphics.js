// scripts/graphics.js
let sepolia_charts = [];

function initializeProgressBars() {
    const ids = ['progress-bar-1', 'progress-bar-2']; //, 'progress-bar-3'];
    const textIds = ['progress-text-1', 'progress-text-2']; //, 'progress-text-3'];
    const percentages = [0, 0]; //, 0];

    ids.forEach((id, index) => {
        const ctx = document.getElementById(id).getContext('2d');
        const progressText = document.getElementById(textIds[index]);
        // progressText.innerText = `Progress: ${percentages[index]}%`;

        const data = {
            labels: ['Percentage'],
            datasets: [{
                label: 'Completion',
                data: [percentages[index]],
                backgroundColor: percentages[index] < 50 ? 'rgba(255, 99, 132, 0.2)' : 'rgba(75, 192, 192, 0.2)',
                borderColor: percentages[index] < 50 ? 'rgba(255, 99, 132, 1)' : 'rgba(75, 192, 192, 1)',
                borderWidth: 1
            }]
        };

        const options = {
            indexAxis: 'y',
            scales: {
                x: {
                    max: 100,
                    beginAtZero: true
                }
            },
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    enabled: false
                }
            }
        };

        const chart = new Chart(ctx, {
            type: 'bar',
            data: data,
            options: options
        });

        sepolia_charts.push(chart);
    });
}

function updateProgressBar(index, percentage) {
    const labels = ["First Pass Reliability", "Second Pass Reliability", "?"]

    if (index < 0 || index >= sepolia_charts.length) {
        console.error('Invalid index for progress bar');
        return;
    }
    const chart = sepolia_charts[index];
    const textId = `progress-text-${index + 1}`;
    const progressText = document.getElementById(textId);

    chart.data.datasets[0].data[0] = percentage;
    chart.data.datasets[0].backgroundColor = percentage < 50 ? 'rgba(255, 99, 132, 0.2)' : 'rgba(75, 192, 192, 0.2)';
    chart.data.datasets[0].borderColor = percentage < 50 ? 'rgba(255, 99, 132, 1)' : 'rgba(75, 192, 192, 1)';
    // progressText.innerText = `${labels[index]}: ${percentage}%`;
    chart.update();
}

eel.expose(updateProgressBar)

document.addEventListener('DOMContentLoaded', function() {
    initializeProgressBars();
    updateProgressBar(0, 0);
    updateProgressBar(1, 0);
    // updateProgressBar(2, 30);
});
