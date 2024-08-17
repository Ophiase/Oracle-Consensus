let simulation_charts = [];

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
}
eel.expose(updateComponents);
