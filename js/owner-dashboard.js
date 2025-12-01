document.addEventListener('DOMContentLoaded', function() {
    initializeSidebar();
    initializeDropdowns();
    initializeSearch();
    initializeTableActions();
    initializeCharts();
    initializeNotifications();
    setupAutoRefresh();
});

// تهيئة القائمة الجانبية
function initializeSidebar() {
    const menuToggle = document.querySelector('.menu-toggle');
    const sidebar = document.querySelector('.sidebar');
    const mainContent = document.querySelector('.main-content');

    if (menuToggle && sidebar) {
        menuToggle.addEventListener('click', () => {
            sidebar.classList.toggle('collapsed');
            mainContent.classList.toggle('expanded');
        });

        // إغلاق القائمة عند النقر خارجها في الشاشات الصغيرة
        document.addEventListener('click', (e) => {
            if (window.innerWidth <= 768 && 
                !sidebar.contains(e.target) && 
                !menuToggle.contains(e.target)) {
                sidebar.classList.remove('collapsed');
            }
        });
    }

    // تفعيل روابط القائمة
    document.querySelectorAll('.sidebar-nav a').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            // إزالة الكلاس النشط من جميع الروابط
            document.querySelectorAll('.sidebar-nav a').forEach(l => 
                l.classList.remove('active'));
            
            // إضافة الكلاس النشط للرابط المحدد
            this.classList.add('active');
            
            const section = this.getAttribute('href').substring(1);
            loadSection(section);
        });
    });
}

// تهيئة القوائم المنسدلة
function initializeDropdowns() {
    // قائمة المستخدم
    const userMenuBtn = document.querySelector('.user-menu-btn');
    const userMenuDropdown = document.querySelector('.user-menu-dropdown');
    
    if (userMenuBtn) {
        userMenuBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            userMenuDropdown?.classList.toggle('active');
            // إغلاق القوائم الأخرى
            document.querySelectorAll('.notifications-dropdown, .messages-dropdown')
                .forEach(dropdown => dropdown.classList.remove('active'));
        });
    }

    // الإشعارات
    const notificationsBtn = document.querySelector('.notifications-dropdown .btn-icon');
    if (notificationsBtn) {
        notificationsBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            const dropdown = notificationsBtn.closest('.notifications-dropdown');
            dropdown.classList.toggle('active');
            // تحديث حالة الإشعارات كمقروءة
            if (dropdown.classList.contains('active')) {
                updateNotificationsStatus();
            }
        });
    }

    // الرسائل
    const messagesBtn = document.querySelector('.messages-dropdown .btn-icon');
    if (messagesBtn) {
        messagesBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            messagesBtn.closest('.messages-dropdown').classList.toggle('active');
        });
    }

    // إغلاق القوائم عند النقر خارجها
    document.addEventListener('click', () => {
        document.querySelectorAll('.notifications-dropdown, .messages-dropdown, .user-menu-dropdown')
            .forEach(dropdown => dropdown.classList.remove('active'));
    });
}

// تهيئة البحث
function initializeSearch() {
    const searchInput = document.querySelector('.search-bar input');
    if (searchInput) {
        let searchTimeout;
        
        searchInput.addEventListener('input', (e) => {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(() => {
                performSearch(e.target.value);
            }, 300);
        });
    }
}

// تهيئة إجراءات الجداول
function initializeTableActions() {
    // إجراءات العقارات
    document.querySelectorAll('.properties-table .actions button').forEach(button => {
        button.addEventListener('click', function() {
            const row = this.closest('tr');
            const propertyId = row.dataset.propertyId;
            
            if (this.querySelector('.fa-edit')) {
                editProperty(propertyId);
            } else if (this.querySelector('.fa-eye')) {
                viewProperty(propertyId);
            }
        });
    });

    // إجراءات الحجوزات
    document.querySelectorAll('.bookings-table .actions button').forEach(button => {
        button.addEventListener('click', function() {
            const row = this.closest('tr');
            const bookingId = row.querySelector('td:first-child').textContent;
            
            if (this.querySelector('.fa-check')) {
                approveBooking(bookingId);
            } else if (this.querySelector('.fa-times')) {
                rejectBooking(bookingId);
            }
        });
    });
}

