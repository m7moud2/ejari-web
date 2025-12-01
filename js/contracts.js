// contracts.js
class ContractsManager {
    constructor() {
        this.contracts = new Map();
        this.initializeEventListeners();
        this.loadContracts();
    }

    initializeEventListeners() {
        // البحث
        const searchInput = document.querySelector('.search-box input');
        if (searchInput) {
            searchInput.addEventListener('input', this.debounce((e) => 
                this.searchContracts(e.target.value), 300));
        }

        // التصفية
        document.querySelectorAll('.filter-select').forEach(select => {
            select.addEventListener('change', (e) => {
                const filterType = e.target.dataset.filter;
                const value = e.target.value;
                this.filterContracts(filterType, value);
            });
        });

        // نطاق التاريخ
        const dateInputs = document.querySelectorAll('.date-range input');
        dateInputs.forEach(input => {
            input.addEventListener('change', () => this.filterByDateRange());
        });
    }

    showNewContractModal() {
        const availableProperties = this.getAvailableProperties();
        const availableTenants = this.getAvailableTenants();

        modal.showForm({
            title: 'إضافة عقد جديد',
            size: 'large',
            fields: [
                {
                    type: 'select',
                    name: 'propertyId',
                    label: 'العقار',
                    required: true,
                    options: availableProperties
                },
                {
                    type: 'select',
                    name: 'tenantId',
                    label: 'المستأجر',
                    required: true,
                    options: availableTenants
                },
                {
                    type: 'date',
                    name: 'startDate',
                    label: 'تاريخ بداية العقد',
                    required: true,
                    min: new Date().toISOString().split('T')[0]
                },
                {
                    type: 'select',
                    name: 'duration',
                    label: 'مدة العقد',
                    required: true,
                    options: [
                        { value: '12', label: 'سنة واحدة' },
                        { value: '24', label: 'سنتان' },
                        { value: '36', label: 'ثلاث سنوات' }
                    ]
                },
                {
                    type: 'number',
                    name: 'rentAmount',
                    label: 'قيمة الإيجار الشهري',
                    required: true
                },
                {
                    type: 'number',
                    name: 'deposit',
                    label: 'قيمة التأمين',
                    required: true
                },
                {
                    type: 'select',
                    name: 'paymentMethod',
                    label: 'طريقة الدفع',
                    required: true,
                    options: [
                        { value: 'monthly', label: 'شهري' },
                        { value: 'quarterly', label: 'ربع سنوي' },
                        { value: 'biannual', label: 'نصف سنوي' },
                        { value: 'annual', label: 'سنوي' }
                    ]
                },
                {
                    type: 'select',
                    name: 'utilities',
                    label: 'المرافق',
                    multiple: true,
                    options: [
                        { value: 'electricity', label: 'كهرباء' },
                        { value: 'water', label: 'مياه' },
                        { value: 'gas', label: 'غاز' },
                        { value: 'internet', label: 'إنترنت' }
                    ]
                },
                {
                    type: 'textarea',
                    name: 'terms',
                    label: 'شروط إضافية',
                    rows: 4
                }
            ],
            onSubmit: async (data) => {
                try {
                    await this.createContract(data);
                    notifications.success('تم إنشاء العقد بنجاح');
                    this.refreshContractsList();
                } catch (error) {
                    notifications.error('حدث خطأ أثناء إنشاء العقد');
                }
            }
        });
    }

    async createContract(data) {
        try {
            // محاكاة طلب API
            await this.simulateApiRequest();

            const contractId = `CNT${Date.now()}`;
            const endDate = this.calculateEndDate(data.startDate, parseInt(data.duration));

            const contract = {
                id: contractId,
                ...data,
                status: 'active',
                endDate,
                createdAt: new Date().toISOString(),
                history: [
                    {
                        action: 'created',
                        date: new Date().toISOString(),
                        note: 'تم إنشاء العقد'
                    }
                ]
            };

            this.contracts.set(contractId, contract);
            
            // تحديث حالة العقار
            this.updatePropertyStatus(data.propertyId, 'rented');
            
            return contract;
        } catch (error) {
            throw new Error('فشل إنشاء العقد');
        }
    }

