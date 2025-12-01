// payments.js
import { modal } from '../utils/modal.js';
import { notifications } from '../utils/notifications.js';
import { chartsSystem } from '../utils/charts.js';

class PaymentsManager {
    constructor() {
        this.payments = new Map();
        this.initializeEventListeners();
    }

    initializeEventListeners() {
        // زر إضافة دفعة جديدة
        const addPaymentBtn = document.querySelector('.add-payment-btn');
        if (addPaymentBtn) {
            addPaymentBtn.addEventListener('click', () => this.showAddPaymentModal());
        }

        // فلتر المدفوعات
        const filterSelect = document.querySelector('.payments-filter');
        if (filterSelect) {
            filterSelect.addEventListener('change', (e) => 
                this.filterPayments(e.target.value));
        }

        // البحث في المدفوعات
        const searchInput = document.querySelector('.payments-search');
        if (searchInput) {
            searchInput.addEventListener('input', this.debounce((e) => 
                this.searchPayments(e.target.value), 300));
        }

        // تحديث تلقائي للمخططات
        setInterval(() => this.updatePaymentsCharts(), 300000); // كل 5 دقائق
    }

    showAddPaymentModal() {
        modal.showForm({
            title: 'تسجيل دفعة جديدة',
            fields: [
                {
                    type: 'select',
                    name: 'propertyId',
                    label: 'العقار',
                    required: true,
                    options: this.getAvailableProperties()
                },
                {
                    type: 'select',
                    name: 'tenantId',
                    label: 'المستأجر',
                    required: true,
                    options: this.getAvailableTenants()
                },
                {
                    type: 'number',
                    name: 'amount',
                    label: 'المبلغ (ج.م)',
                    required: true
                },
                {
                    type: 'select',
                    name: 'paymentType',
                    label: 'نوع الدفعة',
                    required: true,
                    options: [
                        { value: 'rent', label: 'إيجار شهري' },
                        { value: 'deposit', label: 'تأمين' },
                        { value: 'maintenance', label: 'صيانة' },
                        { value: 'utilities', label: 'مرافق' },
                        { value: 'other', label: 'أخرى' }
                    ]
                },
                {
                    type: 'select',
                    name: 'paymentMethod',
                    label: 'طريقة الدفع',
                    required: true,
                    options: [
                        { value: 'cash', label: 'نقداً' },
                        { value: 'bank_transfer', label: 'تحويل بنكي' },
                        { value: 'credit_card', label: 'بطاقة ائتمان' },
                        { value: 'cheque', label: 'شيك' }
                    ]
                },
                {
                    type: 'date',
                    name: 'paymentDate',
                    label: 'تاريخ الدفع',
                    required: true
                },
                {
                    type: 'textarea',
                    name: 'notes',
                    label: 'ملاحظات',
                    rows: 3
                }
            ],
            onSubmit: (data) => this.recordPayment(data)
        });
    }

    async recordPayment(data) {
        try {
            await this.simulateApiRequest();
            const paymentId = Date.now();
            
            this.payments.set(paymentId, {
                id: paymentId,
                ...data,
                status: 'completed',
                createdAt: new Date().toISOString(),
                receiptNumber: this.generateReceiptNumber()
            });

            notifications.success('تم تسجيل الدفعة بنجاح');
            this.refreshPaymentsList();
            this.updatePaymentsCharts();
            this.printReceipt(paymentId);
        } catch (error) {
            notifications.error('حدث خطأ أثناء تسجيل الدفعة');
        }
    }

    viewPayment(paymentId) {
        const payment = this.payments.get(paymentId);
        if (!payment) return;

        modal.show({
            title: `تفاصيل الدفعة #${paymentId}`,
            content: `
                <div class="payment-details">
                    <div class="receipt-header">
                        <div class="logo">
                            <i class="fas fa-building"></i>
                            <h2>إيجاري</h2>
                        </div>
                        <div class="receipt-info">
                            <h3>إيصال دفع</h3>
                            <p>رقم: ${payment.receiptNumber}</p>
                            <p>تاريخ: ${new Date(payment.paymentDate).toLocaleDateString('ar-EG')}</p>
                        </div>
                    </div>

                    <div class="receipt-body">
                        <div class="info-section">
                            <h4>معلومات العقار</h4>
                            <dl>
                                <dt>العقار:</dt>
                                <dd>${payment.propertyName}</dd>
                                <dt>المستأجر:</dt>
                                <dd>${payment.tenantName}</dd>
                            </dl>
                        </div>

                        <div class="info-section">
                            <h4>تفاصيل الدفعة</h4>
                            <dl>
                                <dt>المبلغ:</dt>
                                <dd>${payment.amount} ج.م</dd>
                                <dt>نوع الدفعة:</dt>
                                <dd>${this.getPaymentTypeLabel(payment.paymentType)}</dd>
                                <dt>طريقة الدفع:</dt>
                                <dd>${this.getPaymentMethodLabel(payment.paymentMethod)}</dd>
                            </dl>
                        </div>

                        ${payment.notes ? `
                            <div class="info-section">
                                <h4>ملاحظات</h4>
                                <p>${payment.notes}</p>
                            </div>
                        ` : ''}
                    </div>
                </div>
            `,
            actions: [
                {
                    text: 'طباعة الإيصال',
                    class: 'btn-primary',
                    onClick: () => this.printReceipt(paymentId)
                },
                {
                    text: 'تحميل PDF',
                    class: 'btn-outline',
                    onClick: () => this.downloadReceipt(paymentId)
                }
            ]
        });
    }

