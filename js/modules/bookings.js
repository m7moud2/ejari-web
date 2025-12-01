// bookings.js
import { modal } from '../utils/modal.js';
import { notifications } from '../utils/notifications.js';

class BookingsManager {
    constructor() {
        this.bookings = new Map();
        this.initializeEventListeners();
    }

    initializeEventListeners() {
        // فلتر الحجوزات
        const filterSelect = document.querySelector('.bookings-filter');
        if (filterSelect) {
            filterSelect.addEventListener('change', (e) => this.filterBookings(e.target.value));
        }

        // البحث في الحجوزات
        const searchInput = document.querySelector('.bookings-search');
        if (searchInput) {
            searchInput.addEventListener('input', this.debounce((e) => 
                this.searchBookings(e.target.value), 300));
        }
    }

    showNewBookingModal() {
        modal.showForm({
            title: 'حجز جديد',
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
                    type: 'date',
                    name: 'startDate',
                    label: 'تاريخ البداية',
                    required: true
                },
                {
                    type: 'date',
                    name: 'endDate',
                    label: 'تاريخ النهاية',
                    required: true
                },
                {
                    type: 'number',
                    name: 'rentAmount',
                    label: 'قيمة الإيجار الشهري',
                    required: true
                },
                {
                    type: 'number',
                    name: 'depositAmount',
                    label: 'قيمة التأمين',
                    required: true
                },
                {
                    type: 'textarea',
                    name: 'notes',
                    label: 'ملاحظات',
                    rows: 3
                }
            ],
            onSubmit: (data) => this.createBooking(data)
        });
    }

    async createBooking(data) {
        try {
            await this.simulateApiRequest();
            const bookingId = Date.now();
            
            this.bookings.set(bookingId, {
                id: bookingId,
                ...data,
                status: 'pending',
                createdAt: new Date().toISOString()
            });

            notifications.success('تم إنشاء الحجز بنجاح');
            this.refreshBookingsList();
        } catch (error) {
            notifications.error('حدث خطأ أثناء إنشاء الحجز');
        }
    }

    async approveBooking(bookingId) {
        modal.showConfirmation({
            title: 'تأكيد الحجز',
            message: 'هل أنت متأكد من الموافقة على هذا الحجز؟',
            onConfirm: async () => {
                try {
                    await this.simulateApiRequest();
                    const booking = this.bookings.get(bookingId);
                    if (booking) {
                        booking.status = 'confirmed';
                        booking.approvedAt = new Date().toISOString();
                        this.bookings.set(bookingId, booking);
                        
                        notifications.success('تم تأكيد الحجز بنجاح');
                        this.refreshBookingsList();
                    }
                } catch (error) {
                    notifications.error('حدث خطأ أثناء تأكيد الحجز');
                }
            }
        });
    }

    async rejectBooking(bookingId) {
        modal.showForm({
            title: 'رفض الحجز',
            fields: [
                {
                    type: 'textarea',
                    name: 'rejectionReason',
                    label: 'سبب الرفض',
                    required: true,
                    rows: 3
                }
            ],
            onSubmit: async (data) => {
                try {
                    await this.simulateApiRequest();
                    const booking = this.bookings.get(bookingId);
                    if (booking) {
                        booking.status = 'rejected';
                        booking.rejectionReason = data.rejectionReason;
                        booking.rejectedAt = new Date().toISOString();
                        this.bookings.set(bookingId, booking);
                        
                        notifications.success('تم رفض الحجز');
                        this.refreshBookingsList();
                    }
                } catch (error) {
                    notifications.error('حدث خطأ أثناء رفض الحجز');
                }
            }
        });
    }

    viewBooking(bookingId) {
        const booking = this.bookings.get(bookingId);
        if (!booking) return;

        modal.show({
            title: `تفاصيل الحجز #${bookingId}`,
            content: `
                <div class="booking-details">
                    <div class="info-section">
                        <h3>معلومات العقار</h3>
                        <div class="property-info">
                            <img src="/api/placeholder/200/150" alt="صورة العقار">
                            <div>
                                <h4>${booking.propertyName}</h4>
                                <p>${booking.propertyLocation}</p>
                            </div>
                        </div>
                    </div>

                    <div class="info-section">
                        <h3>معلومات المستأجر</h3>
                        <div class="tenant-info">
                            <img src="/api/placeholder/50/50" alt="صورة المستأجر" class="avatar">
                            <div>
                                <h4>${booking.tenantName}</h4>
                                <p>${booking.tenantPhone}</p>
                                <p>${booking.tenantEmail}</p>
                            </div>
                        </div>
                    </div>

                    <div class="info-section">
                        <h3>تفاصيل الحجز</h3>
                        <dl class="details-list">
                            <dt>تاريخ البداية</dt>
                            <dd>${new Date(booking.startDate).toLocaleDateString('ar-EG')}</dd>
                            
                            <dt>تاريخ النهاية</dt>
                            <dd>${new Date(booking.endDate).toLocaleDateString('ar-EG')}</dd>
                            
                            <dt>قيمة الإيجار</dt>
                            <dd>${booking.rentAmount} ج.م/شهر</dd>
                            
                            <dt>قيمة التأمين</dt>
                            <dd>${booking.depositAmount} ج.م</dd>
                            
                            <dt>الحالة</dt>
                            <dd><span class="status-badge ${booking.status}">
                                ${this.getStatusLabel(booking.status)}
                            </span></dd>
                        </dl>
                    </div>

                    ${booking.notes ? `
                        <div class="info-section">
                            <h3>ملاحظات</h3>
                            <p>${booking.notes}</p>
                        </div>
                    ` : ''}
                </div>
            `,
            actions: this.getBookingActions(booking)
        });
    }

    getBookingActions(booking) {
        const actions = [
            {
                text: 'طباعة العقد',
                class: 'btn-outline',
                icon: 'print',
                onClick: () => this.printContract(booking.id)
            }
        ];

        if (booking.status === 'pending') {
            actions.unshift(
                {
                    text: 'موافقة',
                    class: 'btn-success',
                    icon: 'check',
                    onClick: () => this.approveBooking(booking.id)
                },
                {
                    text: 'رفض',
                    class: 'btn-danger',
                    icon: 'times',
                    onClick: () => this.rejectBooking(booking.id)
                }
            );
        }

        return actions;
    }

    filterBookings(status) {
        const bookingsContainer = document.querySelector('.bookings-table tbody');
        if (!bookingsContainer) return;

        if (status === 'all') {
            bookingsContainer.querySelectorAll('tr').forEach(row => {
                row.style.display = 'table-row';
            });
        } else {
            bookingsContainer.querySelectorAll('tr').forEach(row => {
                const rowStatus = row.dataset.status;
                row.style.display = rowStatus === status ? 'table-row' : 'none';
            });
        }
    }

    searchBookings(query) {
        const bookingsContainer = document.querySelector('.bookings-table tbody');
        if (!bookingsContainer) return;

        const searchTerm = query.toLowerCase();
        bookingsContainer.querySelectorAll('tr').forEach(row => {
            const text = row.textContent.toLowerCase();
            row.style.display = text.includes(searchTerm) ? 'table-row' : 'none';
        });
    }

    refreshBookingsList() {
        const container = document.querySelector('.bookings-table tbody');
        if (!container) return;

        container.innerHTML = '';
        this.bookings.forEach(booking => {
            container.appendChild(this.createBookingRow(booking));
        });
    }

    createBookingRow(booking) {
        const row = document.createElement('tr');
        row.dataset.status = booking.status;
        
        row.innerHTML = `
            <td>#${booking.id}</td>
            <td class="property-cell">
                <div class="property-info">
                    <img src="/api/placeholder/40/40" alt="عقار">
                    <span>${booking.propertyName}</span>
                </div>
            </td>
            <td class="tenant-cell">
                <div class="tenant-info">
                    <img src="/api/placeholder/40/40" alt="مستأجر">
                    <span>${booking.tenantName}</span>
                </div>
            </td>
            <td>${new Date(booking.startDate).toLocaleDateString('ar-EG')}</td>
            <td>${new Date(booking.endDate).toLocaleDateString('ar-EG')}</td>
            <td>${booking.rentAmount} ج.م</td>
            <td>
                <span class="status-badge ${booking.status}">
                    ${this.getStatusLabel(booking.status)}
                </span>
            </td>
            <td>
                <div class="actions">
                    ${this.getRowActions(booking)}
                </div>
            </td>
        `;

        return row;
    }

    getRowActions(booking) {
        let actions = `
            <button class="btn btn-icon" onclick="bookingsManager.viewBooking(${booking.id})">
                <i class="fas fa-eye"></i>
            </button>
        `;

        if (booking.status === 'pending') {
            actions += `
                <button class="btn btn-icon success" onclick="bookingsManager.approveBooking(${booking.id})">
                    <i class="fas fa-check"></i>
                </button>
                <button class="btn btn-icon danger" onclick="bookingsManager.rejectBooking(${booking.id})">
                    <i class="fas fa-times"></i>
                </button>
            `;
        }

        if (booking.status === 'confirmed') {
            actions += `
                <button class="btn btn-icon" onclick="bookingsManager.printContract(${booking.id})">
                    <i class="fas fa-print"></i>
                </button>
            `;
        }

        return actions;
    }

    getStatusLabel(status) {
        const labels = {
            pending: 'قيد المراجعة',
            confirmed: 'مؤكد',
            rejected: 'مرفوض',
            cancelled: 'ملغي',
            completed: 'مكتمل'
        };
        return labels[status] || status;
    }

    async printContract(bookingId) {
        try {
            await this.simulateApiRequest();
            notifications.success('جاري تحميل العقد...');
            // هنا يمكن إضافة منطق طباعة العقد
        } catch (error) {
            notifications.error('حدث خطأ أثناء تحميل العقد');
        }
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
        // محاكاة جلب العقارات المتاحة
        return [
            { value: '1', label: 'شقة في المعادي' },
            { value: '2', label: 'فيلا في التجمع' }
        ];
    }

    getAvailableTenants() {
        // محاكاة جلب المستأجرين
        return [
            { value: '1', label: 'أحمد محمود' },
            { value: '2', label: 'سارة أحمد' }
        ];
    }
}

