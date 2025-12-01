// الإعدادات العامة
const CONFIG = {
    MIN_INSTALLMENT_AMOUNT: 1000,
    MAX_INSTALLMENT_MONTHS: 60,
    SAVED_CARDS_KEY: 'savedPaymentMethods',
    PAYMENT_ATTEMPT_TIMEOUT: 30000 // 30 seconds timeout
};

// تعريف أنواع وسائل الدفع
const PAYMENT_TYPES = {
    CREDIT_CARD: 'credit-card',
    WALLET: 'wallet',
    INSTALLMENT: 'installment',
    CASH_SERVICES: 'cash-services'
};

// إدارة النماذج المختلفة لوسائل الدفع
const paymentForms = {
    'credit-card': { type: PAYMENT_TYPES.CREDIT_CARD, form: 'card-form' },
    'mastercard': { type: PAYMENT_TYPES.CREDIT_CARD, form: 'card-form' },
    'meza': { type: PAYMENT_TYPES.CREDIT_CARD, form: 'card-form' },
    'vodafone-cash': { type: PAYMENT_TYPES.WALLET, form: 'mobile-wallet-form' },
    'etisalat-cash': { type: PAYMENT_TYPES.WALLET, form: 'mobile-wallet-form' },
    'orange-cash': { type: PAYMENT_TYPES.WALLET, form: 'mobile-wallet-form' },
    'we-pay': { type: PAYMENT_TYPES.WALLET, form: 'mobile-wallet-form' },
    'fawry': { type: PAYMENT_TYPES.CASH_SERVICES, form: 'fawry-form' },
    'aman': { type: PAYMENT_TYPES.CASH_SERVICES, form: 'aman-form' },
    'premium': { type: PAYMENT_TYPES.INSTALLMENT, form: 'installment-form' },
    'forsa': { type: PAYMENT_TYPES.INSTALLMENT, form: 'installment-form' },
    'valu': { type: PAYMENT_TYPES.INSTALLMENT, form: 'installment-form' },
    'sympl': { type: PAYMENT_TYPES.INSTALLMENT, form: 'installment-form' }
};

// حفظ التفضيلات والبطاقات المحفوظة
class PaymentPreferences {
    static getSavedCards() {
        const saved = localStorage.getItem(CONFIG.SAVED_CARDS_KEY);
        return saved ? JSON.parse(saved) : [];
    }

    static saveCard(cardData) {
        const saved = this.getSavedCards();
        // تشفير بيانات البطاقة قبل الحفظ
        const encryptedCard = this.encryptCardData(cardData);
        saved.push(encryptedCard);
        localStorage.setItem(CONFIG.SAVED_CARDS_KEY, JSON.stringify(saved));
    }

    static encryptCardData(cardData) {
        // تشفير بسيط للبيانات (في التطبيق الحقيقي يجب استخدام تشفير قوي)
        return {
            ...cardData,
            number: `**** **** **** ${cardData.number.slice(-4)}`,
            savedAt: new Date().toISOString()
        };
    }
}

// التحقق من صحة البطاقة
class CardValidator {
    static luhnCheck(cardNumber) {
        let sum = 0;
        let isEven = false;
        
        // الخوارزمية المعروفة باسم Luhn algorithm للتحقق من صحة رقم البطاقة
        for (let i = cardNumber.length - 1; i >= 0; i--) {
            let digit = parseInt(cardNumber[i]);

            if (isEven) {
                digit *= 2;
                if (digit > 9) {
                    digit -= 9;
                }
            }

            sum += digit;
            isEven = !isEven;
        }

        return sum % 10 === 0;
    }

    static validateExpiryDate(expiryDate) {
        const [month, year] = expiryDate.split('/').map(num => parseInt(num));
        const now = new Date();
        const expiry = new Date(2000 + year, month - 1);
        return expiry > now;
    }

