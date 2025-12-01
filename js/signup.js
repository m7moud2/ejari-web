let selectedAccountType = '';

// اختيار نوع الحساب
function selectAccountType(type) {
    selectedAccountType = type;
    
    // إزالة التحديد من جميع البطاقات
    document.querySelectorAll('.account-type').forEach(card => {
        card.classList.remove('selected');
    });
    
    // تحديد البطاقة المختارة
    if (type !== 'guest') {
        event.currentTarget.classList.add('selected');
        setTimeout(() => {
            document.getElementById('accountTypeSelection').style.display = 'none';
            document.getElementById('signupForm').style.display = 'block';
        }, 500);
        
        // إظهار/إخفاء حقول المالك
        if (type === 'owner') {
            document.getElementById('ownerFields').style.display = 'block';
        }
    }
}

// معالجة تسجيل الحساب
document.getElementById('signupForm').addEventListener('submit', async function(e) {
    e.preventDefault();

    // التحقق من صحة البيانات
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    if (password.length < 6) {
        showNotification('كلمة المرور يجب أن تكون 6 أحرف على الأقل', 'error');
        return;
    }

    // جمع البيانات
    const userData = {
        fullName: document.getElementById('fullName').value,
        email: email,
        phone: document.getElementById('phone').value,
        password: password,
        type: selectedAccountType,
        isVerified: false,
        createdAt: new Date().toISOString()
    };

    // إضافة بيانات المالك
    if (selectedAccountType === 'owner') {
        const idCard = document.getElementById('idCard').files[0];
        const utilityBill = document.getElementById('utilityBill').files[0];
        
        if (!idCard || !utilityBill) {
            showNotification('يرجى رفع جميع المستندات المطلوبة', 'error');
            return;
        }
        
        userData.documents = {
            idCard: idCard.name,
            utilityBill: utilityBill.name
        };
    }

    try {
        // جلب المستخدمين الحاليين
        let users = JSON.parse(localStorage.getItem('users')) || [];

        // التحقق من البريد الإلكتروني
        if (users.some(user => user.email === email)) {
            showNotification('هذا البريد الإلكتروني مسجل بالفعل', 'error');
            return;
        }

        // إضافة المستخدم وحفظ البيانات
        users.push(userData);
        localStorage.setItem('users', JSON.stringify(users));

        // إنشاء جلسة للمستخدم
        const sessionData = {
            userId: email,
            userName: userData.fullName,
            userType: selectedAccountType,
            isLoggedIn: true
        };
        sessionStorage.setItem('userSession', JSON.stringify(sessionData));

        showNotification('تم التسجيل بنجاح!', 'success');

        // التوجيه حسب نوع الحساب
        setTimeout(() => {
            if (selectedAccountType === 'owner') {
                window.location.href = 'owner-dashboard.html';
            } else if (selectedAccountType === 'tenant') {
                window.location.href = 'index.html';
            }
        }, 1500);

    } catch (error) {
        showNotification('حدث خطأ أثناء التسجيل', 'error');
        console.error(error);
    }
});

// تبديل إظهار/إخفاء كلمة المرور
document.querySelector('.toggle-password').addEventListener('click', function() {
    const passwordInput = document.getElementById('password');
    const currentType = passwordInput.type;
    
    passwordInput.type = currentType === 'password' ? 'text' : 'password';
    this.classList.toggle('fa-eye');
    this.classList.toggle('fa-eye-slash');
});

// دالة إظهار الإشعارات
function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);

    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// التحقق من حالة تسجيل الدخول عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', function() {
    const userSession = JSON.parse(sessionStorage.getItem('userSession'));
    if (userSession?.isLoggedIn) {
        if (userSession.userType === 'owner') {
            window.location.href = 'owner-dashboard.html';
        } else if (userSession.userType === 'tenant') {
            window.location.href = 'index.html';
        }
    }
});