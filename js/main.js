document.addEventListener('DOMContentLoaded', function() {
    // تبديل التبويبات
    const tabButtons = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.category-content');

    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            // إزالة الكلاس active من جميع الأزرار
            tabButtons.forEach(btn => btn.classList.remove('active'));
            // إضافة الكلاس active للزر المضغوط
            button.classList.add('active');

            // إخفاء جميع المحتويات
            tabContents.forEach(content => content.classList.remove('active'));
            // إظهار المحتوى المطلوب
            const targetContent = document.getElementById(button.dataset.category);
            targetContent.classList.add('active');
        });
    });

    // إضافة للمفضلة
    const favoriteButtons = document.querySelectorAll('.favorite-btn');
    favoriteButtons.forEach(button => {
        button.addEventListener('click', (e) => {
            e.preventDefault();
            button.querySelector('i').classList.toggle('fas');
            button.querySelector('i').classList.toggle('far');
            
            if (button.querySelector('i').classList.contains('fas')) {
                showNotification('تمت الإضافة للمفضلة');
            } else {
                showNotification('تمت الإزالة من المفضلة');
            }
        });
    });

    // إضافة إلى عربة التسوق
    window.addToCart = function(itemId) {
        // يمكن إضافة منطق إضافة العنصر للعربة هنا
        const cartCount = document.querySelector('.cart-count');
        if (cartCount) {
            let currentCount = parseInt(cartCount.textContent);
            cartCount.textContent = currentCount + 1;
        }
        showNotification('تمت الإضافة إلى عربة التسوق');
    };

    // عرض الإشعارات
    window.showNotification = function(message, type = 'success') {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.textContent = message;
        
        // إضافة الأنماط للإشعار
        notification.style.position = 'fixed';
        notification.style.top = '20px';
        notification.style.right = '20px';
        notification.style.background = type === 'success' ? '#4CAF50' : '#f44336';
        notification.style.color = 'white';
        notification.style.padding = '15px 25px';
        notification.style.borderRadius = '4px';
        notification.style.zIndex = '1000';
        notification.style.animation = 'slideIn 0.3s ease';

        document.body.appendChild(notification);

        // إزالة الإشعار بعد 3 ثواني
        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    };
});

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

    .notification {
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
`;
document.head.appendChild(style);