// تهيئة الرسوم البيانية
function initializeCharts() {
    const ctx = document.querySelector('.chart-content');
    if (ctx) {
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'],
                datasets: [{
                    label: 'الدخل الشهري',
                    data: [12000, 19000, 15000, 25000, 22000, 30000],
                    borderColor: '#4CAF50',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }
}

// تهيئة الإشعارات
function initializeNotifications() {
    const markAllReadBtn = document.querySelector('.notifications-panel .btn-text');
    if (markAllReadBtn) {
        markAllReadBtn.addEventListener('click', () => {
            document.querySelectorAll('.notification-item.unread')
                .forEach(item => item.classList.remove('unread'));
            updateNotificationsBadge();
        });
    }
}

// تحديث تلقائي
function setupAutoRefresh() {
    setInterval(() => {
        updateDashboardStats();
        updateNotificationsBadge();
    }, 60000); // كل دقيقة
}

// دوال مساعدة
function loadSection(section) {
    showLoader();
    // محاكاة تحميل القسم
    setTimeout(() => {
        console.log(`تحميل القسم: ${section}`);
        hideLoader();
        showNotification('تم تحميل القسم بنجاح');
    }, 500);
}

function showLoader() {
    const loader = document.createElement('div');
    loader.className = 'loader';
    document.body.appendChild(loader);
}

function hideLoader() {
    const loader = document.querySelector('.loader');
    if (loader) loader.remove();
}

function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // تحريك الإشعار للأعلى
    setTimeout(() => notification.classList.add('show'), 100);
    
    // إزالة الإشعار
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// دوال معالجة العقارات
function editProperty(propertyId) {
    console.log(`تعديل العقار: ${propertyId}`);
    showNotification('جاري فتح نموذج التعديل...');
}

function viewProperty(propertyId) {
    console.log(`عرض العقار: ${propertyId}`);
    showNotification('جاري تحميل تفاصيل العقار...');
}

// دوال معالجة الحجوزات
function approveBooking(bookingId) {
    console.log(`الموافقة على الحجز: ${bookingId}`);
    showNotification('تم قبول الحجز بنجاح', 'success');
}

function rejectBooking(bookingId) {
    console.log(`رفض الحجز: ${bookingId}`);
    showNotification('تم رفض الحجز', 'error');
}

// دوال التحديث
function updateDashboardStats() {
    // تحديث الإحصائيات من الخادم
    console.log('تحديث إحصائيات لوحة التحكم');
}

function updateNotificationsStatus() {
    // تحديث حالة الإشعارات في الخادم
    console.log('تحديث حالة الإشعارات');
}

function updateNotificationsBadge() {
    const unreadCount = document.querySelectorAll('.notification-item.unread').length;
    const badge = document.querySelector('.notifications-dropdown .badge');
    if (badge) {
        badge.textContent = unreadCount;
        badge.style.display = unreadCount > 0 ? 'block' : 'none';
    }
}

function performSearch(query) {
    console.log(`البحث عن: ${query}`);
    // يمكن إضافة منطق البحث هنا
}
function logout() {
    // Clear local storage
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('isAuthenticated');
    
    // Clear session storage
    sessionStorage.clear();
    
    // Show notification
    showNotification('جاري تسجيل الخروج...', 'info');
    
    // Optional: Call logout API endpoint
    fetch('/api/auth/logout', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
    }).finally(() => {
        // Redirect to login page after small delay
        setTimeout(() => {
            window.location.href = 'login.html'; // or '/login' depending on your routing
        }, 1000);
    });
}

// Add event listener to logout button
document.querySelector('.sidebar-footer .btn').addEventListener('click', logout);