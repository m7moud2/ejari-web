/**
 * Booking Modal Manager
 * Handles the logic for property and car booking modals
 */

const BookingManager = {
    basePrice: 0,
    currentDuration: 1,
    currentUnit: 'days',
    totalCost: 0,
    itemType: 'property', // 'property' or 'car'

    init: function () {
        this.setupEventListeners();
        // Set default date to today
        const today = new Date().toISOString().split('T')[0];
        const dateInput = document.getElementById('startDate');
        if (dateInput) {
            dateInput.value = today;
            dateInput.min = today;
        }
    },

    setupEventListeners: function () {
        // Duration tabs
        document.querySelectorAll('.duration-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                document.querySelectorAll('.duration-tab').forEach(t => t.classList.remove('active'));
                e.target.classList.add('active');
                this.currentUnit = e.target.dataset.unit;
                this.updateDurationLabel();
                this.calculateTotal();
            });
        });
    },

    open: function (title, price, image, type = 'property') {
        const modal = document.getElementById('bookingModal');
        if (!modal) return;

        this.itemType = type;

        // Handle localization
        if (typeof LocalizationManager !== 'undefined') {
            // Assume input price is in EGP (default for properties)
            // Convert to SAR for internal calculation if needed, or just use EGP and let LocalizationManager handle display
            // Better: Store base price in SAR for consistent conversion
            // 1 SAR = 12.5 EGP
            this.basePriceSAR = (parseInt(price) || 0) / 12.5;
            this.basePrice = parseInt(price) || 0;

            // Update base price display with data-price
            const priceEl = modal.querySelector('.base-price .price');
            priceEl.setAttribute('data-price', this.basePriceSAR);
            priceEl.textContent = LocalizationManager.formatPrice(this.basePriceSAR);
        } else {
            this.basePrice = parseInt(price) || 0;
            this.basePriceSAR = this.basePrice;
            modal.querySelector('.base-price .price').textContent = this.basePrice.toLocaleString();
        }

        // Update UI
        modal.querySelector('.property-info h4').textContent = title || 'عنصر غير معروف';

        if (image) {
            modal.querySelector('.property-summary img').src = image;
        }

        // Adjust labels based on type
        const periodLabel = type === 'car' ? '/يوم' : '/شهر';
        modal.querySelector('.base-price .period').textContent = periodLabel;

        // Reset defaults
        this.currentDuration = 1;
        document.getElementById('durationValue').value = 1;

        // Show modal
        modal.style.display = 'flex';
        this.calculateTotal();
        this.updateEndDate();
    },

    close: function () {
        const modal = document.getElementById('bookingModal');
        if (modal) modal.style.display = 'none';
    },

    updateDuration: function (change) {
        let newValue = parseInt(document.getElementById('durationValue').value) + change;
        if (newValue < 1) newValue = 1;
        document.getElementById('durationValue').value = newValue;
        this.currentDuration = newValue;
        this.calculateTotal();
        this.updateEndDate();
    },

    updateDurationLabel: function () {
        const labels = {
            'days': 'يوم',
            'weeks': 'أسبوع',
            'months': 'شهر',
            'years': 'سنة'
        };
        document.getElementById('durationLabel').textContent = labels[this.currentUnit];
    },

    calculateTotal: function () {
        this.currentDuration = parseInt(document.getElementById('durationValue').value) || 1;

        // Multipliers based on unit
        const multipliers = {
            'days': 1 / 30, // Assuming base price is monthly for properties, daily for cars needs adjustment
            'weeks': 0.25,
            'months': 1,
            'years': 12
        };

        let multiplier = multipliers[this.currentUnit];

        // If it's a car, base price is usually daily
        if (this.itemType === 'car') {
            const carMultipliers = {
                'days': 1,
                'weeks': 7,
                'months': 30,
                'years': 365
            };
            multiplier = carMultipliers[this.currentUnit];
        }

        const rentCostSAR = Math.round(this.basePriceSAR * this.currentDuration * multiplier);
        const insuranceSAR = Math.round(rentCostSAR * 0.10);
        const serviceFeeSAR = Math.round(rentCostSAR * 0.05);
        const totalCostSAR = rentCostSAR + insuranceSAR + serviceFeeSAR;

        this.rentCostSAR = rentCostSAR;
        this.insuranceSAR = insuranceSAR;
        this.serviceFeeSAR = serviceFeeSAR;
        this.totalCost = totalCostSAR; // Store in SAR

        // Update UI with localization
        if (typeof LocalizationManager !== 'undefined') {
            const updateElement = (id, priceSAR) => {
                const el = document.getElementById(id);
                // Create inner span if not exists or use existing
                let amountSpan = el.querySelector('.price-amount');
                if (!amountSpan) {
                    el.innerHTML = `<span class="price-amount" data-price="${priceSAR}">${LocalizationManager.formatPrice(priceSAR)}</span>`;
                } else {
                    amountSpan.setAttribute('data-price', priceSAR);
                    el.innerHTML = `<span class="price-amount" data-price="${priceSAR}">${LocalizationManager.formatPrice(priceSAR)}</span>`;
                }
            };

            updateElement('rentCost', rentCostSAR);
            updateElement('insurance', insuranceSAR);
            updateElement('serviceFee', serviceFeeSAR);
            updateElement('totalCost', totalCostSAR);
        } else {
            // Fallback to EGP
            const rentCost = Math.round(this.basePrice * this.currentDuration * multiplier);
            const insurance = Math.round(rentCost * 0.10);
            const serviceFee = Math.round(rentCost * 0.05);
            this.totalCost = rentCost + insurance + serviceFee;

            document.getElementById('rentCost').textContent = rentCost.toLocaleString() + ' ج.م';
            document.getElementById('insurance').textContent = insurance.toLocaleString() + ' ج.م';
            document.getElementById('serviceFee').textContent = serviceFee.toLocaleString() + ' ج.م';
            document.getElementById('totalCost').textContent = this.totalCost.toLocaleString() + ' ج.م';
        }
    },

    updateEndDate: function () {
        const startDateStr = document.getElementById('startDate').value;
        if (!startDateStr) return;

        const startDate = new Date(startDateStr);
        const endDate = new Date(startDate);

        // Add duration
        if (this.currentUnit === 'days') endDate.setDate(startDate.getDate() + this.currentDuration);
        if (this.currentUnit === 'weeks') endDate.setDate(startDate.getDate() + (this.currentDuration * 7));
        if (this.currentUnit === 'months') endDate.setMonth(startDate.getMonth() + this.currentDuration);
        if (this.currentUnit === 'years') endDate.setFullYear(startDate.getFullYear() + this.currentDuration);

        // Update preview
        document.getElementById('startDatePreview').textContent = startDate.toLocaleDateString('ar-EG');
        document.getElementById('endDatePreview').textContent = endDate.toLocaleDateString('ar-EG');
    },

    confirmBooking: function () {
        // تجميع بيانات الحجز
        const durationUnit = document.querySelector('.duration-tab.active').dataset.unit;
        const durationValue = parseInt(document.getElementById('durationValue').value) || 1;
        const isMonthlyStyle = durationUnit === 'months' || durationUnit === 'years';
        const monthlyBase = this.itemType === 'car'
            ? this.basePrice
            : this.basePrice;
        const monthsCount = durationUnit === 'years' ? durationValue * 12 : durationUnit === 'months' ? durationValue : 1;
        const rentPerMonth = this.itemType === 'car' ? monthlyBase : this.basePrice;
        const totalRent = this.itemType === 'car' ? this.totalCost : rentPerMonth * monthsCount;
        const depositAmount = isMonthlyStyle ? Math.max(1000, Math.round(rentPerMonth * 0.1)) : this.insuranceSAR || 0;
        const dueNow = isMonthlyStyle ? depositAmount : this.totalCost;
        const remainingBalance = isMonthlyStyle ? Math.max(0, totalRent - depositAmount) : 0;
        const bookingData = {
            id: Date.now(),
            itemTitle: document.querySelector('.property-info h4').textContent,
            itemImage: document.querySelector('.property-summary img').src,
            location: document.querySelector('.property-info .location').textContent.trim(),
            startDate: document.getElementById('startDate').value,
            duration: durationValue,
            durationUnit,
            price: rentPerMonth,
            serviceFee: this.serviceFeeSAR,
            deposit: depositAmount,
            totalCost: dueNow,
            totalRent,
            remainingBalance,
            paymentMode: isMonthlyStyle ? 'deposit_then_monthly' : 'full',
            installmentPlan: isMonthlyStyle ? {
                monthsCount,
                rentPerMonth,
                depositAmount,
                remainingBalance,
                dueNow
            } : null,
            status: 'pending',
            type: this.itemType
        };

        if (!bookingData.startDate) {
            alert('الرجاء اختيار تاريخ البداية');
            return;
        }

        // حفظ البيانات في LocalStorage
        localStorage.setItem('currentBooking', JSON.stringify(bookingData));

        // إغلاق المودال
        this.close();

        // توجيه لمسار التحقق الموحد (للعقارات والسيارات)
        if (typeof VerificationManager !== 'undefined') {
            VerificationManager.start(this.itemType);
        } else {
            console.error('VerificationManager not found');
            window.location.href = 'payment.html';
        }
    }
};

// Global functions
function openBookingModal(title, price, image, type = 'property') {
    BookingManager.open(title, price, image, type);
}

function closeBookingModal() {
    BookingManager.close();
}

function increaseDuration() {
    BookingManager.updateDuration(1);
}

function decreaseDuration() {
    BookingManager.updateDuration(-1);
}

function calculateTotal() {
    BookingManager.calculateTotal();
}

function updateEndDate() {
    BookingManager.updateEndDate();
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    BookingManager.init();
});
