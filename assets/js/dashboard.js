let activityChart, materialChart;

async function loadDashboardData() {
    try {
        // Load user stats
        const statsResponse = await fetch('/api/user/stats.php', { credentials: 'include' });
        const stats = await statsResponse.json();
        
        // Load recent activity
        const activityResponse = await fetch('/api/user/activity.php', { credentials: 'include' });
        const activity = await activityResponse.json();
        
        // Load chart data
        const chartResponse = await fetch('/api/user/charts.php', { credentials: 'include' });
        const chartData = await chartResponse.json();
        
        updateDashboardUI(stats, activity, chartData);
    } catch (error) {
        console.error("Failed to load dashboard data:", error);
    }
}

function updateDashboardUI(stats, activity, chartData) {
    // Update stats
    document.getElementById('total-points').textContent = stats.total_points;
    document.getElementById('total-items').textContent = stats.total_items;
    document.getElementById('co2-saved').textContent = `${stats.co2_saved} kg`;
    
    // Update trends
    document.getElementById('points-trend').textContent = stats.points_trend >= 0 ? 
        `+${stats.points_trend}%` : `${stats.points_trend}%`;
    document.getElementById('points-trend').className = stats.points_trend >= 0 ? 'positive' : 'negative';
    
    document.getElementById('items-trend').textContent = stats.items_trend >= 0 ? 
        `+${stats.items_trend}%` : `${stats.items_trend}%`;
    document.getElementById('items-trend').className = stats.items_trend >= 0 ? 'positive' : 'negative';
    
    // Update activity table
    const activityList = document.getElementById('activity-list');
    activityList.innerHTML = activity.map(item => `
        <tr>
            <td>${new Date(item.scan_time).toLocaleDateString()}</td>
            <td>${item.barcode}</td>
            <td><span class="badge bg-${getMaterialClass(item.material_type)}">${item.material_type}</span></td>
            <td>+${item.points_awarded}</td>
        </tr>
    `).join('');
    
    // Update charts
    updateCharts(chartData);
}

function updateCharts(chartData) {
    // Destroy existing charts if they exist
    if (activityChart) activityChart.destroy();
    if (materialChart) materialChart.destroy();
    
    // Activity chart (line chart)
    const activityCtx = document.getElementById('activity-chart').getContext('2d');
    activityChart = new Chart(activityCtx, {
        type: 'line',
        data: {
            labels: chartData.activity.labels,
            datasets: [{
                label: 'Points Earned',
                data: chartData.activity.data,
                backgroundColor: 'rgba(46, 204, 113, 0.2)',
                borderColor: 'rgba(46, 204, 113, 1)',
                borderWidth: 2,
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });
    
    // Material chart (doughnut chart)
    const materialCtx = document.getElementById('material-chart').getContext('2d');
    materialChart = new Chart(materialCtx, {
        type: 'doughnut',
        data: {
            labels: chartData.materials.labels,
            datasets: [{
                data: chartData.materials.data,
                backgroundColor: [
                    'rgba(54, 162, 235, 0.7)',
                    'rgba(255, 99, 132, 0.7)',
                    'rgba(255, 206, 86, 0.7)'
                ],
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    });
}

function getMaterialClass(material) {
    const classes = {
        'plastic': 'primary',
        'glass': 'info',
        'aluminum': 'warning'
    };
    return classes[material] || 'secondary';
}

// Global function to update dashboard
window.updateDashboard = loadDashboardData;

// Initialize dashboard when page loads
document.addEventListener('DOMContentLoaded', loadDashboardData);