    static getCardType(cardNumber) {
        // التعرف على نوع البطاقة من خلال الأرقام الأولى
        const patterns = {
            visa: /^4/,
            mastercard: /^5[1-5]/,
            meza: /^507/
        };

        for (const [type, pattern] of Object.entries(patterns)) {
            if (pattern.test(cardNumber)) {
                return type;
            }
        }
        return 'unknown';
    }
}

// معالج التقسيط
class InstallmentCalculator {
    static calculateInstallments(totalAmount, months) {
        if (totalAmount < CONFIG.MIN_INSTALLMENT_AMOUNT) {
            throw new Error(`المبلغ أقل من الحد الأدنى للتقسيط (${CONFIG.MIN_INSTALLMENT_AMOUNT} جنيه)`);
        }

        if (months > CONFIG.MAX_INSTALLMENT_MONTHS) {
            throw new Error(`عدد الأشهر يتجاوز الحد الأقصى (${CONFIG.MAX_INSTALLMENT_MONTHS} شهر)`);
        }

        const interestRates = {
            premium: 0.15, // 15% سنوياً
            forsa: 0.18,
            valu: 0.20,
            sympl: 0.16
        };

        const plans = {};
        for (const [provider, rate] of Object.entries(interestRates)) {
            const monthlyRate = rate / 12;
            const monthlyPayment = (totalAmount * monthlyRate * Math.pow(1 + monthlyRate, months)) / 
                                 (Math.pow(1 + monthlyRate, months) - 1);
            
            plans[provider] = {
                monthlyPayment: Math.round(monthlyPayment * 100) / 100,
                totalAmount: Math.round(monthlyPayment * months * 100) / 100,
                interestAmount: Math.round((monthlyPayment * months - totalAmount) * 100) / 100,
                months: months
            };
        }

        return plans;
    }
}

// إدارة المحفظة الإلكترونية
class WalletManager {
    static validatePhoneNumber(phone) {
        // التحقق من صحة رقم الهاتف المصري
        return /^01[0125][0-9]{8}$/.test(phone);
    }

    static async requestOTP(phone, provider) {
        // محاكاة طلب رمز التحقق
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({ success: true, message: 'تم إرسال رمز التحقق' });
            }, 1000);
        });
    }
}

// معالجة الأخطاء
class PaymentError extends Error {
    constructor(message, code) {
        super(message);
        this.code = code;
        this.name = 'PaymentError';
    }
}

// التهيئة عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', function() {
    initializePaymentSystem();
    loadSavedCards();
    setupEventListeners();
});

// تهيئة نظام الدفع
function initializePaymentSystem() {
    createPaymentForms();
    setupCardScanner();
    initializeInstallmentCalculator();
}

// إنشاء النماذج الديناميكية
function createPaymentForms() {
    // إنشاء نموذج التقسيط
    const installmentForm = `
        <div class="payment-form" id="installment-form" style="display: none;">
            <div class="form-group">
                <label>عدد الأشهر</label>
                <select id="installment-months">
                    ${[6, 12, 24, 36].map(m => `<option value="${m}">${m} شهر</option>`).join('')}
                </select>
            </div>
            <div id="installment-plans"></div>
        </div>
    `;

    // إنشاء نموذج المحفظة الإلكترونية
    const walletForm = `
        <div class="payment-form" id="mobile-wallet-form" style="display: none;">
            <div class="form-group">
                <label>رقم الهاتف</label>
                <input type="tel" id="wallet-phone" placeholder="01xxxxxxxxx" maxlength="11">
            </div>
            <div class="form-group">
                <label>رمز التحقق</label>
                <div class="otp-group">
                    <input type="text" id="wallet-otp" placeholder="______" maxlength="6">
                    <button type="button" id="request-otp">طلب الرمز</button>
                </div>
            </div>
        </div>
    `;

    // إضافة النماذج للصفحة
    const formsContainer = document.createElement('div');
    formsContainer.innerHTML = installmentForm + walletForm;
    document.querySelector('.payment-methods').appendChild(formsContainer);
}

