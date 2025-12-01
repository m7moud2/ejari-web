// bookings.js

class BookingManager {
    constructor() {
        this.bookings = new Map();
        this.initializeEventListeners();
    }

    initializeEventListeners() {
        // تهيئة أزرار الحجز
        document.querySelectorAll('.btn-primary[onclick^="addToCart"]').forEach(button => {
            button.onclick = (e) => {
                e.preventDefault();
                const propertyId = button.getAttribute('onclick').match(/\d+/)[0];
                this.showBookingModal(propertyId);
            };
        });

        // تهيئة أزرار التفاصيل
        document.querySelectorAll('.btn-outline').forEach(button => {
            button.onclick = (e) => {
                e.preventDefault();
                const propertyCard = button.closest('.property-card');
                const propertyId = propertyCard.dataset.id;
                this.showPropertyDetails(propertyId);
            };
        });
    }

    showBookingModal(propertyId) {
        // جلب بيانات العقار
        const property = this.getPropertyDetails(propertyId);
        
        modal.showForm({
            title: 'حجز عقار',
            size: 'large',
            fields: [
                {
                    type: 'hidden',
                    name: 'propertyId',
                    value: propertyId
                },
                {
                    type: 'text',
                    name: 'fullName',
                    label: 'الاسم الكامل',
                    required: true,
                    placeholder: 'أدخل اسمك الكامل'
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
                    type: 'date',
                    name: 'preferredDate',
                    label: 'التاريخ المفضل للمعاينة',
                    required: true,
                    min: new Date().toISOString().split('T')[0]
                },
                {
                    type: 'select',
                    name: 'visitTime',
                    label: 'وقت المعاينة المفضل',
                    required: true,
                    options: [
                        { value: 'morning', label: 'صباحاً (9 - 12)' },
                        { value: 'afternoon', label: 'ظهراً (12 - 3)' },
                        { value: 'evening', label: 'مساءً (3 - 6)' }
                    ]
                },
                {
                    type: 'textarea',
                    name: 'notes',
                    label: 'ملاحظات إضافية',
                    rows: 3
                }
            ],
            content: `
                <div class="booking-summary">
                    <h3>تفاصيل العقار</h3>
                    <div class="property-summary">
                        <img src="${property.image}" alt="${property.title}">
                        <div class="summary-details">
                            <h4>${property.title}</h4>
                            <p class="location">${property.location}</p>
                            <div class="price">
                                <span class="amount">${property.price}</span>
                                <span class="period">/ شهرياً</span>
                            </div>
                        </div>
                    </div>
                </div>
            `,
            actions: [
                {
                    text: 'تأكيد الحجز',
                    class: 'btn-primary',
                    onClick: async (data) => {
                        try {
                            await this.processBooking(data);
                            notifications.success('تم إرسال طلب الحجز بنجاح');
                            modal.close();
                            this.sendBookingConfirmation(data.email, {
                                propertyTitle: property.title,
                                visitDate: data.preferredDate,
                                visitTime: this.getTimeLabel(data.visitTime)
                            });
                        } catch (error) {
                            notifications.error('حدث خطأ أثناء إرسال طلب الحجز');
                        }
                    }
                },
                {
                    text: 'إلغاء',
                    class: 'btn-outline',
                    onClick: 'close'
                }
            ]
        });
    }

    showPropertyDetails(propertyId) {
        // تحويل المستخدم إلى صفحة تفاصيل العقار
        window.location.href = `property-details.html?id=${propertyId}`;
    }

    async processBooking(bookingData) {
        try {
            const bookingId = `BK${Date.now()}`;
            const booking = {
                id: bookingId,
                ...bookingData,
                status: 'pending',
                createdAt: new Date().toISOString()
            };

            // إضافة الحجز إلى القائمة
            this.bookings.set(bookingId, booking);

            // تحديث حالة العقار
            this.updatePropertyStatus(bookingData.propertyId, 'pending');

            // إرسال إشعار للمالك
            this.notifyOwner(booking);

            return booking;
        } catch (error) {
            throw new Error('فشل في معالجة الحجز');
        }
    }

    sendBookingConfirmation(email, bookingDetails) {
        // إرسال بريد تأكيد الحجز
        notifications.info('تم إرسال تفاصيل الحجز إلى بريدك الإلكتروني');
    }

    getTimeLabel(timeSlot) {
        const labels = {
            morning: 'صباحاً (9 - 12)',
            afternoon: 'ظهراً (12 - 3)',
            evening: 'مساءً (3 - 6)'
        };
        return labels[timeSlot];
    }

    notifyOwner(booking) {
        // إرسال إشعار للمالك بالحجز الجديد
    }

    getPropertyDetails(propertyId) {
        // هنا يمكنك استبدال هذا بجلب البيانات من الخادم
        return {
            id: propertyId,
            title: 'شقة في المعادي',
            location: 'المعادي، القاهرة',
            price: '12,000 ج.م',
            image: '/api/placeholder/200/150',
            features: ['3 غرف نوم', '2 حمام', 'مطبخ مجهز'],
            status: 'available'
        };
    }

    updatePropertyStatus(propertyId, status) {
        // تحديث حالة العقار في قاعدة البيانات
    }
}

// تهيئة النظام
const bookingManager = new BookingManager();
export default bookingManager;