class ChartsSystem {
    constructor() {
        this.charts = new Map();
        this.colors = {
            primary: '#2563eb',
            success: '#10b981',
            warning: '#f59e0b',
            danger: '#ef4444',
            info: '#3b82f6'
        };
    }

    initialize() {
        this.initializeIncomeChart();
        this.initializeOccupancyChart();
        this.initializeMaintenanceChart();
        this.initializePaymentsChart();
        this.setupChartUpdates();
    }

    initializeIncomeChart() {
        const ctx = document.getElementById('incomeChart');
        if (!ctx) return;

        const chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: this.getLastSixMonths(),
                datasets: [{
                    label: 'الدخل الشهري',
                    data: [45000, 48000, 42000, 50000, 55000, 53000],
                    borderColor: this.colors.primary,
                    tension: 0.4,
                    fill: true,
                    backgroundColor: `${this.colors.primary}20`
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                        rtl: true
                    },
                    tooltip: {
                        rtl: true,
                        callbacks: {
                            label: function(context) {
                                return `${context.parsed.y} ج.م`;
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: value => `${value} ج.م`
                        }
                    }
                }
            }
        });

        this.charts.set('income', chart);
    }

    initializeOccupancyChart() {
        const ctx = document.getElementById('occupancyChart');
        if (!ctx) return;

        const chart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['مؤجر', 'متاح', 'تحت الصيانة'],
                datasets: [{
                    data: [8, 3, 1],
                    backgroundColor: [
                        this.colors.success,
                        this.colors.info,
                        this.colors.warning
                    ]
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'bottom',
                        rtl: true
                    }
                },
                cutout: '70%'
            }
        });

        this.charts.set('occupancy', chart);
    }

    initializeMaintenanceChart() {
        const ctx = document.getElementById('maintenanceChart');
        if (!ctx) return;

        const chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: this.getLastSixMonths(),
                datasets: [{
                    label: 'طلبات الصيانة',
                    data: [5, 7, 4, 6, 8, 3],
                    backgroundColor: this.colors.warning
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                        rtl: true
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            stepSize: 1
                        }
                    }
                }
            }
        });

        this.charts.set('maintenance', chart);
    }

    initializePaymentsChart() {
        const ctx = document.getElementById('paymentsChart');
        if (!ctx) return;

        const chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: this.getLastSixMonths(),
                datasets: [
                    {
                        label: 'المدفوعات المستلمة',
                        data: [42000, 45000, 40000, 48000, 52000, 50000],
                        backgroundColor: this.colors.success
                    },
                    {
                        label: 'المدفوعات المستحقة',
                        data: [45000, 48000, 42000, 50000, 55000, 53000],
                        backgroundColor: this.colors.warning
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                        rtl: true
                    },
                    tooltip: {
                        rtl: true,
                        callbacks: {
                            label: function(context) {
                                return `${context.parsed.y} ج.م`;
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: value => `${value} ج.م`
                        }
                    }
                }
            }
        });

        this.charts.set('payments', chart);
    }

    updateChartData(chartId, newData, labels = null) {
        const chart = this.charts.get(chartId);
        if (!chart) return;

        if (labels) {
            chart.data.labels = labels;
        }
        
        if (Array.isArray(newData)) {
            chart.data.datasets[0].data = newData;
        } else {
            chart.data.datasets = newData;
        }
        
        chart.update();
    }

    getLastSixMonths() {
        const months = ['يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو', 
                       'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
        const result = [];
        const currentDate = new Date();
        
        for (let i = 5; i >= 0; i--) {
            const d = new Date(currentDate);
            d.setMonth(d.getMonth() - i);
            result.push(months[d.getMonth()]);
        }
        
        return result;
    }

    setupChartUpdates() {
        // تحديث المخططات كل دقيقة
        setInterval(() => {
            this.updateAllCharts();
        }, 60000);
    }

    updateAllCharts() {
        // تحديث مخطط الدخل
        this.updateIncomeChart();
        // تحديث مخطط الإشغال
        this.updateOccupancyChart();
        // تحديث مخطط الصيانة
        this.updateMaintenanceChart();
        // تحديث مخطط المدفوعات
        this.updatePaymentsChart();
    }

    // تحديث مخطط الدخل
    updateIncomeChart() {
        const newData = this.generateRandomData(6, 40000, 60000);
        this.updateChartData('income', newData);
    }

    // تحديث مخطط الإشغال
    updateOccupancyChart() {
        const newData = [
            Math.floor(Math.random() * 3) + 7, // مؤجر
            Math.floor(Math.random() * 2) + 2, // متاح
            Math.floor(Math.random() * 2)      // تحت الصيانة
        ];
        this.updateChartData('occupancy', newData);
    }

    // تحديث مخطط الصيانة
    updateMaintenanceChart() {
        const newData = this.generateRandomData(6, 2, 10);
        this.updateChartData('maintenance', newData);
    }

    // تحديث مخطط المدفوعات
    updatePaymentsChart() {
        const received = this.generateRandomData(6, 40000, 55000);
        const due = this.generateRandomData(6, 42000, 58000);
        
        const newData = [
            {
                label: 'المدفوعات المستلمة',
                data: received,
                backgroundColor: this.colors.success
            },
            {
                label: 'المدفوعات المستحقة',
                data: due,
                backgroundColor: this.colors.warning
            }
        ];
        
        this.updateChartData('payments', newData);
    }

    generateRandomData(count, min, max) {
        return Array.from({ length: count }, () => 
            Math.floor(Math.random() * (max - min + 1)) + min
        );
    }

    // تغيير نطاق المخططات
    changeChartRange(range) {
        const ranges = {
            'daily': 7,
            'weekly': 4,
            'monthly': 6,
            'yearly': 12
        };

        const count = ranges[range] || 6;
        const labels = this.generateLabels(range, count);

        // تحديث جميع المخططات بالنطاق الجديد
        this.charts.forEach((chart, chartId) => {
            const newData = this.generateRandomData(count, 40000, 60000);
            this.updateChartData(chartId, newData, labels);
        });
    }

    generateLabels(range, count) {
        switch(range) {
            case 'daily':
                return Array.from({ length: count }, (_, i) => 
                    new Date(Date.now() - i * 24 * 60 * 60 * 1000)
                        .toLocaleDateString('ar-EG', { weekday: 'long' })
                ).reverse();
            
            case 'weekly':
                return Array.from({ length: count }, (_, i) => 
                    `الأسبوع ${count - i}`
                );
            
            case 'yearly':
                return Array.from({ length: count }, (_, i) => 
                    new Date(new Date().getFullYear(), i, 1)
                        .toLocaleDateString('ar-EG', { month: 'long' })
                );
            
            default:
                return this.getLastSixMonths();
        }
    }
}

// تصدير نظام المخططات
export const chartsSystem = new ChartsSystem();