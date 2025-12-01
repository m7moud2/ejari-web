// maintenance.js
import { modal } from '../utils/modal.js';
import { notifications } from '../utils/notifications.js';

class MaintenanceManager {
    constructor() {
        this.requests = new Map();
        this.technicians = new Map();
        this.initializeEventListeners();
    }

    initializeEventListeners() {
        // فلتر طلبات الصيانة
        const filterSelect = document.querySelector('.maintenance-filter');
        if (filterSelect) {
            filterSelect.addEventListener('change', (e) => 
                this.filterRequests(e.target.value));
        }

        // البحث في الطلبات
        const searchInput = document.querySelector('.maintenance-search');
        if (searchInput) {
            searchInput.addEventListener('input', this.debounce((e) => 
                this.searchRequests(e.target.value), 300));
        }

        // تحديث تلقائي كل دقيقة
        setInterval(() => this.updateRequestsStatus(), 60000);
    }

    showNewRequestModal() {
        modal.showForm({
            title: 'طلب صيانة جديد',
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
                    name: 'category',
                    label: 'نوع المشكلة',
                    required: true,
                    options: [
                        { value: 'plumbing', label: 'سباكة' },
                        { value: 'electrical', label: 'كهرباء' },
                        { value: 'ac', label: 'تكييف' },
                        { value: 'carpentry', label: 'نجارة' },
                        { value: 'painting', label: 'دهان' },
                        { value: 'other', label: 'أخرى' }
                    ]
                },
                {
                    type: 'select',
                    name: 'priority',
                    label: 'الأولوية',
                    required: true,
                    options: [
                        { value: 'urgent', label: 'عاجل' },
                        { value: 'high', label: 'مرتفع' },
                        { value: 'medium', label: 'متوسط' },
                        { value: 'low', label: 'منخفض' }
                    ]
                },
                {
                    type: 'textarea',
                    name: 'description',
                    label: 'وصف المشكلة',
                    required: true,
                    rows: 4
                },
                {
                    type: 'text',
                    name: 'preferredDate',
                    label: 'التاريخ المفضل للزيارة',
                    type: 'date'
                },
                {
                    type: 'text',
                    name: 'contactNumber',
                    label: 'رقم التواصل',
                    required: true
                }
            ],
            onSubmit: (data) => this.createMaintenanceRequest(data)
        });
    }

    async createMaintenanceRequest(data) {
        try {
            await this.simulateApiRequest();
            const requestId = Date.now();
            
            this.requests.set(requestId, {
                id: requestId,
                ...data,
                status: 'pending',
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString(),
                timeline: [
                    {
                        status: 'created',
                        timestamp: new Date().toISOString(),
                        note: 'تم إنشاء طلب الصيانة'
                    }
                ]
            });

            notifications.success('تم إنشاء طلب الصيانة بنجاح');
            this.refreshRequestsList();
        } catch (error) {
            notifications.error('حدث خطأ أثناء إنشاء طلب الصيانة');
        }
    }

    viewRequest(requestId) {
        const request = this.requests.get(requestId);
        if (!request) return;

        modal.show({
            title: `طلب صيانة #${requestId}`,
            size: 'large',
            content: `
                <div class="maintenance-request-details">
                    <div class="request-header">
                        <div class="status-badge ${request.priority}">
                            ${this.getPriorityLabel(request.priority)}
                        </div>
                        <div class="category-badge">
                            <i class="fas ${this.getCategoryIcon(request.category)}"></i>
                            ${this.getCategoryLabel(request.category)}
                        </div>
                        <div class="status-badge ${request.status}">
                            ${this.getStatusLabel(request.status)}
                        </div>
                    </div>

                    <div class="request-sections">
                        <div class="section">
                            <h3>تفاصيل المشكلة</h3>
                            <p>${request.description}</p>
                        </div>

                        <div class="section">
                            <h3>معلومات العقار</h3>
                            <div class="property-info">
                                <img src="/api/placeholder/100/100" alt="صورة العقار">
                                <div>
                                    <h4>${request.propertyName}</h4>
                                    <p>${request.propertyAddress}</p>
                                </div>
                            </div>
                        </div>

                        <div class="section">
                            <h3>معلومات التواصل</h3>
                            <p><i class="fas fa-phone"></i> ${request.contactNumber}</p>
                            <p><i class="fas fa-calendar"></i> التاريخ المفضل: ${request.preferredDate}</p>
                        </div>

                        ${request.assignedTechnician ? `
                            <div class="section">
                                <h3>الفني المكلف</h3>
                                <div class="technician-info">
                                    <img src="/api/placeholder/50/50" alt="صورة الفني">
                                    <div>
                                        <h4>${request.assignedTechnician.name}</h4>
                                        <p>${request.assignedTechnician.specialization}</p>
                                        <p><i class="fas fa-phone"></i> ${request.assignedTechnician.phone}</p>
                                    </div>
                                </div>
                            </div>
                        ` : ''}

                        <div class="section">
                            <h3>سجل الطلب</h3>
                            <div class="request-timeline">
                                ${this.renderTimeline(request.timeline)}
                            </div>
                        </div>

                        ${request.completionDetails ? `
                            <div class="section">
                                <h3>تفاصيل الإنجاز</h3>
                                <div class="completion-details">
                                    <p>${request.completionDetails.notes}</p>
                                    <div class="cost-details">
                                        <span>التكلفة: ${request.completionDetails.cost} ج.م</span>
                                        <span>وقت العمل: ${request.completionDetails.workHours} ساعة</span>
                                    </div>
                                </div>
                            </div>
                        ` : ''}
                    </div>
                </div>
            `,
            actions: this.getRequestActions(request)
        });
    }

    getRequestActions(request) {
        const actions = [];

        switch (request.status) {
            case 'pending':
                actions.push(
                    {
                        text: 'تعيين فني',
                        class: 'btn-primary',
                        onClick: () => this.assignTechnician(request.id)
                    }
                );
                break;

            case 'assigned':
                actions.push(
                    {
                        text: 'تحديث الحالة',
                        class: 'btn-primary',
                        onClick: () => this.updateRequestStatus(request.id)
                    },
                    {
                        text: 'تغيير الفني',
                        class: 'btn-outline',
                        onClick: () => this.reassignTechnician(request.id)
                    }
                );
                break;

            case 'in_progress':
                actions.push(
                    {
                        text: 'إنهاء الطلب',
                        class: 'btn-success',
                        onClick: () => this.completeRequest(request.id)
                    },
                    {
                        text: 'إضافة ملاحظة',
                        class: 'btn-outline',
                        onClick: () => this.addNote(request.id)
                    }
                );
                break;
        }

        // أزرار عامة
        actions.push(
            {
                text: 'طباعة التقرير',
                class: 'btn-outline',
                onClick: () => this.printRequestReport(request.id)
            }
        );

        return actions;
    }

    async assignTechnician(requestId) {
        const technicians = await this.getAvailableTechnicians();
        
        modal.showForm({
            title: 'تعيين فني',
            fields: [
                {
                    type: 'select',
                    name: 'technicianId',
                    label: 'اختر الفني',
                    required: true,
                    options: technicians
                },
                {
                    type: 'datetime-local',
                    name: 'scheduledDate',
                    label: 'موعد الزيارة',
                    required: true
                },
                {
                    type: 'textarea',
                    name: 'notes',
                    label: 'ملاحظات',
                    rows: 3
                }
            ],
            onSubmit: async (data) => {
                try {
                    await this.simulateApiRequest();
                    const request = this.requests.get(requestId);
                    if (request) {
                        const technician = this.technicians.get(data.technicianId);
                        request.status = 'assigned';
                        request.assignedTechnician = technician;
                        request.scheduledDate = data.scheduledDate;
                        request.timeline.push({
                            status: 'assigned',
                            timestamp: new Date().toISOString(),
                            note: `تم تعيين ${technician.name} للمهمة`
                        });
                        
                        this.requests.set(requestId, request);
                        notifications.success('تم تعيين الفني بنجاح');
                        this.refreshRequestsList();
                    }
                } catch (error) {
                    notifications.error('حدث خطأ أثناء تعيين الفني');
                }
            }
        });
    }

    async completeRequest(requestId) {
        modal.showForm({
            title: 'إنهاء طلب الصيانة',
            fields: [
                {
                    type: 'textarea',
                    name: 'completionNotes',
                    label: 'تفاصيل الإنجاز',
                    required: true,
                    rows: 4
                },
                {
                    type: 'number',
                    name: 'cost',
                    label: 'التكلفة (ج.م)',
                    required: true
                },
                {
                    type: 'number',
                    name: 'workHours',
                    label: 'ساعات العمل',
                    required: true
                },
                {
                    type: 'file',
                    name: 'images',
                    label: 'صور العمل المنجز',
                    multiple: true
                }
            ],
            onSubmit: async (data) => {
                try {
                    await this.simulateApiRequest();
                    const request = this.requests.get(requestId);
                    if (request) {
                        request.status = 'completed';
                        request.completionDetails = {
                            notes: data.completionNotes,
                            cost: data.cost,
                            workHours: data.workHours,
                            completedAt: new Date().toISOString()
                        };
                        request.timeline.push({
                            status: 'completed',
                            timestamp: new Date().toISOString(),
                            note: 'تم إنجاز الطلب'
                        });
                        
                        this.requests.set(requestId, request);
                        notifications.success('تم إنهاء الطلب بنجاح');
                        this.refreshRequestsList();
                    }
                } catch (error) {
                    notifications.error('حدث خطأ أثناء إنهاء الطلب');
                }
            }
        });
    }

    addNote(requestId) {
        modal.showForm({
            title: 'إضافة ملاحظة',
            fields: [
                {
                    type: 'textarea',
                    name: 'note',
                    label: 'الملاحظة',
                    required: true,
                    rows: 3
                }
            ],
            onSubmit: async (data) => {
                try {
                    await this.simulateApiRequest();
                    const request = this.requests.get(requestId);
                    if (request) {
                        request.timeline.push({
                            status: 'note',
                            timestamp: new Date().toISOString(),
                            note: data.note
                        });
                        
                        this.requests.set(requestId, request);
                        notifications.success('تمت إضافة الملاحظة بنجاح');
                        this.refreshRequestsList();
                    }
                } catch (error) {
                    notifications.error('حدث خطأ أثناء إضافة الملاحظة');
                }
            }
        });
    }

    renderTimeline(timeline) {
        if (!timeline || timeline.length === 0) {
            return '<p class="no-data">لا يوجد سجل للطلب</p>';
        }

        return `
            <div class="timeline">
                ${timeline.map(event => `
                    <div class="timeline-item">
                        <div class="timeline-icon ${event.status}">
                            <i class="fas ${this.getTimelineIcon(event.status)}"></i>
                        </div>
                        <div class="timeline-content">
                            <div class="timeline-time">
                                ${new Date(event.timestamp).toLocaleString('ar-EG')}
                            </div>
                            <div class="timeline-text">
                                ${event.note}
                            </div>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
    }

    getTimelineIcon(status) {
        const icons = {
            created: 'fa-plus-circle',
            assigned: 'fa-user-check',
            in_progress: 'fa-tools',
            completed: 'fa-check-circle',
            note: 'fa-comment',
            cancelled: 'fa-times-circle'
        };
        return icons[status] || 'fa-circle';
    }

    getCategoryIcon(category) {
        const icons = {
            plumbing: 'fa-faucet',
            electrical: 'fa-bolt',
            ac: 'fa-snowflake',
            carpentry: 'fa-hammer',
            painting: 'fa-paint-roller',
            other: 'fa-tools'
        };
        return icons[category] || 'fa-tools';
    }

    getCategoryLabel(category) {
        const labels = {
            plumbing: 'سباكة',
            electrical: 'كهرباء',
            ac: 'تكييف',
            carpentry: 'نجارة',
            painting: 'دهان',
            other: 'أخرى'
        };
        return labels[category] || category;
    }

    getPriorityLabel(priority) {
        const labels = {
            urgent: 'عاجل',
            high: 'مرتفع',
            medium: 'متوسط',
            low: 'منخفض'
        };
        return labels[priority] || priority;
    }

    getStatusLabel(status) {
        const labels = {
            pending: 'قيد الانتظار',
            assigned: 'تم التعيين',
            in_progress: 'قيد التنفيذ',
            completed: 'مكتمل',
            cancelled: 'ملغي'
        };
        return labels[status] || status;
    }

    // دوال مساعدة
    async getAvailableTechnicians() {
        await this.simulateApiRequest();
        return [
            { value: '1', label: 'أحمد علي - سباكة' },
            { value: '2', label: 'محمد حسن - كهرباء' },
            { value: '3', label: 'خالد محمود - تكييف' }
        ];
    }

    async getAvailableProperties() {
        await this.simulateApiRequest();
        return [
            { value: '1', label: 'شقة المعادي - الدور الثالث' },
            { value: '2', label: 'فيلا التجمع - 14' }
        ];
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

    async simulateApiRequest() {
        return new Promise(resolve => setTimeout(resolve, 1000));
    }
}

// تصدير مدير الصيانة
export const maintenanceManager = new MaintenanceManager();