// تصدير مدير الحجوزات
export const bookingsManager = new BookingsManager();
class BookingManager {
    constructor() {
        this.bookingModal = document.getElementById('bookingModal');
        this.bookingForm = document.getElementById('bookingForm');
        this.init();
    }

    init() {
        this.bookingForm.addEventListener('submit', this.handleSubmit.bind(this));
        this.initializeValidation();
    }

    async handleSubmit(e) {
        e.preventDefault();
        
        try {
            const formData = this.getFormData();
            const response = await this.submitBooking(formData);
            
            if (response.success) {
                showNotification('success', 'تم إنشاء الحجز بنجاح');
                this.closeModal();
                // تحديث واجهة المستخدم
                window.location.href = `/bookings/${response.data._id}`;
            }
        } catch (error) {
            showNotification('error', error.message);
        }
    }

    getFormData() {
        return {
            propertyId: this.bookingForm.dataset.propertyId,
            startDate: document.getElementById('startDate').value,
            duration: parseInt(document.getElementById('durationValue').value),
            durationUnit: this.getCurrentDurationUnit(),
            totalAmount: this.calculateTotalAmount()
        };
    }

    async submitBooking(data) {
        const response = await fetch('/api/bookings', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify(data)
        });

        return await response.json();
    }

    initializeValidation() {
        // تحقق من صحة المدخلات
        const startDateInput = document.getElementById('startDate');
        const durationInput = document.getElementById('durationValue');
        
        startDateInput.addEventListener('change', () => {
            this.validateDates();
            this.updateEndDate();
        });

        durationInput.addEventListener('change', () => {
            this.validateDuration();
            this.updateEndDate();
            this.calculateTotal();
        });
    }

    validateDates() {
        const startDate = new Date(document.getElementById('startDate').value);
        const today = new Date();
        
        if (startDate < today) {
            throw new Error('تاريخ البداية يجب أن يكون في المستقبل');
        }
    }

    validateDuration() {
        const duration = parseInt(document.getElementById('durationValue').value);
        const maxDurations = {
            days: 90,
            weeks: 12,
            months: 12,
            years: 5
        };

        const currentUnit = this.getCurrentDurationUnit();
        if (duration > maxDurations[currentUnit]) {
            throw new Error(`المدة يجب أن لا تتجاوز ${maxDurations[currentUnit]} ${currentUnit}`);
        }
    }
}

