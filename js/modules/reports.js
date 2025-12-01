// reports.js
import { modal } from '../utils/modal.js';
import { notifications } from '../utils/notifications.js';
import { chartsSystem } from '../utils/charts.js';

class ReportsManager {
    constructor() {
        this.initializeEventListeners();
        this.initializeCharts();
    }

    initializeEventListeners() {
        // تحديد نطاق التقرير
        const dateRange = document.querySelector('.report-date-range');
        if (dateRange) {
            dateRange.addEventListener('change', (e) => 
                this.updateReportRange(e.target.value));
        }

        // تصدير التقارير
        const exportBtns = document.querySelectorAll('.export-report-btn');
        exportBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const reportType = e.target.dataset.reportType;
                this.exportReport(reportType);
            });
        });
    }

    async generateReport(type, filters = {}) {
        try {
            notifications.info('جاري توليد التقرير...');
            await this.simulateApiRequest();

            const reportData = await this.getReportData(type, filters);
            this.displayReport(type, reportData);
            
            notifications.success('تم توليد التقرير بنجاح');
        } catch (error) {
            notifications.error('حدث خطأ أثناء توليد التقرير');
        }
    }

    async getReportData(type, filters) {
        // محاكاة جلب البيانات من الخادم
        switch (type) {
            case 'financial':
                return this.generateFinancialReport(filters);
            case 'occupancy':
                return this.generateOccupancyReport(filters);
            case 'maintenance':
                return this.generateMaintenanceReport(filters);
            case 'tenants':
                return this.generateTenantsReport(filters);
            default:
                throw new Error('نوع تقرير غير معروف');
        }
    }

    displayReport(type, data) {
        const container = document.querySelector('.report-content');
        if (!container) return;

        container.innerHTML = this.getReportTemplate(type, data);
        this.updateReportCharts(type, data);
    }

    getReportTemplate(type, data) {
        switch (type) {
            case 'financial':
                return this.getFinancialReportTemplate(data);
            case 'occupancy':
                return this.getOccupancyReportTemplate(data);
            case 'maintenance':
                return this.getMaintenanceReportTemplate(data);
            case 'tenants':
                return this.getTenantsReportTemplate(data);
            default:
                return '<p>نوع تقرير غير معروف</p>';
        }
    }

    getFinancialReportTemplate(data) {
        return `
            <div class="report-section">
                <h2>التقرير المالي</h2>
                <div class="report-period">
                    <span>الفترة: ${data.startDate} - ${data.endDate}</span>
                </div>

                <div class="financial-summary">
                    <div class="stat-cards">
                        <div class="stat-card">
                            <div class="stat-value">${data.totalIncome.toLocaleString()} ج.م</div>
                            <div class="stat-label">إجمالي الدخل</div>
                            <div class="stat-change ${data.incomeChange >= 0 ? 'positive' : 'negative'}">
                                <i class="fas fa-${data.incomeChange >= 0 ? 'arrow-up' : 'arrow-down'}"></i>
                                ${Math.abs(data.incomeChange)}%
                            </div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-value">${data.totalExpenses.toLocaleString()} ج.م</div>
                            <div class="stat-label">إجمالي المصروفات</div>
                            <div class="stat-change ${data.expensesChange <= 0 ? 'positive' : 'negative'}">
                                <i class="fas fa-${data.expensesChange <= 0 ? 'arrow-down' : 'arrow-up'}"></i>
                                ${Math.abs(data.expensesChange)}%
                            </div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-value">${data.netIncome.toLocaleString()} ج.م</div>
                            <div class="stat-label">صافي الدخل</div>
                            <div class="stat-change ${data.netIncomeChange >= 0 ? 'positive' : 'negative'}">
                                <i class="fas fa-${data.netIncomeChange >= 0 ? 'arrow-up' : 'arrow-down'}"></i>
                                ${Math.abs(data.netIncomeChange)}%
                            </div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-value">${data.collectionRate}%</div>
                            <div class="stat-label">معدل التحصيل</div>
                            <div class="stat-change ${data.collectionRateChange >= 0 ? 'positive' : 'negative'}">
                                <i class="fas fa-${data.collectionRateChange >= 0 ? 'arrow-up' : 'arrow-down'}"></i>
                                ${Math.abs(data.collectionRateChange)}%
                            </div>
                        </div>
                    </div>

                    <div class="charts-container">
                        <div class="chart-wrapper">
                            <h3>تحليل الدخل الشهري</h3>
                            <canvas id="monthlyIncomeChart"></canvas>
                        </div>

                        <div class="chart-wrapper">
                            <h3>توزيع المصروفات</h3>
                            <canvas id="expensesDistributionChart"></canvas>
                        </div>
                    </div>

                    <div class="data-tables">
                        <div class="table-wrapper">
                            <h3>المدفوعات المتأخرة</h3>
                            <table class="report-table">
                                <thead>
                                    <tr>
                                        <th>العقار</th>
                                        <th>المستأجر</th>
                                        <th>المبلغ</th>
                                        <th>تاريخ الاستحقاق</th>
                                        <th>التأخير</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${data.latePayments.map(payment => `
                                        <tr>
                                            <td>${payment.property}</td>
                                            <td>${payment.tenant}</td>
                                            <td>${payment.amount.toLocaleString()} ج.م</td>
                                            <td>${payment.dueDate}</td>
                                            <td>${payment.daysLate} يوم</td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    getOccupancyReportTemplate(data) {
        return `
            <div class="report-section">
                <h2>تقرير الإشغال</h2>
                
                <div class="occupancy-summary">
                    <div class="stat-cards">
                        <div class="stat-card">
                            <div class="stat-value">${data.occupancyRate}%</div>
                            <div class="stat-label">معدل الإشغال</div>
                        </div>
                        
                        <div class="stat-card">
                            <div class="stat-value">${data.rentedUnits}/${data.totalUnits}</div>
                            <div class="stat-label">الوحدات المؤجرة</div>
                        </div>
                        
                        <div class="stat-card">
                            <div class="stat-value">${data.averageRentDuration}</div>
                            <div class="stat-label">متوسط مدة الإيجار</div>
                        </div>
                        
                        <div class="stat-card">
                            <div class="stat-value">${data.turnoverRate}%</div>
                            <div class="stat-label">معدل تغيير المستأجرين</div>
                        </div>
                    </div>

                    <div class="charts-container">
                        <div class="chart-wrapper">
                            <h3>توزيع حالات العقارات</h3>
                            <canvas id="propertyStatusChart"></canvas>
                        </div>
                        
                        <div class="chart-wrapper">
                            <h3>معدل الإشغال الشهري</h3>
                            <canvas id="monthlyOccupancyChart"></canvas>
                        </div>
                    </div>

                    <div class="property-list">
                        <h3>تفاصيل العقارات</h3>
                        <table class="report-table">
                            <thead>
                                <tr>
                                    <th>العقار</th>
                                    <th>الحالة</th>
                                    <th>المستأجر</th>
                                    <th>تاريخ البداية</th>
                                    <th>تاريخ النهاية</th>
                                    <th>الإيجار الشهري</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${data.properties.map(prop => `
                                    <tr>
                                        <td>${prop.name}</td>
                                        <td>
                                            <span class="status-badge ${prop.status}">
                                                ${this.getStatusLabel(prop.status)}
                                            </span>
                                        </td>
                                        <td>${prop.tenant || '-'}</td>
                                        <td>${prop.startDate || '-'}</td>
                                        <td>${prop.endDate || '-'}</td>
                                        <td>${prop.monthlyRent?.toLocaleString() || '-'} ج.م</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;
    }

    getMaintenanceReportTemplate(data) {
        return `
            <div class="report-section">
                <h2>تقرير الصيانة</h2>

                <div class="maintenance-summary">
                    <div class="stat-cards">
                        <div class="stat-card">
                            <div class="stat-value">${data.totalRequests}</div>
                            <div class="stat-label">إجمالي الطلبات</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-value">${data.averageResponseTime}</div>
                            <div class="stat-label">متوسط وقت الاستجابة</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-value">${data.totalCost.toLocaleString()} ج.م</div>
                            <div class="stat-label">تكلفة الصيانة</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-value">${data.completionRate}%</div>
                            <div class="stat-label">معدل الإنجاز</div>
                        </div>
                    </div>

                    <div class="charts-container">
                        <div class="chart-wrapper">
                            <h3>توزيع طلبات الصيانة</h3>
                            <canvas id="maintenanceTypeChart"></canvas>
                        </div>

                        <div class="chart-wrapper">
                            <h3>حالة الطلبات</h3>
                            <canvas id="maintenanceStatusChart"></canvas>
                        </div>
                    </div>

                    <div class="maintenance-details">
                        <h3>تفاصيل طلبات الصيانة</h3>
                        <table class="report-table">
                            <thead>
                                <tr>
                                    <th>رقم الطلب</th>
                                    <th>العقار</th>
                                    <th>نوع المشكلة</th>
                                    <th>الحالة</th>
                                    <th>تاريخ الطلب</th>
                                    <th>وقت الاستجابة</th>
                                    <th>التكلفة</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${data.requests.map(request => `
                                    <tr>
                                        <td>#${request.id}</td>
                                        <td>${request.property}</td>
                                        <td>${this.getMaintenanceTypeLabel(request.type)}</td>
                                        <td>
                                            <span class="status-badge ${request.status}">
                                                ${this.getMaintenanceStatusLabel(request.status)}
                                            </span>
                                        </td>
                                        <td>${request.requestDate}</td>
                                        <td>${request.responseTime}</td>
                                        <td>${request.cost?.toLocaleString() || '-'} ج.م</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;
    }

    getTenantsReportTemplate(data) {
        return `
            <div class="report-section">
                <h2>تقرير المستأجرين</h2>

                <div class="tenants-summary">
                    <div class="stat-cards">
                        <div class="stat-card">
                            <div class="stat-value">${data.totalTenants}</div>
                            <div class="stat-label">إجمالي المستأجرين</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-value">${data.averageTenancy}</div>
                            <div class="stat-label">متوسط مدة الإقامة</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-value">${data.renewalRate}%</div>
                            <div class="stat-label">معدل التجديد</div>
                        </div>

                        <div class="stat-card">
                            <div class="stat-value">${data.satisfactionRate}%</div>
                            <div class="stat-label">معدل الرضا</div>
                        </div>
                    </div>

                    <div class="charts-container">
                        <div class="chart-wrapper">
                            <h3>توزيع مدد الإيجار</h3>
                            <canvas id="tenancyDurationChart"></canvas>
                        </div>

                        <div class="chart-wrapper">
                            <h3>تحليل المدفوعات</h3>
                            <canvas id="paymentAnalysisChart"></canvas>
                        </div>
                    </div>

                    <div class="tenants-details">
                        <h3>تفاصيل المستأجرين</h3>
                        <table class="report-table">
                            <thead>
                                <tr>
                                    <th>المستأجر</th>
                                    <th>العقار</th>
                                    <th>تاريخ البداية</th>
                                    <th>تاريخ النهاية</th>
                                    <th>الإيجار الشهري</th>
                                    <th>حالة المدفوعات</th>
                                    <th>معدل الالتزام</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${data.tenants.map(tenant => `
                                    <tr>
                                        <td>${tenant.name}</td>
                                        <td>${tenant.property}</td>
                                        <td>${tenant.startDate}</td>
                                        <td>${tenant.endDate}</td>
                                        <td>${tenant.monthlyRent.toLocaleString()} ج.م</td>
                                        <td>
                                            <span class="status-badge ${tenant.paymentStatus}">
                                                ${this.getPaymentStatusLabel(tenant.paymentStatus)}
                                            </span>
                                        </td>
                                        <td>
                                            <div class="compliance-rate">
                                                <div class="progress-bar" style="width: ${tenant.complianceRate}%"></div>
                                                <span>${tenant.complianceRate}%</span>
                                            </div>
                                        </td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;
    }

    exportReport(type, format = 'pdf') {
        notifications.info('جاري تصدير التقرير...');
        
        setTimeout(() => {
            const fileName = `report-${type}-${new Date().toISOString().split('T')[0]}.${format}`;
            notifications.success(`تم تصدير التقرير: ${fileName}`);
        }, 2000);
    }

    initializeCharts() {
        // المخططات المالية
        this.initializeFinancialCharts();
        // مخططات الإشغال
        this.initializeOccupancyCharts();
        // مخططات الصيانة
        this.initializeMaintenanceCharts();
        // مخططات المستأجرين
        this.initializeTenantsCharts();
    }

    updateReportRange(range) {
        const dates = this.calculateDateRange(range);
        this.refreshAllReports(dates.startDate, dates.endDate);
    }

    calculateDateRange(range) {
        const now = new Date();
        const startDate = new Date();

        switch (range) {
            case 'week':
                startDate.setDate(now.getDate() - 7);
                break;
            case 'month':
                startDate.setMonth(now.getMonth() - 1);
                break;
            case 'quarter':
                startDate.setMonth(now.getMonth() - 3);
                break;
            case 'year':
                startDate.setFullYear(now.getFullYear() - 1);
                break;
            default:
                startDate.setMonth(now.getMonth() - 1); // الافتراضي: شهر
        }

        return {
            startDate,
            endDate: now
        };
    }

    refreshAllReports(startDate, endDate) {
        this.generateReport('financial', { startDate, endDate });
        this.generateReport('occupancy', { startDate, endDate });
        this.generateReport('maintenance', { startDate, endDate });
        this.generateReport('tenants', { startDate, endDate });
    }

    // دوال مساعدة للعلامات والتسميات
    getStatusLabel(status) {
        const labels = {
            occupied: 'مؤجر',
            vacant: 'متاح',
            maintenance: 'تحت الصيانة',
            reserved: 'محجوز'
        };
        return labels[status] || status;
    }

    getMaintenanceTypeLabel(type) {
        const labels = {
            plumbing: 'سباكة',
            electrical: 'كهرباء',
            ac: 'تكييف',
            carpentry: 'نجارة',
            painting: 'دهان',
            other: 'أخرى'
        };
        return labels[type] || type;
    }

    getMaintenanceStatusLabel(status) {
        const labels = {
            pending: 'قيد الانتظار',
            in_progress: 'جاري العمل',
            completed: 'مكتمل',
            cancelled: 'ملغي'
        };
        return labels[status] || status;
    }

    getPaymentStatusLabel(status) {
        const labels = {
            paid: 'مدفوع',
            partial: 'مدفوع جزئياً',
            pending: 'قيد الانتظار',
            late: 'متأخر'
        };
        return labels[status] || status;
    }

    async generateFinancialReport(filters) {
        // محاكاة جلب بيانات التقرير المالي
        await this.simulateApiRequest();
        return {
            startDate: filters.startDate,
            endDate: filters.endDate,
            totalIncome: 150000,
            totalExpenses: 45000,
            netIncome: 105000,
            incomeChange: 15,
            expensesChange: -5,
            netIncomeChange: 20,
            collectionRate: 92,
            collectionRateChange: 3,
            monthlyData: [
                { month: 'يناير', income: 45000, expenses: 15000 },
                { month: 'فبراير', income: 48000, expenses: 14000 },
                // ... المزيد من البيانات الشهرية
            ],
            latePayments: [
                {
                    property: 'شقة المعادي',
                    tenant: 'أحمد محمود',
                    amount: 12000,
                    dueDate: '2024-01-15',
                    daysLate: 5
                }
                // ... المزيد من المدفوعات المتأخرة
            ]
        };
    }

    async simulateApiRequest() {
        return new Promise(resolve => setTimeout(resolve, 1000));
    }
}

// تصدير مدير التقارير
export const reportsManager = new ReportsManager();