    viewContract(contractId) {
        const contract = this.contracts.get(contractId);
        if (!contract) return;

        modal.show({
            title: `تفاصيل العقد #${contractId}`,
            size: 'large',
            content: `
                <div class="contract-details">
                    <div class="contract-header">
                        <div class="status-badge ${contract.status}">
                            ${this.getStatusLabel(contract.status)}
                        </div>
                        <div class="contract-dates">
                            <span>من: ${new Date(contract.startDate).toLocaleDateString('ar-EG')}</span>
                            <span>إلى: ${new Date(contract.endDate).toLocaleDateString('ar-EG')}</span>
                        </div>
                    </div>

                    <div class="contract-body">
                        <div class="info-section">
                            <h3>معلومات العقار</h3>
                            <div class="property-details">
                                <img src="/api/placeholder/100/100" alt="Property">
                                <div>
                                    <h4>${contract.propertyName}</h4>
                                    <p>${contract.propertyAddress}</p>
                                </div>
                            </div>
                        </div>

                        <div class="info-section">
                            <h3>معلومات المستأجر</h3>
                            <div class="tenant-details">
                                <img src="/api/placeholder/100/100" alt="Tenant">
                                <div>
                                    <h4>${contract.tenantName}</h4>
                                    <p>${contract.tenantPhone}</p>
                                    <p>${contract.tenantEmail}</p>
                                </div>
                            </div>
                        </div>

                        <div class="info-section">
                            <h3>التفاصيل المالية</h3>
                            <div class="financial-details">
                                <div class="detail-item">
                                    <span class="label">الإيجار الشهري</span>
                                    <span class="value">${contract.rentAmount} ج.م</span>
                                </div>
                                <div class="detail-item">
                                    <span class="label">التأمين</span>
                                    <span class="value">${contract.deposit} ج.م</span>
                                </div>
                                <div class="detail-item">
                                    <span class="label">طريقة الدفع</span>
                                    <span class="value">${this.getPaymentMethodLabel(contract.paymentMethod)}</span>
                                </div>
                            </div>
                        </div>

                        <div class="info-section">
                            <h3>المرافق المشمولة</h3>
                            <div class="utilities-list">
                                ${this.renderUtilities(contract.utilities)}
                            </div>
                        </div>

                        ${contract.terms ? `
                            <div class="info-section">
                                <h3>شروط إضافية</h3>
                                <p>${contract.terms}</p>
                            </div>
                        ` : ''}

                        <div class="info-section">
                            <h3>سجل العقد</h3>
                            <div class="contract-history">
                                ${this.renderContractHistory(contract.history)}
                            </div>
                        </div>
                    </div>
                </div>
            `,
            actions: this.getContractActions(contract)
        });
    }

    getContractActions(contract) {
        const actions = [
            {
                text: 'طباعة العقد',
                class: 'btn-outline',
                icon: 'print',
                onClick: () => this.printContract(contract.id)
            }
        ];

        if (contract.status === 'active') {
            actions.unshift({
                text: 'تعديل',
                class: 'btn-primary',
                icon: 'edit',
                onClick: () => this.editContract(contract.id)
            });

            if (this.isContractNearExpiry(contract)) {
                actions.push({
                    text: 'تجديد العقد',
                    class: 'btn-success',
                    icon: 'sync',
                    onClick: () => this.renewContract(contract.id)
                });
            }
        }

        return actions;
    }