// تهيئة النظام
document.addEventListener('DOMContentLoaded', () => {
    const bookingManager = new BookingManager();
    window.bookingManager = bookingManager; // للوصول العالمي
});
// models/Booking.js
const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
    property: {
        type: mongoose.Schema.ObjectId,
        ref: 'Property',
        required: true
    },
    user: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: true
    },
    startDate: {
        type: Date,
        required: true
    },
    endDate: {
        type: Date,
        required: true
    },
    duration: {
        type: Number,
        required: true
    },
    durationUnit: {
        type: String,
        enum: ['days', 'weeks', 'months', 'years'],
        required: true
    },
    totalAmount: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'cancelled', 'completed'],
        default: 'pending'
    },
    paymentStatus: {
        type: String,
        enum: ['pending', 'paid', 'refunded'],
        default: 'pending'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// التحقق من توفر العقار قبل الحفظ
bookingSchema.pre('save', async function(next) {
    const overlappingBooking = await this.constructor.findOne({
        property: this.property,
        status: { $nin: ['cancelled'] },
        $or: [
            {
                startDate: { $lte: this.startDate },
                endDate: { $gte: this.startDate }
            },
            {
                startDate: { $lte: this.endDate },
                endDate: { $gte: this.endDate }
            }
        ]
    });

    if (overlappingBooking) {
        throw new Error('العقار غير متاح في هذه الفترة');
    }

    next();
});

module.exports = mongoose.model('Booking', bookingSchema);