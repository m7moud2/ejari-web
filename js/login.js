document.addEventListener('DOMContentLoaded', function() {
    // تبديل عرض كلمة المرور
    const togglePassword = document.querySelector('.toggle-password');
    const passwordInput = document.querySelector('#password');
    
    if (togglePassword && passwordInput) {
        togglePassword.addEventListener('click', function() {
            const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
            passwordInput.setAttribute('type', type);
            
            const icon = this.querySelector('i');
            icon.classList.toggle('fa-eye');
            icon.classList.toggle('fa-eye-slash');
        });
    }

    // نموذج تسجيل الدخول
    const loginForm = document.querySelector('#loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }
});

// معالجة تسجيل الدخول
async function handleLogin(event) {
    event.preventDefault();

    const email = document.querySelector('#email').value;
    const password = document.querySelector('#password').value;
    const remember = document.querySelector('#remember').checked;

    try {
        // إظهار حالة التحميل
        const submitBtn = event.target.querySelector('.submit-btn');
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري التحميل...';
        submitBtn.disabled = true;

        // جلب المستخدمين المسجلين
        const users = JSON.parse(localStorage.getItem('users')) || [];
        
        // البحث عن المستخدم
        const user = users.find(u => u.email === email && u.password === password);

        if (user) {
            // حفظ بيانات الجلسة
            const sessionData = {
                userId: user.email,
                userName: user.fullName,
                userType: user.type,
                isLoggedIn: true,
                rememberMe: remember
            };

            if (remember) {
                localStorage.setItem('userSession', JSON.stringify(sessionData));
            } else {
                sessionStorage.setItem('userSession', JSON.stringify(sessionData));
            }

            // عرض رسالة النجاح
            showNotification('تم تسجيل الدخول بنجاح! جاري التحويل...', 'success');

            // التوجيه حسب نوع المستخدم
            setTimeout(() => {
                if (user.type === 'owner') {
                    window.location.href = 'owner-dashboard.html';
                } else if (user.type === 'tenant') {
                    window.location.href = 'tenant-dashboard.html';
                } else {
                    window.location.href = 'index.html';
                }
            }, 1500);
        } else {
            showNotification('البريد الإلكتروني أو كلمة المرور غير صحيحة', 'error');
            submitBtn.innerHTML = originalText;
            submitBtn.disabled = false;
        }
    } catch (error) {
        console.error('Login error:', error);
        showNotification('حدث خطأ أثناء تسجيل الدخول', 'error');
        submitBtn.innerHTML = originalText;
        submitBtn.disabled = false;
    }
}

// عرض الإشعارات
function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    Object.assign(notification.style, {
        position: 'fixed',
        top: '20px',
        right: '20px',
        padding: '15px 25px',
        borderRadius: '8px',
        backgroundColor: type === 'success' ? '#10b981' : '#ef4444',
        color: 'white',
        boxShadow: '0 4px 12px rgba(0, 0, 0, 0.1)',
        zIndex: 1000,
        animation: 'slideIn 0.3s ease'
    });
    
    document.body.appendChild(notification);

    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// تحقق من وجود جلسة مسجلة
function checkSession() {
    const session = localStorage.getItem('userSession') || sessionStorage.getItem('userSession');
    if (session) {
        const userData = JSON.parse(session);
        if (userData.isLoggedIn) {
            if (userData.userType === 'owner') {
                window.location.href = 'owner-dashboard.html';
            } else if (userData.userType === 'tenant') {
                window.location.href = 'tenant-dashboard.html';
            }
        }
    }
}

// تحقق من الجلسة عند تحميل الصفحة
checkSession();