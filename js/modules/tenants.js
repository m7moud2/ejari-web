// tenants.js
import { modal } from '../utils/modal.js';
import { notifications } from '../utils/notifications.js';

class TenantsManager {
    constructor() {
        this.tenants = new Map();
        this.initializeEventListeners();
    }

    initializeEventListeners() {
        // زر إضافة مستأجر جديد
        const addTenantBtn = document.querySelector('.add-tenant-btn');
        if (addTenantBtn) {
            addTenantBtn.addEventListener('click', () => this.showAddTenantModal());
        }

        // البحث في المستأجرين
        const searchInput = document.querySelector('.tenants-search');
        if (searchInput) {
            searchInput.addEventListener('input', this.debounce((e) => 
                this.searchTenants(e.target.value), 300));
        }

        // فلتر المستأجرين
        const statusFilter = document.querySelector('.tenants-status-filter');
        if (statusFilter) {
            statusFilter.addEventListener('change', (e) => 
                this.filterTenants(e.target.value));
        }
    }

    showAddTenantModal() {
        modal.showForm({
            title: 'إضافة مستأجر جديد',
            fields: [
                {
                    type: 'text',
                    name: 'fullName',
                    label: 'الاسم الكامل',
                    required: true,
                    placeholder: 'أدخل الاسم الكامل'
                },
                {
                    type: 'email',
                    name: 'email',
                    label: 'البريد الإلكتروني',
                    required: true,
                    placeholder: 'example@domain.com'
                },
                {
                    type: 'tel',
                    name: 'phone',
                    label: 'رقم الهاتف',
                    required: true,
                    placeholder: '01xxxxxxxxx'
                },
                {
                    type: 'text',
                    name: 'nationalId',
                    label: 'رقم الهوية',
                    required: true,
                    placeholder: 'أدخل رقم الهوية'
                },
                {
                    type: 'textarea',
                    name: 'address',
                    label: 'العنوان',
                    required: true,
                    placeholder: 'أدخل العنوان بالتفصيل'
                },
                {
                    type: 'text',
                    name: 'occupation',
                    label: 'الوظيفة',
                    placeholder: 'أدخل الوظيفة'
                },
                {
                    type: 'text',
                    name: 'emergencyContact',
                    label: 'رقم للطوارئ',
                    placeholder: 'رقم شخص يمكن الاتصال به في الطوارئ'
                }
            ],
            onSubmit: (data) => this.addTenant(data)
        });
    }

    async addTenant(data) {
        try {
            await this.simulateApiRequest();
            const tenantId = Date.now();
            
            this.tenants.set(tenantId, {
                id: tenantId,
                ...data,
                status: 'active',
                createdAt: new Date().toISOString(),
                rentedProperties: [],
                paymentHistory: []
            });

            notifications.success('تم إضافة المستأجر بنجاح');
            this.refreshTenantsList();
        } catch (error) {
            notifications.error('حدث خطأ أثناء إضافة المستأجر');
        }
    }