// إعداد مستمعي الأحداث
function setupEventListeners() {
    // مستمعي أحداث وسائل الدفع
    document.querySelectorAll('input[name="payment-method"]').forEach(option => {
        option.addEventListener('change', handlePaymentMethodChange);
    });

    // مستمع حدث طلب رمز التحقق
    const otpButton = document.getElementById('request-otp');
    if (otpButton) {
        otpButton.addEventListener('click', async () => {
            const phone = document.getElementById('wallet-phone').value;
            if (WalletManager.validatePhoneNumber(phone)) {
                try {
                    otpButton.disabled = true;
                    const result = await WalletManager.requestOTP(phone);
                    showToast(result.message, 'success');
                    startOTPCountdown(otpButton);
                } catch (error) {
                    showToast(error.message, 'error');
                }
            } else {
                showToast('رقم الهاتف غير صحيح', 'error');
            }
        });
    }

    // مستمع حدث تغيير عدد أشهر التقسيط
    const monthsSelect = document.getElementById('installment-months');
    if (monthsSelect) {
        monthsSelect.addEventListener('change', updateInstallmentPlans);
    }
}

// تحديث خطط التقسيط
function updateInstallmentPlans() {
    const months = parseInt(document.getElementById('installment-months').value);
    const totalAmount = parseFloat(document.querySelector('.total span:last-child').textContent);
    
    try {
        const plans = InstallmentCalculator.calculateInstallments(totalAmount, months);
        const plansContainer = document.getElementById('installment-plans');
        
        plansContainer.innerHTML = Object.entries(plans).map(([provider, plan]) => `
            <div class="installment-plan">
                <h4>${provider}</h4>
                <p>القسط الشهري: ${plan.monthlyPayment} جنيه</p>
                <p>إجمالي المبلغ: ${plan.totalAmount} جنيه</p>
                <p>قيمة الفائدة: ${plan.interestAmount} جنيه</p>
            </div>
        `).join('');
    } catch (error) {
        showToast(error.message, 'error');
    }
}

// عرض رسائل للمستخدم
function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    
    setTimeout(() => {
        toast.classList.add('show');
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => toast.remove(), 300);
        }, 3000);
    }, 100);
}

// عد تنازلي لرمز التحقق
function startOTPCountdown(button) {
    let seconds = 60;
    const originalText = button.textContent;
    
    const countdown = setInterval(() => {
        seconds--;
        button.textContent = `انتظر (${seconds})`;
        
        if (seconds <= 0) {
            clearInterval(countdown);
            button.textContent = originalText;
            button.disabled = false;
        }
    }, 1000);
}

// معالجة الدفع الآمن
async function processSecurePayment(paymentData) {
    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), CONFIG.PAYMENT_ATTEMPT_TIMEOUT);

        const response = await fetch('/api/process-payment', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Security-Token': generateSecurityToken()
            },
            body: JSON.stringify(paymentData),
            signal: controller.signal
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
            throw new PaymentError('فشلت عملية الدفع', response.status);
        }

        const result = await response.json();
        return result;
    } catch (error) {
        if (error.name === 'AbortError') {
            throw new PaymentError('انتهت مهلة عملية الدفع', 'TIMEOUT');
        }
        throw error;
    }
}

// إنشاء رمز أمان للعملية
function generateSecurityToken() {
    return btoa(Date.now() + Math.random().toString(36).substr(2));
}

// مسح بيانات البطاقة
class CardScanner {
    static async scanCard() {
        // محاكاة مسح البطاقة
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    number: '4111111111111111',
                    expiry: '12/25',
                    holder: 'John Doe'
                });
            }, 2000);
        });
    }
}

