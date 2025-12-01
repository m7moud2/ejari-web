// properties.js
import { modal } from '../utils/modal.js';
import { notifications } from '../utils/notifications.js';

class PropertiesManager {
    constructor() {
        this.properties = new Map();
        this.initializeEventListeners();
    }

    initializeEventListeners() {
        // زر إضافة عقار جديد
        const addPropertyBtn = document.querySelector('.add-property-btn');
        if (addPropertyBtn) {
            addPropertyBtn.addEventListener('click', () => this.showAddPropertyModal());
        }

        // فلتر العقارات
        const filterSelect = document.querySelector('.property-filter');
        if (filterSelect) {
            filterSelect.addEventListener('change', (e) => this.filterProperties(e.target.value));
        }
    }

    showAddPropertyModal() {
        modal.showForm({
            title: 'إضافة عقار جديد',
            fields: [
                {
                    type: 'text',
                    name: 'propertyName',
                    label: 'اسم العقار',
                    required: true,
                    placeholder: 'مثال: شقة في المعادي'
                },
                {
                    type: 'text',
                    name: 'location',
                    label: 'الموقع',
                    required: true,
                    placeholder: 'المنطقة، المدينة'
                },
                {
                    type: 'number',
                    name: 'bedrooms',
                    label: 'عدد الغرف',
                    required: true
                },
                {
                    type: 'number',
                    name: 'bathrooms',
                    label: 'عدد الحمامات',
                    required: true
                },
                {
                    type: 'number',
                    name: 'area',
                    label: 'المساحة (م²)',
                    required: true
                },
                {
                    type: 'number',
                    name: 'rent',
                    label: 'قيمة الإيجار (ج.م)',
                    required: true
                },
                {
                    type: 'select',
                    name: 'status',
                    label: 'الحالة',
                    required: true,
                    options: [
                        { value: 'available', label: 'متاح' },
                        { value: 'rented', label: 'مؤجر' },
                        { value: 'maintenance', label: 'تحت الصيانة' }
                    ]
                },
                {
                    type: 'textarea',
                    name: 'description',
                    label: 'وصف العقار',
                    rows: 4
                }
            ],
            onSubmit: (data) => this.addProperty(data)
        });
    }

    async addProperty(data) {
        try {
            // هنا يمكن إضافة طلب API لإضافة العقار
            // محاكاة طلب API
            await this.simulateApiRequest();
            
            this.properties.set(Date.now(), {
                id: Date.now(),
                ...data,
                createdAt: new Date().toISOString()
            });

            notifications.success('تم إضافة العقار بنجاح');
            this.refreshPropertiesList();
        } catch (error) {
            notifications.error('حدث خطأ أثناء إضافة العقار');
            console.error('خطأ في إضافة العقار:', error);
        }
    }

    async editProperty(propertyId) {
        const property = this.properties.get(propertyId);
        if (!property) return;

        modal.showForm({
            title: 'تعديل العقار',
            fields: [
                {
                    type: 'text',
                    name: 'propertyName',
                    label: 'اسم العقار',
                    required: true,
                    value: property.propertyName
                },
                // ... باقي الحقول مع القيم الحالية
            ],
            onSubmit: async (data) => {
                try {
                    await this.simulateApiRequest();
                    this.properties.set(propertyId, {
                        ...property,
                        ...data,
                        updatedAt: new Date().toISOString()
                    });
                    notifications.success('تم تحديث العقار بنجاح');
                    this.refreshPropertiesList();
                } catch (error) {
                    notifications.error('حدث خطأ أثناء تحديث العقار');
                }
            }
        });
    }

    async deleteProperty(propertyId) {
        modal.showConfirmation({
            title: 'حذف العقار',
            message: 'هل أنت متأكد من حذف هذا العقار؟',
            onConfirm: async () => {
                try {
                    await this.simulateApiRequest();
                    this.properties.delete(propertyId);
                    notifications.success('تم حذف العقار بنجاح');
                    this.refreshPropertiesList();
                } catch (error) {
                    notifications.error('حدث خطأ أثناء حذف العقار');
                }
            }
        });
    }

    viewProperty(propertyId) {
        const property = this.properties.get(propertyId);
        if (!property) return;

        modal.show({
            title: property.propertyName,
            content: `
                <div class="property-details">
                    <div class="property-images">
                        <img src="/api/placeholder/600/400" alt="صورة العقار" class="main-image">
                        <div class="image-thumbnails">
                            <img src="/api/placeholder/100/100" alt="صورة مصغرة">
                            <img src="/api/placeholder/100/100" alt="صورة مصغرة">
                            <img src="/api/placeholder/100/100" alt="صورة مصغرة">
                        </div>
                    </div>
                    <div class="property-info">
                        <div class="info-section">
                            <h3>معلومات العقار</h3>
                            <dl>
                                <dt>الموقع</dt>
                                <dd>${property.location}</dd>
                                <dt>المساحة</dt>
                                <dd>${property.area} م²</dd>
                                <dt>عدد الغرف</dt>
                                <dd>${property.bedrooms}</dd>
                                <dt>عدد الحمامات</dt>
                                <dd>${property.bathrooms}</dd>
                            </dl>
                        </div>
                        <div class="info-section">
                            <h3>التفاصيل المالية</h3>
                            <dl>
                                <dt>قيمة الإيجار</dt>
                                <dd>${property.rent} ج.م/شهر</dd>
                                <dt>التأمين</dt>
                                <dd>${property.rent * 2} ج.م</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            `,
            actions: [
                {
                    text: 'تعديل',
                    class: 'btn-primary',
                    onClick: () => this.editProperty(propertyId)
                },
                {
                    text: 'حذف',
                    class: 'btn-danger',
                    onClick: () => this.deleteProperty(propertyId)
                }
            ]
        });
    }