    viewTenant(tenantId) {
        const tenant = this.tenants.get(tenantId);
        if (!tenant) return;

        modal.show({
            title: 'ملف المستأجر',
            size: 'large',
            content: `
                <div class="tenant-profile">
                    <div class="profile-header">
                        <div class="profile-image">
                            <img src="/api/placeholder/150/150" alt="صورة المستأجر">
                            <span class="status ${tenant.status}"></span>
                        </div>
                        <div class="profile-info">
                            <h2>${tenant.fullName}</h2>
                            <p class="tenant-id">رقم المستأجر: #${tenant.id}</p>
                            <p class="join-date">
                                تاريخ التسجيل: ${new Date(tenant.createdAt).toLocaleDateString('ar-EG')}
                            </p>
                        </div>
                    </div>

                    <div class="profile-sections">
                        <div class="section personal-info">
                            <h3>المعلومات الشخصية</h3>
                            <dl>
                                <dt>البريد الإلكتروني</dt>
                                <dd><a href="mailto:${tenant.email}">${tenant.email}</a></dd>
                                
                                <dt>رقم الهاتف</dt>
                                <dd><a href="tel:${tenant.phone}">${tenant.phone}</a></dd>
                                
                                <dt>رقم الهوية</dt>
                                <dd>${tenant.nationalId}</dd>
                                
                                <dt>العنوان</dt>
                                <dd>${tenant.address}</dd>
                                
                                <dt>الوظيفة</dt>
                                <dd>${tenant.occupation || 'غير محدد'}</dd>
                                
                                <dt>رقم الطوارئ</dt>
                                <dd>${tenant.emergencyContact || 'غير محدد'}</dd>
                            </dl>
                        </div>

                        <div class="section rented-properties">
                            <h3>العقارات المستأجرة</h3>
                            ${this.renderRentedProperties(tenant.rentedProperties)}
                        </div>

                        <div class="section payment-history">
                            <h3>سجل المدفوعات</h3>
                            ${this.renderPaymentHistory(tenant.paymentHistory)}
                        </div>

                        <div class="section documents">
                            <h3>المستندات</h3>
                            <div class="documents-list">
                                <div class="document-item">
                                    <i class="fas fa-file-pdf"></i>
                                    <span>صورة الهوية</span>
                                    <button class="btn btn-sm" onclick="tenantsManager.viewDocument('id', ${tenant.id})">
                                        عرض
                                    </button>
                                </div>
                                <div class="document-item">
                                    <i class="fas fa-file-contract"></i>
                                    <span>العقد الحالي</span>
                                    <button class="btn btn-sm" onclick="tenantsManager.viewDocument('contract', ${tenant.id})">
                                        عرض
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `,
            actions: [
                {
                    text: 'تعديل البيانات',
                    class: 'btn-primary',
                    onClick: () => this.editTenant(tenantId)
                },
                {
                    text: 'إرسال رسالة',
                    class: 'btn-outline',
                    onClick: () => this.sendMessage(tenantId)
                },
                {
                    text: 'طباعة الملف',
                    class: 'btn-outline',
                    onClick: () => this.printTenantProfile(tenantId)
                }
            ]
        });
    }

    renderRentedProperties(properties) {
        if (!properties || properties.length === 0) {
            return `<p class="no-data">لا توجد عقارات مستأجرة حالياً</p>`;
        }

        return `
            <div class="properties-list">
                ${properties.map(property => `
                    <div class="property-item">
                        <img src="/api/placeholder/100/100" alt="صورة العقار">
                        <div class="property-details">
                            <h4>${property.name}</h4>
                            <p>${property.address}</p>
                            <div class="rent-details">
                                <span class="rent">${property.rent} ج.م/شهر</span>
                                <span class="dates">
                                    ${new Date(property.startDate).toLocaleDateString('ar-EG')} - 
                                    ${new Date(property.endDate).toLocaleDateString('ar-EG')}
                                </span>
                            </div>
                        </div>
                        <div class="contract-status ${property.status}">
                            ${this.getContractStatusLabel(property.status)}
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }

    renderPaymentHistory(payments) {
        if (!payments || payments.length === 0) {
            return `<p class="no-data">لا يوجد سجل مدفوعات</p>`;
        }

        return `
            <table class="payments-table">
                <thead>
                    <tr>
                        <th>التاريخ</th>
                        <th>العقار</th>
                        <th>المبلغ</th>
                        <th>نوع الدفع</th>
                        <th>الحالة</th>
                    </tr>
                </thead>
                <tbody>
                    ${payments.map(payment => `
                        <tr>
                            <td>${new Date(payment.date).toLocaleDateString('ar-EG')}</td>
                            <td>${payment.propertyName}</td>
                            <td>${payment.amount} ج.م</td>
                            <td>${payment.type}</td>
                            <td>
                                <span class="status-badge ${payment.status}">
                                    ${this.getPaymentStatusLabel(payment.status)}
                                </span>
                            </td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        `;
    }

    async editTenant(tenantId) {
        const tenant = this.tenants.get(tenantId);
        if (!tenant) return;

        modal.showForm({
            title: 'تعديل بيانات المستأجر',
            fields: [
                {
                    type: 'text',
                    name: 'fullName',
                    label: 'الاسم الكامل',
                    required: true,
                    value: tenant.fullName
                },
                {
                    type: 'email',
                    name: 'email',
                    label: 'البريد الإلكتروني',
                    required: true,
                    value: tenant.email
                },
                {
                    type: 'tel',
                    name: 'phone',
                    label: 'رقم الهاتف',
                    required: true,
                    value: tenant.phone
                },
                {
                    type: 'text',
                    name: 'address',
                    label: 'العنوان',
                    required: true,
                    value: tenant.address
                },
                {
                    type: 'text',
                    name: 'occupation',
                    label: 'الوظيفة',
                    value: tenant.occupation
                },
                {
                    type: 'text',
                    name: 'emergencyContact',
                    label: 'رقم للطوارئ',
                    value: tenant.emergencyContact
                }
            ],
            onSubmit: async (data) => {
                try {
                    await this.simulateApiRequest();
                    this.tenants.set(tenantId, {
                        ...tenant,
                        ...data,
                        updatedAt: new Date().toISOString()
                    });
                    notifications.success('تم تحديث بيانات المستأجر بنجاح');
                    this.refreshTenantsList();
                } catch (error) {
                    notifications.error('حدث خطأ أثناء تحديث البيانات');
                }
            }
        });
    }

    async sendMessage(tenantId) {
        const tenant = this.tenants.get(tenantId);
        if (!tenant) return;

        modal.showForm({
            title: `إرسال رسالة إلى ${tenant.fullName}`,
            fields: [
                {
                    type: 'select',
                    name: 'messageType',
                    label: 'نوع الرسالة',
                    required: true,
                    options: [
                        { value: 'email', label: 'بريد إلكتروني' },
                        { value: 'sms', label: 'رسالة نصية' },
                        { value: 'notification', label: 'إشعار في النظام' }
                    ]
                },
                {
                    type: 'text',
                    name: 'subject',
                    label: 'الموضوع',
                    required: true
                },
                {
                    type: 'textarea',
                    name: 'message',
                    label: 'نص الرسالة',
                    required: true,
                    rows: 5
                }
            ],
            onSubmit: async (data) => {
                try {
                    await this.simulateApiRequest();
                    notifications.success('تم إرسال الرسالة بنجاح');
                } catch (error) {
                    notifications.error('حدث خطأ أثناء إرسال الرسالة');
                }
            }
        });
    }

    getContractStatusLabel(status) {
        const labels = {
            active: 'ساري',
            expired: 'منتهي',
            pending: 'قيد التجديد'
        };
        return labels[status] || status;
    }

    getPaymentStatusLabel(status) {
        const labels = {
            paid: 'مدفوع',
            pending: 'قيد الانتظار',
            late: 'متأخر',
            failed: 'فشل الدفع'
        };
        return labels[status] || status;
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

    async viewDocument(type, tenantId) {
        try {
            await this.simulateApiRequest();
            notifications.success('جاري تحميل المستند...');
            
            // محاكاة عرض المستند
            modal.show({
                title: 'عرض المستند',
                content: `
                    <div class="document-viewer">
                        <div class="document-preview">
                            <img src="/api/placeholder/600/800" alt="معاينة المستند">
                        </div>
                        <div class="document-info">
                            <h4>${this.getDocumentTitle(type)}</h4>
                            <p>تاريخ الرفع: ${new Date().toLocaleDateString('ar-EG')}</p>
                        </div>
                    </div>
                `,
                actions: [
                    {
                        text: 'تحميل',
                        class: 'btn-primary',
                        onClick: () => this.downloadDocument(type, tenantId)
                    },
                    {
                        text: 'طباعة',
                        class: 'btn-outline',
                        onClick: () => this.printDocument(type, tenantId)
                    }
                ]
            });
        } catch (error) {
            notifications.error('حدث خطأ أثناء تحميل المستند');
        }
    }

    getDocumentTitle(type) {
        const titles = {
            id: 'صورة الهوية',
            contract: 'عقد الإيجار',
            receipt: 'إيصال دفع'
        };
        return titles[type] || 'مستند';
    }

    async downloadDocument(type, tenantId) {
        try {
            await this.simulateApiRequest();
            notifications.success('تم تحميل المستند بنجاح');
        } catch (error) {
            notifications.error('حدث خطأ أثناء تحميل المستند');
        }
    }

    async printDocument(type, tenantId) {
        try {
            await this.simulateApiRequest();
            window.print();
        } catch (error) {
            notifications.error('حدث خطأ أثناء طباعة المستند');
        }
    }

    searchTenants(query) {
        if (!query) {
            this.refreshTenantsList();
            return;
        }

        const searchTerm = query.toLowerCase();
        const filteredTenants = Array.from(this.tenants.values()).filter(tenant => 
            tenant.fullName.toLowerCase().includes(searchTerm) ||
            tenant.email.toLowerCase().includes(searchTerm) ||
            tenant.phone.includes(searchTerm)
        );

        this.renderTenants(filteredTenants);
    }

    filterTenants(status) {
        if (status === 'all') {
            this.refreshTenantsList();
            return;
        }

        const filteredTenants = Array.from(this.tenants.values())
            .filter(tenant => tenant.status === status);
        
        this.renderTenants(filteredTenants);
    }

    renderTenants(tenants) {
        const container = document.querySelector('.tenants-grid');
        if (!container) return;

        container.innerHTML = tenants.map(tenant => this.createTenantCard(tenant)).join('');
    }

    createTenantCard(tenant) {
        return `
            <div class="tenant-card" data-id="${tenant.id}">
                <div class="tenant-header">
                    <img src="/api/placeholder/80/80" alt="${tenant.fullName}">
                    <span class="status-badge ${tenant.status}">
                        ${this.getTenantStatusLabel(tenant.status)}
                    </span>
                </div>
                <div class="tenant-content">
                    <h3>${tenant.fullName}</h3>
                    <div class="tenant-contact">
                        <p><i class="fas fa-envelope"></i> ${tenant.email}</p>
                        <p><i class="fas fa-phone"></i> ${tenant.phone}</p>
                    </div>
                    <div class="tenant-stats">
                        <div class="stat">
                            <label>العقارات المؤجرة</label>
                            <value>${tenant.rentedProperties?.length || 0}</value>
                        </div>
                        <div class="stat">
                            <label>إجمالي المدفوعات</label>
                            <value>${this.calculateTotalPayments(tenant)} ج.م</value>
                        </div>
                    </div>
                </div>
                <div class="tenant-actions">
                    <button class="btn btn-primary btn-sm" 
                            onclick="tenantsManager.viewTenant(${tenant.id})">
                        عرض الملف
                    </button>
                    <button class="btn btn-outline btn-sm" 
                            onclick="tenantsManager.sendMessage(${tenant.id})">
                        مراسلة
                    </button>
                </div>
            </div>
        `;
    }

    calculateTotalPayments(tenant) {
        return tenant.paymentHistory?.reduce((total, payment) => 
            total + (payment.amount || 0), 0) || 0;
    }

    getTenantStatusLabel(status) {
        const labels = {
            active: 'نشط',
            inactive: 'غير نشط',
            pending: 'قيد المراجعة',
            blacklisted: 'محظور'
        };
        return labels[status] || status;
    }

    async refreshTenantsList() {
        try {
            const container = document.querySelector('.tenants-grid');
            if (!container) return;

            container.innerHTML = '';
            this.tenants.forEach(tenant => {
                container.insertAdjacentHTML('beforeend', this.createTenantCard(tenant));
            });
        } catch (error) {
            notifications.error('حدث خطأ أثناء تحديث قائمة المستأجرين');
        }
    }
}

// تصدير مدير المستأجرين
export const tenantsManager = new TenantsManager();