// إعداد ماسح البطاقة
// إكمال دالة إعداد ماسح البطاقة
function setupCardScanner() {
    const scanButton = document.createElement('button');
    scanButton.className = 'scan-card-btn';
    scanButton.innerHTML = '<i class="fas fa-camera"></i> مسح البطاقة';
    
    const cardForm = document.getElementById('card-form');
    if (cardForm) {
        cardForm.insertBefore(scanButton, cardForm.firstChild);
        
        scanButton.addEventListener('click', async () => {
            try {
                scanButton.disabled = true;
                scanButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري المسح...';
                
                const cardData = await CardScanner.scanCard();
                
                // ملء بيانات البطاقة
                document.getElementById('card-number').value = cardData.number;
                document.getElementById('expiry-date').value = cardData.expiry;
                document.getElementById('card-holder').value = cardData.holder;
                
                showToast('تم مسح البطاقة بنجاح', 'success');
            } catch (error) {
                showToast('فشل مسح البطاقة', 'error');
            } finally {
                scanButton.disabled = false;
                scanButton.innerHTML = '<i class="fas fa-camera"></i> مسح البطاقة';
            }
        });
    }
}

// تحسين تجربة المستخدم مع التقسيط
class InstallmentUI {
    static createComparisonChart(plans) {
        const canvas = document.createElement('canvas');
        canvas.id = 'installment-comparison';
        canvas.width = 600;
        canvas.height = 400;
        
        const ctx = canvas.getContext('2d');
        const providers = Object.keys(plans);
        const monthlyPayments = providers.map(p => plans[p].monthlyPayment);
        
        // رسم الرسم البياني
        const maxPayment = Math.max(...monthlyPayments);
        const barWidth = canvas.width / (providers.length * 2);
        
        providers.forEach((provider, index) => {
            const height = (plans[provider].monthlyPayment / maxPayment) * (canvas.height - 100);
            const x = (index * 2 + 1) * barWidth;
            
            ctx.fillStyle = this.getProviderColor(provider);
            ctx.fillRect(x, canvas.height - height - 50, barWidth, height);
            
            // إضافة التسميات
            ctx.fillStyle = '#000';
            ctx.font = '14px Cairo';
            ctx.textAlign = 'center';
            ctx.fillText(provider, x + barWidth/2, canvas.height - 20);
            ctx.fillText(`${plans[provider].monthlyPayment} ج.م`, x + barWidth/2, canvas.height - height - 60);
        });
        
        return canvas;
    }
    
    static getProviderColor(provider) {
        const colors = {
            premium: '#2196F3',
            forsa: '#4CAF50',
            valu: '#FFC107',
            sympl: '#9C27B0'
        };
        return colors[provider] || '#999';
    }
}

// إضافة خيار الحفظ التلقائي للبطاقة
function addSaveCardOption() {
    const cardForm = document.getElementById('card-form');
    if (cardForm) {
        const saveCardDiv = document.createElement('div');
        saveCardDiv.className = 'form-group save-card-option';
        saveCardDiv.innerHTML = `
            <label class="checkbox-container">
                <input type="checkbox" id="save-card">
                <span class="checkmark"></span>
                حفظ هذه البطاقة للمعاملات المستقبلية
            </label>
            <small class="security-note">
                <i class="fas fa-lock"></i>
                سيتم تشفير بيانات بطاقتك بشكل آمن
            </small>
        `;
        cardForm.appendChild(saveCardDiv);
    }
}

// إضافة ميزة العملات المتعددة
class CurrencyConverter {
    static async convertAmount(amount, fromCurrency, toCurrency) {
        // في التطبيق الحقيقي، يجب استخدام API لأسعار العملات
        const rates = {
            EGP: 1,
            USD: 0.032,
            EUR: 0.029,
            GBP: 0.025,
            SAR: 0.12
        };
        
        return amount * (rates[toCurrency] / rates[fromCurrency]);
    }
    
    static formatCurrency(amount, currency) {
        const formatter = new Intl.NumberFormat('ar-EG', {
            style: 'currency',
            currency: currency
        });
        return formatter.format(amount);
    }
}

