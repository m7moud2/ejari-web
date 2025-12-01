/**
 * Property & Vehicle Details Manager
 * Handles dynamic loading of property and vehicle details
 */

const DetailsManager = {
    init: function () {
        const urlParams = new URLSearchParams(window.location.search);
        const id = urlParams.get('id');
        const type = urlParams.get('type') || 'property';

        if (!id) {
            alert('لم يتم تحديد العنصر');
            window.location.href = 'properties.html';
            return;
        }

        if (type === 'property') {
            this.loadPropertyDetails(id);
        } else if (type === 'vehicle') {
            this.loadVehicleDetails(id);
        }
    },

    loadPropertyDetails: function (id) {
        const properties = JSON.parse(localStorage.getItem('ejari_properties')) || [];
        const property = properties.find(p => p.id == id);

        if (!property) {
            alert('العقار غير موجود');
            window.location.href = 'properties.html';
            return;
        }

        // Update page title
        document.title = `${property.title} | إيجاري`;

        // Update main title
        const titleEl = document.querySelector('.property-nav-info h1');
        if (titleEl) titleEl.textContent = property.title;

        // Update property ID
        const idEl = document.querySelector('.property-id');
        if (idEl) idEl.textContent = `رقم العقار: #${property.id}`;

        // Update status badge
        const statusBadge = document.querySelector('.status-badge');
        if (statusBadge) {
            statusBadge.textContent = property.status === 'available' ? 'متاح' : 'مؤجر';
            statusBadge.className = `status-badge ${property.status === 'available' ? 'available' : 'rented'}`;
        }

        // Update main image
        const mainImage = document.querySelector('.main-image img');
        if (mainImage && property.images && property.images.length > 0) {
            mainImage.src = property.images[0];
        }

        // Update thumbnails
        const thumbnailsContainer = document.querySelector('.thumbnails');
        if (thumbnailsContainer && property.images) {
            const thumbnailsHTML = property.images.map((img, index) =>
                `<img src="${img}" alt="صورة ${index + 1}" class="${index === 0 ? 'active' : ''}" onclick="DetailsManager.changeMainImage('${img}')">`
            ).join('');
            thumbnailsContainer.innerHTML = thumbnailsHTML + `
                <button class="add-photo-btn">
                    <i class="fas fa-plus"></i>
                    <span>إضافة صور</span>
                </button>
            `;
        }

        // Update specs
        this.updatePropertySpecs(property);

        // Update financial info
        this.updateFinancialInfo(property);

        // Update location
        this.updateLocation(property);

        // Update tenant info if rented
        if (property.status !== 'available') {
            this.updateTenantInfo(property);
        } else {
            document.querySelector('.tenant-info').innerHTML = '<h2>معلومات المستأجر</h2><p style="text-align: center; color: #94a3b8; padding: 2rem;">العقار متاح للإيجار</p>';
        }
    },

    loadVehicleDetails: function (id) {
        const vehicles = JSON.parse(localStorage.getItem('ejari_vehicles')) || [];
        const vehicle = vehicles.find(v => v.id == id);

        if (!vehicle) {
            alert('السيارة غير موجودة');
            window.location.href = 'properties.html';
            return;
        }

        // Update page title
        document.title = `${vehicle.brand} ${vehicle.model} | إيجاري`;

        // Update main title
        const titleEl = document.querySelector('.property-nav-info h1');
        if (titleEl) titleEl.textContent = `${vehicle.brand} ${vehicle.model} ${vehicle.year}`;

        // Update vehicle ID
        const idEl = document.querySelector('.property-id');
        if (idEl) idEl.textContent = `رقم السيارة: #${vehicle.id}`;

        // Update status badge
        const statusBadge = document.querySelector('.status-badge');
        if (statusBadge) {
            statusBadge.textContent = vehicle.status === 'available' ? 'متاحة' : 'مؤجرة';
            statusBadge.className = `status-badge ${vehicle.status === 'available' ? 'available' : 'rented'}`;
        }

        // Update main image
        const mainImage = document.querySelector('.main-image img');
        if (mainImage && vehicle.images && vehicle.images.length > 0) {
            mainImage.src = vehicle.images[0];
        }

        // Update vehicle specs
        this.updateVehicleSpecs(vehicle);

        // Update rental info
        this.updateVehicleRentalInfo(vehicle);
    },

    updatePropertySpecs: function (property) {
        const specsContainer = document.querySelector('.property-specs');
        if (!specsContainer) return;

        specsContainer.innerHTML = `
            <div class="spec-item">
                <i class="fas fa-ruler-combined"></i>
                <div class="spec-details">
                    <span class="value">${property.area || 'N/A'}</span>
                    <span class="label">متر مربع</span>
                </div>
            </div>
            <div class="spec-item">
                <i class="fas fa-bed"></i>
                <div class="spec-details">
                    <span class="value">${property.bedrooms || 0}</span>
                    <span class="label">غرف نوم</span>
                </div>
            </div>
            <div class="spec-item">
                <i class="fas fa-bath"></i>
                <div class="spec-details">
                    <span class="value">${property.bathrooms || 0}</span>
                    <span class="label">حمام</span>
                </div>
            </div>
            <div class="spec-item">
                <i class="fas fa-car"></i>
                <div class="spec-details">
                    <span class="value">${property.parking || 0}</span>
                    <span class="label">موقف سيارات</span>
                </div>
            </div>
        `;

        // Update features
        const featuresList = document.querySelector('.features-list');
        if (featuresList && property.features) {
            featuresList.innerHTML = property.features.map(f =>
                `<li><i class="fas fa-check"></i> ${f}</li>`
            ).join('');
        }
    },

    updateVehicleSpecs: function (vehicle) {
        const specsContainer = document.querySelector('.property-specs');
        if (!specsContainer) return;

        specsContainer.innerHTML = `
            <div class="spec-item">
                <i class="fas fa-car"></i>
                <div class="spec-details">
                    <span class="value">${vehicle.brand}</span>
                    <span class="label">الماركة</span>
                </div>
            </div>
            <div class="spec-item">
                <i class="fas fa-calendar"></i>
                <div class="spec-details">
                    <span class="value">${vehicle.year}</span>
                    <span class="label">سنة الصنع</span>
                </div>
            </div>
            <div class="spec-item">
                <i class="fas fa-tachometer-alt"></i>
                <div class="spec-details">
                    <span class="value">${vehicle.mileage || 0}</span>
                    <span class="label">كم مقطوعة</span>
                </div>
            </div>
            <div class="spec-item">
                <i class="fas fa-cog"></i>
                <div class="spec-details">
                    <span class="value">${vehicle.transmission || 'أوتوماتيك'}</span>
                    <span class="label">ناقل الحركة</span>
                </div>
            </div>
        `;

        // Update features
        const featuresList = document.querySelector('.features-list');
        if (featuresList && vehicle.features) {
            featuresList.innerHTML = vehicle.features.map(f =>
                `<li><i class="fas fa-check"></i> ${f}</li>`
            ).join('');
        }
    },

    updateFinancialInfo: function (property) {
        const financialContainer = document.querySelector('.financial-details');
        if (!financialContainer) return;

        financialContainer.innerHTML = `
            <div class="financial-item">
                <span class="label">الإيجار الشهري</span>
                <span class="value">${property.price ? property.price.toLocaleString() : 'N/A'} ج.م</span>
            </div>
            <div class="financial-item">
                <span class="label">التأمين</span>
                <span class="value">${property.price ? (property.price * 2).toLocaleString() : 'N/A'} ج.م</span>
            </div>
            <div class="financial-item">
                <span class="label">مصاريف الصيانة السنوية</span>
                <span class="value">${property.price ? (property.price * 0.5).toLocaleString() : 'N/A'} ج.م</span>
            </div>
            <div class="financial-item">
                <span class="label">العائد السنوي</span>
                <span class="value positive">8.5%</span>
            </div>
        `;
    },

    updateVehicleRentalInfo: function (vehicle) {
        const financialContainer = document.querySelector('.financial-details');
        if (!financialContainer) return;

        financialContainer.innerHTML = `
            <div class="financial-item">
                <span class="label">الإيجار اليومي</span>
                <span class="value">${vehicle.pricePerDay ? vehicle.pricePerDay.toLocaleString() : 'N/A'} ج.م</span>
            </div>
            <div class="financial-item">
                <span class="label">التأمين</span>
                <span class="value">${vehicle.insurance || 500} ج.م</span>
            </div>
            <div class="financial-item">
                <span class="label">الحد الأدنى للإيجار</span>
                <span class="value">${vehicle.minDays || 1} يوم</span>
            </div>
            <div class="financial-item">
                <span class="label">الحد الأقصى للمسافة</span>
                <span class="value">${vehicle.maxKm || 200} كم/يوم</span>
            </div>
        `;
    },

    updateLocation: function (property) {
        const addressEl = document.querySelector('.address');
        if (addressEl) {
            addressEl.innerHTML = `<i class="fas fa-map-marker-alt"></i> ${property.location || property.address || 'غير محدد'}`;
        }
    },

    updateTenantInfo: function (property) {
        // Get bookings for this property
        const bookings = JSON.parse(localStorage.getItem('ejari_bookings')) || [];
        const activeBooking = bookings.find(b => b.propertyId == property.id && b.status === 'active');

        if (!activeBooking) {
            document.querySelector('.tenant-info').innerHTML = '<h2>معلومات المستأجر</h2><p style="text-align: center; color: #94a3b8; padding: 2rem;">لا توجد معلومات متاحة</p>';
            return;
        }

        // Get tenant info
        const users = JSON.parse(localStorage.getItem('ejari_users')) || [];
        const tenant = users.find(u => u.id === activeBooking.userId);

        if (!tenant) return;

        const tenantInfoContainer = document.querySelector('.current-tenant');
        if (tenantInfoContainer) {
            tenantInfoContainer.innerHTML = `
                <div class="tenant-header">
                    <img src="${tenant.avatar || 'images/default-avatar.jpg'}" alt="صورة المستأجر" class="tenant-avatar">
                    <div class="tenant-main-info">
                        <h3>${tenant.name}</h3>
                        <span class="tenant-since">مستأجر منذ: ${new Date(activeBooking.startDate).toLocaleDateString('ar-EG')}</span>
                    </div>
                    <button class="btn btn-outline btn-sm">
                        <i class="fas fa-user"></i>
                        عرض الملف
                    </button>
                </div>
                <div class="tenant-details">
                    <div class="contact-info">
                        <div class="contact-item">
                            <i class="fas fa-phone"></i>
                            <span>${tenant.phone || 'غير متوفر'}</span>
                        </div>
                        <div class="contact-item">
                            <i class="fas fa-envelope"></i>
                            <span>${tenant.email || 'غير متوفر'}</span>
                        </div>
                    </div>
                    <div class="lease-info">
                        <h4>معلومات العقد</h4>
                        <div class="lease-details">
                            <div class="detail-item">
                                <span class="label">تاريخ البداية</span>
                                <span class="value">${new Date(activeBooking.startDate).toLocaleDateString('ar-EG')}</span>
                            </div>
                            <div class="detail-item">
                                <span class="label">المدة</span>
                                <span class="value">${activeBooking.duration} ${activeBooking.durationUnit === 'months' ? 'شهر' : 'يوم'}</span>
                            </div>
                            <div class="detail-item">
                                <span class="label">حالة العقد</span>
                                <span class="status-badge active">ساري</span>
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }
    },

    changeMainImage: function (imageSrc) {
        const mainImage = document.querySelector('.main-image img');
        if (mainImage) {
            mainImage.src = imageSrc;
        }

        // Update active thumbnail
        document.querySelectorAll('.thumbnails img').forEach(img => {
            img.classList.remove('active');
            if (img.src === imageSrc) {
                img.classList.add('active');
            }
        });
    }
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    DetailsManager.init();
});