    async printReceipt(paymentId) {
        try {
            const payment = this.payments.get(paymentId);
            if (!payment) return;

            // إنشاء نافذة طباعة جديدة
            const printWindow = window.open('', '_blank');
            printWindow.document.write(`
                <html dir="rtl">
                <head>
                    <title>إيصال دفع #${payment.receiptNumber}</title>
                    <style>
                        /* أنماط الطباعة */
                        body {
                            font-family: Arial, sans-serif;
                            padding: 20px;
                            direction: rtl;
                        }
                        .receipt {
                            border: 1px solid #ccc;
                            padding: 20px;
                            max-width: 800px;
                            margin: 0 auto;
                        }
                        .header {
                            text-align: center;
                            border-bottom: 2px solid #eee;
                            padding-bottom: 20px;
                            margin-bottom: 20px;
                        }
                        .details {
                            margin-bottom: 20px;
                        }
                        .footer {
                            text-align: center;
                            margin-top: 40px;
                            border-top: 1px solid #eee;
                            padding-top: 20px;
                        }
                    </style>
                </head>
                <body>
                    <div class="receipt">
                        <div class="header">
                            <h1>إيصال دفع</h1>
                            <p>رقم: ${payment.receiptNumber}</p>
                            <p>تاريخ: ${new Date(payment.paymentDate).toLocaleDateString('ar-EG')}</p>
                        </div>
                        <div class="details">
                            <h3>تفاصيل الدفعة</h3>
                            <p>المبلغ: ${payment.amount} ج.م</p>
                            <p>نوع الدفعة: ${this.getPaymentTypeLabel(payment.paymentType)}</p>
                            <p>طريقة الدفع: ${this.getPaymentMethodLabel(payment.paymentMethod)}</p>
                            <p>العقار: ${payment.propertyName}</p>
                            <p>المستأجر: ${payment.tenantName}</p>
                            ${payment.notes ? `<p>ملاحظات: ${payment.notes}</p>` : ''}
                        </div>
                        <div class="footer">
                            <p>شكراً لك</p>
                            <p>تم إصدار هذا الإيصال بواسطة نظام إيجاري</p>
                        </div>
                    </div>
                </body>
                </html>
            `);
            
            printWindow.document.close();
            printWindow.print();
        } catch (error) {
            notifications.error('حدث خطأ أثناء طباعة الإيصال');
        }
    }

    generateReceiptNumber() {
        const date = new Date();
        const year = date.getFullYear().toString().slice(-2);
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
        return `RCP-${year}${month}-${random}`;
    }

    getPaymentTypeLabel(type) {
        const labels = {
            rent: 'إيجار شهري',
            deposit: 'تأمين',
            maintenance: 'صيانة',
            utilities: 'مرافق',
            other: 'أخرى'
        };
        return labels[type] || type;
    }

    getPaymentMethodLabel(method) {
        const labels = {
            cash: 'نقداً',
            bank_transfer: 'تحويل بنكي',
            credit_card: 'بطاقة ائتمان',
            cheque: 'شيك'
        };
        return labels[method] || method;
    }

    updatePaymentsCharts() {
        // تحديث مخطط المدفوعات الشهرية
        const monthlyData = this.calculateMonthlyPayments();
        chartsSystem.updateChartData('monthly-payments', monthlyData);

        // تحديث مخطط توزيع المدفوعات حسب النوع
        const typeData = this.calculatePaymentsByType();
        chartsSystem.updateChartData('payments-by-type', typeData);
    }

    calculateMonthlyPayments() {
        // حساب إجمالي المدفوعات لكل شهر
        const monthlyTotals = {};
        this.payments.forEach(payment => {
            const date = new Date(payment.paymentDate);
            const monthKey = `${date.getFullYear()}-${date.getMonth() + 1}`;
            monthlyTotals[monthKey] = (monthlyTotals[monthKey] || 0) + payment.amount;
        });

        return Object.entries(monthlyTotals).map(([month, total]) => ({
            month,
            amount: total
        }));
    }

    calculatePaymentsByType() {
        // حساب إجمالي المدفوعات لكل نوع
        const typeTotals = {};
        this.payments.forEach(payment => {
            typeTotals[payment.paymentType] = 
                (typeTotals[payment.paymentType] || 0) + payment.amount;
        });

        return Object.entries(typeTotals).map(([type, total]) => ({
            type: this.getPaymentTypeLabel(type),
            amount: total
        }));
    }

    // دوال مساعدة
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    async simulateApiRequest() {
        return new Promise(resolve => setTimeout(resolve, 1000));
    }

    getAvailableProperties() {
        return [
            { value: '1', label: 'شقة المعادي' },
            { value: '2', label: 'فيلا التجمع' }
        ];
    }

    getAvailableTenants() {
        return [
            { value: '1', label: 'أحمد محمود' },
            { value: '2', label: 'سارة أحمد' }
        ];
    }
}

// تصدير مدير المدفوعات
export const paymentsManager = new PaymentsManager();
