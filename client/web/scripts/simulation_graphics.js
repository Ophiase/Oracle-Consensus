let simulation_charts = []; // Array to hold Chart instances

Chart.defaults.borderColor = '#606060';
Chart.defaults.color = '#000';

initComponents(3);

function initComponents(dimension) {
    simulation_charts = [];
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
                    label: `Prediction ${i*2},${i*2 + 1}`,
                    data: [], // Initial empty data
                    backgroundColor: ['rgba(54, 54, 54, 0.6)'],  // Dark gray background
                    borderColor: 'rgba(34, 34, 34, 0.1)',        // Even darker border
                    borderWidth: 5,
                    pointRadius: 5
                }, {
                    label: "Median",
                    data: [], // Initial empty data
                    backgroundColor: 'rgba(100, 200, 50, 0.6)',  // Dark gray background
                    borderColor: 'rgba(34, 134, 34, 0.2)',        // Even darker border
                    borderWidth: 20,
                    pointRadius: 20
                }, {
                    label: "Mean",
                    data: [], // Initial empty data
                    backgroundColor: 'rgba(100, 54, 200, 0.6)',  // Dark gray background
                    borderColor: 'rgba(34, 34, 34, 0.3)',        // Even darker border
                    borderWidth: 5
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

        simulation_charts.push(chart); // Store each chart instance
    }
}

eel.expose(initComponents)


function updateComponents(components, mean=null, median=null) {
    labels = components[0].data.map((point, i) => {
        return `Oracle ${i}`
    });

    components.forEach((component, index) => {
        const chart = simulation_charts[index];
        // chart.data.datasets[0].label = labels;
        chart.data.datasets[0].data = component.data;
        chart.options.scales.x.title.text = component.columnNames[0];
        chart.options.scales.y.title.text = component.columnNames[1];
    
        chart.data.datasets[0].backgroundColor = component.data.map((point, i) => {
            return point.score > 0.2 ? 'rgba(54, 54, 54, 0.6)' : 'rgba(220, 60, 60)';
        });

        if (median) {
            // console.log("median")
            chart.data.datasets[1].data =[{
                // label: "Median",
                x: median[2*index],
                y: median[2*index + 1],
                // r: 10,
                // backgroundColor: 'green'
            }];
        }    

        if (mean) {
            // console.log("mean")
            chart.data.datasets[2].data = [{
                // label: "Mean",
                x: mean[2*index],
                y: mean[2*index + 1],
                // r: 10,
                // backgroundColor: 'violet'
            }];
        }
    
        chart.update();
    });

    // // Calculate and add mean, median, and confidence ellipsoid
    // const data = component.data;
    // const mean = calculateMean(data);
    // const median = calculateMedian(data);
    // const confidenceEllipsoid = calculateConfidenceEllipsoid(data);

    // chart.options.plugins.annotation.annotations = [
    //     {
    //         type: 'point',
    //         xValue: mean.x,
    //         yValue: mean.y,
    //         backgroundColor: 'rgba(255, 0, 0, 0.6)',
    //         radius: 5,
    //         label: {
    //             enabled: true,
    //             content: 'Mean'
    //         }
    //     },
    //     {
    //         type: 'point',
    //         xValue: median.x,
    //         yValue: median.y,
    //         backgroundColor: 'rgba(0, 0, 255, 0.6)',
    //         radius: 5,
    //         label: {
    //             enabled: true,
    //             content: 'Median'
    //         }
    //     },
    //     {
    //         type: 'ellipse',
    //         xValue: confidenceEllipsoid.x,
    //         yValue: confidenceEllipsoid.y,
    //         width: confidenceEllipsoid.width,
    //         height: confidenceEllipsoid.height,
    //         borderColor: 'rgba(0, 255, 0, 0.6)',
    //         borderWidth: 2,
    //         label: {
    //             enabled: true,
    //             content: 'Confidence Ellipsoid'
    //         }
    //     }
    // ];
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