    filterProperties(status) {
        const propertiesContainer = document.querySelector('.properties-grid');
        if (!propertiesContainer) return;

        if (status === 'all') {
            propertiesContainer.querySelectorAll('.property-card').forEach(card => {
                card.style.display = 'block';
            });
        } else {
            propertiesContainer.querySelectorAll('.property-card').forEach(card => {
                const cardStatus = card.dataset.status;
                card.style.display = cardStatus === status ? 'block' : 'none';
            });
        }
    }

    refreshPropertiesList() {
        const container = document.querySelector('.properties-grid');
        if (!container) return;

        container.innerHTML = '';
        this.properties.forEach(property => {
            container.appendChild(this.createPropertyCard(property));
        });
    }

    createPropertyCard(property) {
        const card = document.createElement('div');
        card.className = 'property-card';
        card.dataset.status = property.status;
        
        card.innerHTML = `
            <div class="property-image">
                <img src="/api/placeholder/400/300" alt="${property.propertyName}">
                <span class="status-badge ${property.status}">${this.getStatusLabel(property.status)}</span>
            </div>
            <div class="property-content">
                <h3>${property.propertyName}</h3>
                <p class="location">
                    <i class="fas fa-map-marker-alt"></i>
                    ${property.location}
                </p>
                <div class="property-features">
                    <span><i class="fas fa-bed"></i> ${property.bedrooms} غرف</span>
                    <span><i class="fas fa-bath"></i> ${property.bathrooms} حمام</span>
                    <span><i class="fas fa-ruler-combined"></i> ${property.area}م²</span>
                </div>
                <div class="property-price">
                    <span class="price">${property.rent} ج.م</span>
                    <span class="period">/ شهر</span>
                </div>
            </div>
            <div class="property-actions">
                <button class="btn btn-outline btn-sm" onclick="propertiesManager.viewProperty(${property.id})">
                    <i class="fas fa-eye"></i>
                    عرض
                </button>
                <button class="btn btn-outline btn-sm" onclick="propertiesManager.editProperty(${property.id})">
                    <i class="fas fa-edit"></i>
                    تعديل
                </button>
                <button class="btn btn-outline btn-sm" onclick="propertiesManager.viewMaintenanceHistory(${property.id})">
                    <i class="fas fa-tools"></i>
                    الصيانة
                </button>
            </div>
        `;

        return card;
    }

    getStatusLabel(status) {
        const labels = {
            available: 'متاح',
            rented: 'مؤجر',
            maintenance: 'تحت الصيانة'
        };
        return labels[status] || status;
    }

    async viewMaintenanceHistory(propertyId) {
        try {
            const maintenanceHistory = await this.fetchMaintenanceHistory(propertyId);
            modal.show({
                title: 'سجل الصيانة',
                content: this.createMaintenanceHistoryContent(maintenanceHistory),
                size: 'large'
            });
        } catch (error) {
            notifications.error('حدث خطأ أثناء تحميل سجل الصيانة');
        }
    }

    // محاكاة طلبات API
    async simulateApiRequest() {
        return new Promise(resolve => setTimeout(resolve, 1000));
    }

    async fetchMaintenanceHistory(propertyId) {
        await this.simulateApiRequest();
        return [
            {
                date: '2024-01-15',
                type: 'دورية',
                description: 'صيانة دورية للتكييف',
                cost: 500
            },
            {
                date: '2024-02-20',
                type: 'طارئة',
                description: 'إصلاح تسريب مياه',
                cost: 800
            }
        ];
    }

    createMaintenanceHistoryContent(history) {
        return `
            <div class="maintenance-history">
                <table class="table">
                    <thead>
                        <tr>
                            <th>التاريخ</th>
                            <th>النوع</th>
                            <th>الوصف</th>
                            <th>التكلفة</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${history.map(item => `
                            <tr>
                                <td>${new Date(item.date).toLocaleDateString('ar-EG')}</td>
                                <td>${item.type}</td>
                                <td>${item.description}</td>
                                <td>${item.cost} ج.م</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    }
}

// تصدير مدير العقارات
export const propertiesManager = new PropertiesManager();