    renewContract(contractId) {
        const contract = this.contracts.get(contractId);
        if (!contract) return;

        modal.showForm({
            title: 'تجديد العقد',
            fields: [
                {
                    type: 'number',
                    name: 'newRentAmount',
                    label: 'قيمة الإيجار الجديدة',
                    value: contract.rentAmount,
                    required: true
                },
                {
                    type: 'select',
                    name: 'duration',
                    label: 'مدة التجديد',
                    required: true,
                    options: [
                        { value: '12', label: 'سنة واحدة' },
                        { value: '24', label: 'سنتان' },
                        { value: '36', label: 'ثلاث سنوات' }
                    ]
                },
                {
                    type: 'textarea',
                    name: 'renewalNotes',
                    label: 'ملاحظات التجديد',
                    rows: 3
                }
            ],
            onSubmit: async (data) => {
                try {
                    await this.processContractRenewal(contractId, data);
                    notifications.success('تم تجديد العقد بنجاح');
                    this.refreshContractsList();
                } catch (error) {
                    notifications.error('حدث خطأ أثناء تجديد العقد');
                }
            }
        });
    }

    async processContractRenewal(contractId, renewalData) {
        const contract = this.contracts.get(contractId);
        if (!contract) throw new Error('العقد غير موجود');

        await this.simulateApiRequest();

        const newEndDate = this.calculateEndDate(contract.endDate, parseInt(renewalData.duration));
        
        contract.rentAmount = renewalData.newRentAmount;
        contract.endDate = newEndDate;
        contract.history.push({
            action: 'renewed',
            date: new Date().toISOString(),
            note: `تم تجديد العقد لمدة ${renewalData.duration} شهر بقيمة ${renewalData.newRentAmount} ج.م`
        });

        this.contracts.set(contractId, contract);
    }

    exportContracts() {
        const contracts = Array.from(this.contracts.values());
        const exportData = contracts.map(contract => ({
            'رقم العقد': contract.id,
            'العقار': contract.propertyName,
            'المستأجر': contract.tenantName,
            'تاريخ البداية': new Date(contract.startDate).toLocaleDateString('ar-EG'),
            'تاريخ النهاية': new Date(contract.endDate).toLocaleDateString('ar-EG'),
            'قيمة الإيجار': `${contract.rentAmount} ج.م`,
            'الحالة': this.getStatusLabel(contract.status)
        }));

        this.downloadCSV(exportData, `contracts_${new Date().toISOString()}.csv`);
    }

    // دوال مساعدة
    calculateEndDate(startDate, durationMonths) {
        const date = new Date(startDate);
        date.setMonth(date.getMonth() + durationMonths);
        return date.toISOString();
    }

    isContractNearExpiry(contract) {
        const expiryDate = new Date(contract.endDate);
        const today = new Date();
        const monthsDiff = (expiryDate - today) / (1000 * 60 * 60 * 24 * 30);
        return monthsDiff <= 2;
    }

    getPaymentMethodLabel(method) {
        const labels = {
            monthly: 'شهري',
            quarterly: 'ربع سنوي',
            biannual: 'نصف سنوي',
            annual: 'سنوي'
        };
        return labels[method] || method;
    }

    renderUtilities(utilities) {
        if (!utilities || !utilities.length) return '<p>لا يوجد مرافق مشمولة</p>';

        const labels = {
            electricity: 'كهرباء',
            water: 'مياه',
            gas: 'غاز',
            internet: 'إنترنت'
        };

        return utilities.map(util => `
            <span class="utility-badge">
                <i class="fas fa-check"></i>
                ${labels[util]}
            </span>
        `).join('');
    }

    // تكملة الكلاس السابق
    getActionIcon(action) {
        const icons = {
            created: 'fa-plus-circle',
            renewed: 'fa-sync',
            edited: 'fa-edit',
            terminated: 'fa-times-circle',
            payment: 'fa-money-bill',
            notice: 'fa-exclamation-circle'
        };
        return icons[action] || 'fa-circle';
    }

