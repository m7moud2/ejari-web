function handleSubmit(event) {
    event.preventDefault();
    
    // جمع البيانات من النموذج
    const formData = {
        name: document.getElementById('name').value,
        email: document.getElementById('email').value,
        phone: document.getElementById('phone').value,
        subject: document.getElementById('subject').value,
        message: document.getElementById('message').value
    };

    // هنا يمكنك إضافة كود لإرسال البيانات للخادم
    console.log('Form submitted:', formData);

    // عرض رسالة نجاح (يمكن تحسينها باستخدام مكتبة// التحقق من تحميل الصفحة
document.addEventListener('DOMContentLoaded', function() {
    // إضافة مستمع للنموذج
    const contactForm = document.querySelector('.contact-form');
    if (contactForm) {
        contactForm.addEventListener('submit', handleSubmit);
    }

    // إضافة التحقق المباشر للمدخلات
    setupFormValidation();
});

// دالة التحقق من المدخلات
function setupFormValidation() {
    const emailInput = document.getElementById('email');
    const phoneInput = document.getElementById('phone');
    const messageInput = document.getElementById('message');

    // التحقق من صحة البريد الإلكتروني
    if (emailInput) {
        emailInput.addEventListener('blur', function() {
            const isValid = validateEmail(this.value);
            toggleError(this, isValid, 'يرجى إدخال بريد إلكتروني صحيح');
        });
    }

    // التحقق من رقم الهاتف
    if (phoneInput) {
        phoneInput.addEventListener('blur', function() {
            const isValid = validatePhone(this.value);
            toggleError(this, isValid, 'يرجى إدخال رقم هاتف صحيح');
        });
    }

    // التحقق من طول الرسالة
    if (messageInput) {
        messageInput.addEventListener('input', function() {
            const isValid = this.value.length >= 10;
            toggleError(this, isValid, 'الرسالة يجب أن تكون 10 أحرف على الأقل');
        });
    }
}

// دالة التحقق من صحة البريد الإلكتروني
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

// دالة التحقق من صحة رقم الهاتف
function validatePhone(phone) {
    const re = /^[0-9\s+()-]{8,}$/;
    return re.test(phone);
}

// دالة إظهار/إخفاء رسائل الخطأ
function toggleError(element, isValid, errorMessage) {
    const errorDiv = element.nextElementSibling?.classList.contains('error-message') 
        ? element.nextElementSibling 
        : document.createElement('div');
    
    if (!isValid) {
        if (!element.nextElementSibling?.classList.contains('error-message')) {
            errorDiv.className = 'error-message';
            errorDiv.style.color = 'red';
            errorDiv.style.fontSize = '12px';
            errorDiv.style.marginTop = '5px';
            element.parentNode.insertBefore(errorDiv, element.nextSibling);
        }
        errorDiv.textContent = errorMessage;
        element.classList.add('error');
    } else {
        if (element.nextElementSibling?.classList.contains('error-message')) {
            element.nextElementSibling.remove();
        }
        element.classList.remove('error');
    }
}

// دالة معالجة تقديم النموذج
function handleSubmit(event) {
    event.preventDefault();
    
    // جمع البيانات من النموذج
    const formData = {
        name: document.getElementById('name').value,
        email: document.getElementById('email').value,
        phone: document.getElementById('phone').value,
        subject: document.getElementById('subject').value,
        message: document.getElementById('message').value
    };

    // التحقق من صحة جميع المدخلات
    const isEmailValid = validateEmail(formData.email);
    const isPhoneValid = validatePhone(formData.phone);
    const isMessageValid = formData.message.length >= 10;

    if (!isEmailValid || !isPhoneValid || !isMessageValid) {
        showNotification('يرجى التحقق من صحة جميع البيانات المدخلة', 'error');
        return;
    }

    // محاكاة إرسال البيانات للخادم
    showLoadingSpinner();
    
    setTimeout(() => {
        // محاكاة استجابة ناجحة من الخادم
        hideLoadingSpinner();
        showNotification('تم إرسال رسالتك بنجاح! سنتواصل معك قريباً', 'success');
        resetForm();
    }, 1500);
}

// دالة عرض الإشعارات
function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);

    // إضافة الأنماط
    notification.style.position = 'fixed';
    notification.style.top = '20px';
    notification.style.right = '20px';
    notification.style.padding = '15px 25px';
    notification.style.borderRadius = '8px';
    notification.style.color = 'white';
    notification.style.zIndex = '1000';
    notification.style.animation = 'slideIn 0.3s ease';

    if (type === 'success') {
        notification.style.backgroundColor = '#4CAF50';
    } else if (type === 'error') {
        notification.style.backgroundColor = '#f44336';
    }

    // إزالة الإشعار بعد 3 ثوانٍ
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// دالة عرض مؤشر التحميل
function showLoadingSpinner() {
    const spinner = document.createElement('div');
    spinner.className = 'loading-spinner';
    spinner.innerHTML = `
        <div class="spinner"></div>
        <p>جارِ الإرسال...</p>
    `;
    
    document.body.appendChild(spinner);

    // إضافة الأنماط
    spinner.style.position = 'fixed';
    spinner.style.top = '0';
    spinner.style.left = '0';
    spinner.style.width = '100%';
    spinner.style.height = '100%';
    spinner.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
    spinner.style.display = 'flex';
    spinner.style.flexDirection = 'column';
    spinner.style.alignItems = 'center';
    spinner.style.justifyContent = 'center';
    spinner.style.color = 'white';
    spinner.style.zIndex = '1000';
}

// دالة إخفاء مؤشر التحميل
function hideLoadingSpinner() {
    const spinner = document.querySelector('.loading-spinner');
    if (spinner) {
        spinner.remove();
    }
}

// دالة إعادة تعيين النموذج
function resetForm() {
    const form = document.querySelector('.contact-form');
    if (form) {
        form.reset();
    }
}

// إضافة الأنماط للرسوم المتحركة
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }

    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }

    .spinner {
        width: 40px;
        height: 40px;
        border: 4px solid #f3f3f3;
        border-top: 4px solid var(--primary-color);
        border-radius: 50%;
        animation: spin 1s linear infinite;
    }

    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }
`;
document.head.appendChild(style);}