// إضافة شريط التقدم للدفع
class PaymentProgressBar {
    constructor() {
        this.steps = ['اختيار الطريقة', 'إدخال البيانات', 'التحقق', 'التأكيد'];
        this.currentStep = 0;
        this.element = this.createProgressBar();
    }
    
    createProgressBar() {
        const container = document.createElement('div');
        container.className = 'payment-progress';
        
        this.steps.forEach((step, index) => {
            const stepElement = document.createElement('div');
            stepElement.className = 'progress-step';
            stepElement.innerHTML = `
                <div class="step-number">${index + 1}</div>
                <div class="step-label">${step}</div>
            `;
            container.appendChild(stepElement);
            
            if (index < this.steps.length - 1) {
                const line = document.createElement('div');
                line.className = 'progress-line';
                container.appendChild(line);
            }
        });
        
        return container;
    }
    
    nextStep() {
        if (this.currentStep < this.steps.length - 1) {
            this.currentStep++;
            this.updateProgress();
        }
    }
    
    updateProgress() {
        const stepElements = this.element.querySelectorAll('.progress-step');
        stepElements.forEach((step, index) => {
            if (index < this.currentStep) {
                step.classList.add('completed');
            } else if (index === this.currentStep) {
                step.classList.add('active');
            }
        });
    }
}

// إضافة نظام للإيصالات
class ReceiptGenerator {
    static generateReceipt(paymentData) {
        const receiptTemplate = `
            <div class="receipt">
                <div class="receipt-header">
                    <h2>إيصال الدفع</h2>
                    <div class="receipt-number">رقم العملية: ${this.generateTransactionId()}</div>
                    <div class="receipt-date">${new Date().toLocaleDateString('ar-EG')}</div>
                </div>
                <div class="receipt-body">
                    <div class="receipt-item">
                        <span>المبلغ</span>
                        <span>${paymentData.amount} جنيه</span>
                    </div>
                    <div class="receipt-item">
                        <span>طريقة الدفع</span>
                        <span>${paymentData.method}</span>
                    </div>
                    <div class="receipt-item">
                        <span>حالة الدفع</span>
                        <span class="status-success">تم بنجاح</span>
                    </div>
                </div>
                <div class="receipt-footer">
                    <button onclick="window.print()">طباعة الإيصال</button>
                    <button onclick="ReceiptGenerator.downloadPDF()">تحميل PDF</button>
                </div>
            </div>
        `;
        return receiptTemplate;
    }
    
    static generateTransactionId() {
        return 'TRX' + Date.now().toString(36).toUpperCase();
    }
    
    static downloadPDF() {
        // تنفيذ تحميل PDF
        // يمكن استخدام مكتبة مثل jsPDF
    }
}

// إضافة خيارات تقسيط مخصصة
function setupCustomInstallmentOptions() {
    const container = document.createElement('div');
    container.className = 'custom-installment-options';
    container.innerHTML = `
        <div class="form-group">
            <label>المبلغ المقدم</label>
            <input type="number" id="down-payment" min="0">
        </div>
        <div class="form-group">
            <label>عدد الأشهر</label>
            <input type="range" id="months-range" min="6" max="60" step="6">
            <output id="months-value">12</output>
        </div>
    `;
    
    document.getElementById('installment-form')?.appendChild(container);
    
    // إضافة مستمعي الأحداث
    const monthsRange = document.getElementById('months-range');
    const monthsValue = document.getElementById('months-value');
    const downPayment = document.getElementById('down-payment');
    
    if (monthsRange && monthsValue) {
        monthsRange.addEventListener('input', (e) => {
            monthsValue.value = e.target.value;
            updateInstallmentPlans();
        });
    }
    
    if (downPayment) {
        downPayment.addEventListener('input', updateInstallmentPlans);
    }
}

// تصدير الدوال والكلاسات للاستخدام
export {
    PaymentPreferences,
    CardValidator,
    InstallmentCalculator,
    WalletManager,
    CurrencyConverter,
    PaymentProgressBar,
    ReceiptGenerator
};