    async printContract(contractId) {
        const contract = this.contracts.get(contractId);
        if (!contract) return;

        try {
            this.showLoader();
            await this.simulateApiRequest();

            const printWindow = window.open('', '_blank');
            printWindow.document.write(`
                <!DOCTYPE html>
                <html lang="ar" dir="rtl">
                <head>
                    <meta charset="UTF-8">
                    <title>عقد إيجار #${contractId}</title>
                    <style>
                        @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap');
                        
                        body {
                            font-family: 'Cairo', sans-serif;
                            padding: 40px;
                            line-height: 1.6;
                        }
                        
                        .contract-header {
                            text-align: center;
                            margin-bottom: 40px;
                        }
                        
                        .contract-title {
                            font-size: 24px;
                            font-weight: bold;
                            margin-bottom: 10px;
                        }
                        
                        .section {
                            margin-bottom: 30px;
                        }
                        
                        .section-title {
                            font-size: 18px;
                            font-weight: bold;
                            margin-bottom: 15px;
                            border-bottom: 2px solid #eee;
                            padding-bottom: 5px;
                        }
                        
                        .info-grid {
                            display: grid;
                            grid-template-columns: repeat(2, 1fr);
                            gap: 20px;
                            margin-bottom: 20px;
                        }
                        
                        .info-item {
                            margin-bottom: 10px;
                        }
                        
                        .info-label {
                            font-weight: bold;
                            margin-left: 10px;
                        }
                        
                        .signatures {
                            margin-top: 50px;
                            display: flex;
                            justify-content: space-between;
                        }
                        
                        .signature-box {
                            border-top: 2px solid #000;
                            width: 200px;
                            padding-top: 10px;
                            text-align: center;
                        }
                        
                        @media print {
                            @page {
                                margin: 2cm;
                            }
                        }
                    </style>
                </head>
                <body>
                    <div class="contract-header">
                        <div class="contract-title">عقد إيجار</div>
                        <div>رقم العقد: ${contractId}</div>
                        <div>تاريخ التحرير: ${new Date().toLocaleDateString('ar-EG')}</div>
                    </div>

                    <div class="section">
                        <div class="section-title">أطراف العقد</div>
                        <div class="info-grid">
                            <div class="party-info">
                                <h3>الطرف الأول (المؤجر)</h3>
                                <div class="info-item">
                                    <span class="info-label">الاسم:</span>
                                    <span>أحمد محمد</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">رقم الهوية:</span>
                                    <span>29XXXXXXXX</span>
                                </div>
                            </div>
                            <div class="party-info">
                                <h3>الطرف الثاني (المستأجر)</h3>
                                <div class="info-item">
                                    <span class="info-label">الاسم:</span>
                                    <span>${contract.tenantName}</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">رقم الهوية:</span>
                                    <span>${contract.tenantId}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="section">
                        <div class="section-title">تفاصيل العقار</div>
                        <div class="property-details">
                            <div class="info-item">
                                <span class="info-label">العقار:</span>
                                <span>${contract.propertyName}</span>
                            </div>
                            <div class="info-item">
                                <span class="info-label">العنوان:</span>
                                <span>${contract.propertyAddress}</span>
                            </div>
                        </div>
                    </div>

                    <div class="section">
                        <div class="section-title">شروط العقد</div>
                        <div class="contract-terms">
                            <div class="info-item">
                                <span class="info-label">مدة العقد:</span>
                                <span>${contract.duration} شهر</span>
                            </div>
                            <div class="info-item">
                                <span class="info-label">تاريخ البداية:</span>
                                <span>${new Date(contract.startDate).toLocaleDateString('ar-EG')}</span>
                            </div>
                            <div class="info-item">
                                <span class="info-label">تاريخ النهاية:</span>
                                <span>${new Date(contract.endDate).toLocaleDateString('ar-EG')}</span>
                            </div>
                            <div class="info-item">
                                <span class="info-label">قيمة الإيجار:</span>
                                <span>${contract.rentAmount} ج.م شهرياً</span>
                            </div>
                            <div class="info-item">
                                <span class="info-label">قيمة التأمين:</span>
                                <span>${contract.deposit} ج.م</span>
                            </div>
                            <div class="info-item">
                                <span class="info-label">طريقة السداد:</span>
                                <span>${this.getPaymentMethodLabel(contract.paymentMethod)}</span>
                            </div>
                        </div>
                    </div>

                    <div class="section">
                        <div class="section-title">المرافق المشمولة</div>
                        <div class="utilities">
                            ${this.renderUtilities(contract.utilities)}
                        </div>
                    </div>

                    ${contract.terms ? `
                        <div class="section">
                            <div class="section-title">شروط إضافية</div>
                            <div class="additional-terms">
                                ${contract.terms}
                            </div>
                        </div>
                    ` : ''}

                    <div class="signatures">
                        <div class="signature-box">
                            <div>توقيع المؤجر</div>
                            <div>الاسم: أحمد محمد</div>
                        </div>
                        <div class="signature-box">
                            <div>توقيع المستأجر</div>
                            <div>الاسم: ${contract.tenantName}</div>
                        </div>
                    </div>
                </body>
                </html>
            `);

            printWindow.document.close();
            setTimeout(() => {
                printWindow.print();
                this.hideLoader();
                notifications.success('تم إرسال العقد للطباعة');
            }, 500);

        } catch (error) {
            this.hideLoader();
            notifications.error('حدث خطأ أثناء طباعة العقد');
        }
    }

