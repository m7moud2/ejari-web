/**
 * Session Manager - Ejari
 * Manages user session state across public pages
 */

const SessionManager = {
    init: function () {
        this.updateNavbar();
        this.setupLogoutButtons();
    },

    getCurrentUser: function () {
        return JSON.parse(localStorage.getItem('ejari_user'));
    },

    isLoggedIn: function () {
        return !!this.getCurrentUser();
    },

    updateNavbar: function () {
        const user = this.getCurrentUser();
        const loginBtn = document.querySelector('.btn-login');
        const signupBtn = document.querySelector('.btn-signup');

        if (user && loginBtn && signupBtn) {
            // Replace login/signup buttons with user menu
            const navButtons = loginBtn.parentElement;
            navButtons.innerHTML = `
                <div style="display: flex; align-items: center; gap: 1rem;">
                    <div style="display: flex; align-items: center; gap: 0.5rem; padding: 0.5rem 1rem; background: #f3f4f6; border-radius: 8px;">
                        <img src="${user.avatar || 'images/default-avatar.jpg'}" 
                             style="width: 32px; height: 32px; border-radius: 50%; object-fit: cover;" 
                             alt="${user.name}">
                        <span style="font-weight: 600;">${user.name}</span>
                    </div>
                    <button onclick="SessionManager.goToDashboard()" class="btn-primary" style="padding: 0.75rem 1.5rem;">
                        <i class="fas fa-tachometer-alt"></i> لوحة التحكم
                    </button>
                    <button onclick="SessionManager.logout()" class="btn-secondary" style="padding: 0.75rem 1.5rem; background: #ef4444; color: white; border: none;">
                        <i class="fas fa-sign-out-alt"></i> خروج
                    </button>
                </div>
            `;
        }
    },

    goToDashboard: function () {
        const user = this.getCurrentUser();
        if (!user) {
            window.location.href = 'login.html';
            return;
        }

        if (user.role === 'admin') {
            window.location.href = 'admin-dashboard.html';
        } else if (user.role === 'owner') {
            window.location.href = 'owner-dashboard.html';
        } else {
            window.location.href = 'tenant-dashboard.html';
        }
    },

    logout: function () {
        if (confirm('هل أنت متأكد من تسجيل الخروج؟')) {
            localStorage.removeItem('ejari_user');
            localStorage.removeItem('ejari_token');
            window.location.href = 'index.html';
        }
    },

    setupLogoutButtons: function () {
        // Setup logout buttons in dashboards
        const logoutBtns = document.querySelectorAll('.logout-btn');
        logoutBtns.forEach(btn => {
            btn.addEventListener('click', () => this.logout());
        });
    },

    initializeDemoUsers: function () {
        // Check if users already exist
        const users = JSON.parse(localStorage.getItem('ejari_users')) || [];

        if (users.length === 0) {
            // Create demo users
            const demoUsers = [
                {
                    id: 1,
                    name: 'أحمد محمد',
                    email: 'tenant@test.com',
                    password: '123456',
                    phone: '01012345678',
                    role: 'tenant',
                    avatar: 'images/tenant-2.jpg',
                    status: 'active',
                    verificationStatus: 'unverified',
                    points: 150,
                    pointsHistory: [],
                    createdAt: new Date().toISOString()
                },
                {
                    id: 2,
                    name: 'شركة العقارات الحديثة',
                    email: 'owner@test.com',
                    password: '123456',
                    phone: '01098765432',
                    role: 'owner',
                    avatar: 'images/owner-avatar.jpg',
                    status: 'active',
                    verificationStatus: 'unverified',
                    points: 150,
                    pointsHistory: [],
                    subscriptionPlan: 'basic',
                    createdAt: new Date().toISOString()
                },
                {
                    id: 99,
                    name: 'Admin',
                    email: 'admin@ejari.app',
                    password: 'admin123',
                    phone: '01000000000',
                    role: 'admin',
                    avatar: 'images/logo.png',
                    status: 'active',
                    verificationStatus: 'verified',
                    createdAt: new Date().toISOString()
                }
            ];

            localStorage.setItem('ejari_users', JSON.stringify(demoUsers));
        }
    }
};

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    SessionManager.initializeDemoUsers();
    SessionManager.init();
});
