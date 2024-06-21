let chartInstances = []; // Array to hold Chart instances

Chart.defaults.borderColor = '#363636';
Chart.defaults.color = '#000';

initComponents(3);

function initComponents(dimension) {
    chartInstances = [];
    const container = document.getElementById('plots-container');
    container.innerHTML = ''; 

    for (let i = 0; i < dimension; i++) {
        const plotContainer = document.createElement('div');
        plotContainer.className = 'plot';
        const canvas = document.createElement('canvas');
        plotContainer.appendChild(canvas);
        container.appendChild(plotContainer);

        const chart = new Chart(canvas, {
            type: 'scatter',
            data: {
                datasets: [{
                    label: `Component ${i + 1}`,
                    data: [], // Initial empty data
                    backgroundColor: 'rgba(54, 54, 54, 0.6)',  // Dark gray background
                    borderColor: 'rgba(34, 34, 34, 1)',        // Even darker border
                    borderWidth: 1
                }]
            },
            options: {
                aspectRatio: 1,
                animation: {
                    duration: 0 // Disable animation on update
                },
                scales: {
                    x: {
                        type: 'linear', // Ensure x-axis is linear (default)
                        min: 0, // Minimum value
                        max: 1, // Maximum value
                        title: {
                            display: true,
                            text: '' // Empty initially, will be updated
                        }
                    },
                    y: {
                        type: 'linear', // Ensure y-axis is linear (default)
                        min: 0, // Minimum value
                        max: 1, // Maximum value
                        title: {
                            display: true,
                            text: '' // Empty initially, will be updated
                        }
                    }
                },
                plugins: {
                    annotation: {
                        annotations: []
                    }
                }
            }
        });

        chartInstances.push(chart); // Store each chart instance
    }
}

eel.expose(initComponents)


function updateComponents(components) {
    components.forEach((component, index) => {
        const chart = chartInstances[index];
        chart.data.datasets[0].label = `Component ${index + 1}`;
        chart.data.datasets[0].data = component.data;
        chart.options.scales.x.title.text = component.columnNames[0];
        chart.options.scales.y.title.text = component.columnNames[1];

        // Calculate and add mean, median, and confidence ellipsoid
        const data = component.data;
        const mean = calculateMean(data);
        const median = calculateMedian(data);
        const confidenceEllipsoid = calculateConfidenceEllipsoid(data);

        chart.options.plugins.annotation.annotations = [
            {
                type: 'point',
                xValue: mean.x,
                yValue: mean.y,
                backgroundColor: 'rgba(255, 0, 0, 0.6)',
                radius: 5,
                label: {
                    enabled: true,
                    content: 'Mean'
                }
            },
            {
                type: 'point',
                xValue: median.x,
                yValue: median.y,
                backgroundColor: 'rgba(0, 0, 255, 0.6)',
                radius: 5,
                label: {
                    enabled: true,
                    content: 'Median'
                }
            },
            {
                type: 'ellipse',
                xValue: confidenceEllipsoid.x,
                yValue: confidenceEllipsoid.y,
                width: confidenceEllipsoid.width,
                height: confidenceEllipsoid.height,
                borderColor: 'rgba(0, 255, 0, 0.6)',
                borderWidth: 2,
                label: {
                    enabled: true,
                    content: 'Confidence Ellipsoid'
                }
            }
        ];

        chart.update();
    });
}
eel.expose(updateComponents);

function calculateMean(data) {
    const mean = { x: 0, y: 0 };
    data.forEach(point => {
        mean.x += point.x;
        mean.y += point.y;
    });
    mean.x /= data.length;
    mean.y /= data.length;
    return mean;
}

function calculateMedian(data) {
    const sortedX = data.map(p => p.x).sort((a, b) => a - b);
    const sortedY = data.map(p => p.y).sort((a, b) => a - b);
    const median = {
        x: sortedX[Math.floor(sortedX.length / 2)],
        y: sortedY[Math.floor(sortedY.length / 2)]
    };
    return median;
}

function calculateConfidenceEllipsoid(data) {
    // Placeholder: Replace this with actual confidence ellipsoid calculation
    // The calculation of a confidence ellipsoid would involve covariance matrix and eigenvalues
    return {
        x: 0.5, // Center of ellipsoid
        y: 0.5,
        width: 0.3, // Width of ellipsoid
        height: 0.2 // Height of ellipsoid
    };
}
