let chartInstances = []; // Array to hold Chart instances

function initComponents(dimension) {
    const container = document.getElementById('plots-container');
    container.innerHTML = ''; 

    // Initialize Chart instances and store them
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
                    backgroundColor: 'rgba(75, 192, 192, 0.6)',
                    borderColor: 'rgba(75, 192, 192, 1)',
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
                }
            }
        });

        chartInstances.push(chart); // Store each chart instance
    }
}
eel.expose(initComponents);

function updateComponents(components) {
    components.forEach((component, index) => {
        // Update dataset for each chart instance
        chartInstances[index].data.datasets[0].label = `Component ${index + 1}`;
        chartInstances[index].data.datasets[0].data = component.data;
        chartInstances[index].options.scales.x.title.text = component.columnNames[0];
        chartInstances[index].options.scales.y.title.text = component.columnNames[1];
        chartInstances[index].update(); // Update the chart
    });
}
eel.expose(updateComponents);
