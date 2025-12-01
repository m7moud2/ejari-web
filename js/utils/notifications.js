class NotificationSystem {
    constructor() {
        this.notifications = [];
        this.initializeNotificationSystem();
    }

    initializeNotificationSystem() {
        // إنشاء حاوية الإشعارات
        const container = document.createElement('div');
        container.className = 'notifications-container';
        document.body.appendChild(container);
        this.container = container;

        // تهيئة مستمعي الأحداث للإشعارات
        this.initializeNotificationListeners();
    }

    initializeNotificationListeners() {
        // تهيئة زر الإشعارات في القائمة العلوية
        const notificationBtn = document.querySelector('.notifications-dropdown .btn-icon');
        if (notificationBtn) {
            notificationBtn.addEventListener('click', () => {
                this.toggleNotificationsList();
            });
        }

        // إضافة مستمع لتحديث الإشعارات تلقائياً
        setInterval(() => {
            this.checkForNewNotifications();
        }, 30000); // كل 30 ثانية
    }

    show(options) {
        const {
            message,
            type = 'info',
            duration = 3000,
            action = null
        } = options;

        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        
        notification.innerHTML = `
            <div class="notification-content">
                <i class="notification-icon fas fa-${this.getIcon(type)}"></i>
                <div class="notification-message">${message}</div>
                ${action ? `
                    <button class="notification-action btn btn-sm">
                        ${action.text}
                    </button>
                ` : ''}
                <button class="notification-close">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="notification-progress"></div>
        `;

        // إضافة مستمعي الأحداث
        const closeBtn = notification.querySelector('.notification-close');
        closeBtn.addEventListener('click', () => this.close(notification));

        if (action) {
            const actionBtn = notification.querySelector('.notification-action');
            actionBtn.addEventListener('click', action.onClick);
        }

        this.container.appendChild(notification);
        this.notifications.push(notification);

        // تفعيل الإشعار
        setTimeout(() => notification.classList.add('show'), 10);

        // إضافة شريط التقدم
        const progress = notification.querySelector('.notification-progress');
        progress.style.transition = `width ${duration}ms linear`;
        setTimeout(() => progress.style.width = '0%', 10);

        // إغلاق تلقائي
        if (duration > 0) {
            setTimeout(() => {
                if (this.notifications.includes(notification)) {
                    this.close(notification);
                }
            }, duration);
        }

        return notification;
    }

    close(notification) {
        notification.classList.remove('show');
        setTimeout(() => {
            notification.remove();
            this.notifications = this.notifications.filter(n => n !== notification);
        }, 300);
    }

    closeAll() {
        [...this.notifications].forEach(notification => this.close(notification));
    }

    success(message, options = {}) {
        return this.show({ ...options, message, type: 'success' });
    }

    error(message, options = {}) {
        return this.show({ ...options, message, type: 'error' });
    }

    warning(message, options = {}) {
        return this.show({ ...options, message, type: 'warning' });
    }

    info(message, options = {}) {
        return this.show({ ...options, message, type: 'info' });
    }

    getIcon(type) {
        const icons = {
            success: 'check-circle',
            error: 'exclamation-circle',
            warning: 'exclamation-triangle',
            info: 'info-circle'
        };
        return icons[type] || icons.info;
    }

    // إدارة قائمة الإشعارات
    toggleNotificationsList() {
        const dropdown = document.querySelector('.notifications-dropdown');
        if (dropdown) {
            dropdown.classList.toggle('active');
            if (dropdown.classList.contains('active')) {
                this.markAllAsRead();
            }
        }
    }

    markAllAsRead() {
        const unreadNotifications = document.querySelectorAll('.notification-item.unread');
        unreadNotifications.forEach(notification => {
            notification.classList.remove('unread');
        });
        this.updateNotificationBadge();
    }

    updateNotificationBadge() {
        const unreadCount = document.querySelectorAll('.notification-item.unread').length;
        const badge = document.querySelector('.notifications-dropdown .badge');
        if (badge) {
            badge.textContent = unreadCount;
            badge.style.display = unreadCount > 0 ? 'block' : 'none';
        }
    }

    checkForNewNotifications() {
        // هنا يمكن إضافة منطق للتحقق من وجود إشعارات جديدة من الخادم
        // محاكاة لتحديث الإشعارات
        console.log('جاري التحقق من الإشعارات الجديدة...');
    }

    // إضافة إشعار إلى القائمة
    addNotificationToList(notification) {
        const notificationsList = document.querySelector('.notifications-list');
        if (notificationsList) {
            const notificationElement = document.createElement('div');
            notificationElement.className = 'notification-item unread';
            notificationElement.innerHTML = `
                <div class="notification-icon ${notification.type}">
                    <i class="fas fa-${this.getIcon(notification.type)}"></i>
                </div>
                <div class="notification-content">
                    <h4>${notification.title}</h4>
                    <p>${notification.message}</p>
                    <span class="time">${notification.time}</span>
                </div>
                <button class="btn btn-icon">
                    <i class="fas fa-ellipsis-v"></i>
                </button>
            `;
            notificationsList.prepend(notificationElement);
            this.updateNotificationBadge();
        }
    }
}

// تصدير نظام الإشعارات
export const notifications = new NotificationSystem();