    async searchContracts(query) {
        if (!query) {
            this.refreshContractsList();
            return;
        }

        const searchTerm = query.toLowerCase();
        const filteredContracts = Array.from(this.contracts.values()).filter(contract => 
            contract.id.toLowerCase().includes(searchTerm) ||
            contract.propertyName.toLowerCase().includes(searchTerm) ||
            contract.tenantName.toLowerCase().includes(searchTerm)
        );

        this.renderContracts(filteredContracts);
    }

    downloadCSV(data, filename) {
        const csvContent = this.convertToCSV(data);
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        
        if (navigator.msSaveBlob) {
            navigator.msSaveBlob(blob, filename);
            return;
        }

        link.href = URL.createObjectURL(blob);
        link.setAttribute('download', filename);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    convertToCSV(objArray) {
        const array = typeof objArray !== 'object' ? JSON.parse(objArray) : objArray;
        let str = '\uFEFF'; // BOM for Excel to properly display Arabic

        // Headers
        const headers = Object.keys(array[0]);
        str += headers.join(',') + '\r\n';

        // Data
        array.forEach(item => {
            let line = '';
            headers.forEach((header, index) => {
                if (line !== '') line += ',';
                line += `"${item[header]}"`;
            });
            str += line + '\r\n';
        });

        return str;
    }

    // التحميل والتحديث
    async loadContracts() {
        try {
            this.showLoader();
            await this.simulateApiRequest();
            // هنا يمكن إضافة طلب API لجلب العقود
            this.hideLoader();
        } catch (error) {
            this.hideLoader();
            notifications.error('حدث خطأ أثناء تحميل العقود');
        }
    }

    refreshContractsList() {
        this.renderContracts(Array.from(this.contracts.values()));
        this.updateContractStats();
    }

    showLoader() {
        const loader = document.createElement('div');
        loader.className = 'loader';
        document.body.appendChild(loader);
    }

    hideLoader() {
        const loader = document.querySelector('.loader');
        if (loader) loader.remove();
    }

    simulateApiRequest() {
        return new Promise(resolve => setTimeout(resolve, 1000));
    }

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
}

// تهيئة النظام
document.addEventListener('DOMContentLoaded', () => {
    window.contractsManager = new ContractsManager();
});

// تصدير مدير العقود
export default ContractsManager;