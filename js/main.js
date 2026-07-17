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

    const getFavoriteItems = () => JSON.parse(localStorage.getItem('ejari_favorites')) || [];
    const saveFavoriteItems = (items) => localStorage.setItem('ejari_favorites', JSON.stringify(items));
    const syncFavoriteButtonState = (btn, isFavorite) => {
        const icon = btn.querySelector('i');
        btn.classList.toggle('active', isFavorite);
        if (icon) {
            icon.style.color = isFavorite ? '#f5576c' : '';
            icon.classList.toggle('fas', isFavorite);
            icon.classList.toggle('far', !isFavorite);
        }
    };
    const toggleFavoriteFromButton = (btn) => {
        const card = btn.closest('[data-property-id]') || btn.closest('.property-card');
        const propertyId = card?.dataset?.propertyId || card?.dataset?.id || btn.dataset?.propertyId || card?.querySelector('button.btn-details')?.onclick?.toString?.().match(/id=(\d+)/)?.[1];
        if (!propertyId) return;
        const title = card?.dataset?.propertyTitle || card?.querySelector('h3')?.textContent || card?.querySelector('h4')?.textContent || 'عقار';
        const image = card?.querySelector('img')?.src || 'images/home1.jpg';
        const price = Number(card?.dataset?.price || 0);
        let favorites = getFavoriteItems();
        const exists = favorites.find(item => String(item.id) === String(propertyId));
        favorites = exists ? favorites.filter(item => String(item.id) !== String(propertyId)) : [{ id: propertyId, title, image, price, savedAt: new Date().toISOString() }, ...favorites];
        saveFavoriteItems(favorites);
        syncFavoriteButtonState(btn, !exists);
        if (typeof showNotification === 'function') {
            showNotification(exists ? 'تمت الإزالة من المفضلة' : 'تمت الإضافة للمفضلة');
        }
        window.dispatchEvent(new CustomEvent('ejari:favorites-updated', { detail: favorites }));
    };
    window.refreshFavoriteButtons = () => {
        document.querySelectorAll('.favorite-btn').forEach(btn => {
            const card = btn.closest('[data-property-id]') || btn.closest('.property-card');
            const propertyId = card?.dataset?.propertyId || card?.dataset?.id;
            if (!propertyId) return;
            const exists = getFavoriteItems().some(item => String(item.id) === String(propertyId));
            syncFavoriteButtonState(btn, exists);
        });
    };
    document.addEventListener('click', (e) => {
        const btn = e.target.closest('.favorite-btn');
        if (!btn) return;
        e.preventDefault();
        toggleFavoriteFromButton(btn);
    });
    window.refreshFavoriteButtons();

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
