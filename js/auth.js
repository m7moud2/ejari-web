/**
 * Auth Manager - Ejari
 * Handles login, signup, and session management
 */

const AuthManager = {
    // Login function with validation
    login: function (email, password) {
        // Validation
        if (!email || !password) {
            alert('الرجاء إدخال البريد الإلكتروني وكلمة المرور');
            return false;
        }

        // Get all users from localStorage
        const users = JSON.parse(localStorage.getItem('ejari_users')) || [];

        // Find user by email
        const user = users.find(u => u.email === email);

        if (!user) {
            alert('البريد الإلكتروني غير مسجل. يرجى إنشاء حساب جديد.');
            return false;
        }

        // Check password
        if (user.password !== password) {
            alert('كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.');
            return false;
        }

        // Save user session
        localStorage.setItem('ejari_user', JSON.stringify(user));
        localStorage.setItem('ejari_token', 'token_' + user.id + '_' + Date.now());

        // Redirect based on role
        this.redirectUser(user.role);
        return true;
    },

    signup: function (userData) {
        // Get existing users
        const users = JSON.parse(localStorage.getItem('ejari_users')) || [];

        // Check if email already exists
        if (users.find(u => u.email === userData.email)) {
            alert('البريد الإلكتروني مسجل بالفعل. يرجى تسجيل الدخول.');
            return false;
        }

        // Create new user
        const newUser = {
            id: Date.now(),
            name: userData.name,
            email: userData.email,
            password: userData.password,
            phone: userData.phone || '',
            role: userData.role || 'tenant',
            avatar: userData.role === 'owner' ? 'images/owner-avatar.jpg' : 'images/tenant-2.jpg',
            status: 'active',
            verificationStatus: 'unverified',
            points: 0,
            pointsHistory: [],
            createdAt: new Date().toISOString()
        };

        // Add to users array
        users.push(newUser);
        localStorage.setItem('ejari_users', JSON.stringify(users));

        // Auto login
        localStorage.setItem('ejari_user', JSON.stringify(newUser));
        localStorage.setItem('ejari_token', 'token_' + newUser.id + '_' + Date.now());

        // Redirect
        this.redirectUser(newUser.role);
        return true;
    },

    logout: function () {
        localStorage.removeItem('ejari_user');
        localStorage.removeItem('ejari_token');
        window.location.href = 'login.html';
    },

    checkAuth: function () {
        const user = JSON.parse(localStorage.getItem('ejari_user'));
        if (!user) {
            window.location.href = 'login.html';
            return null;
        }
        return user;
    },

    redirectUser: function (role) {
        if (role === 'admin') {
            window.location.href = 'admin-dashboard.html';
        } else if (role === 'owner') {
            window.location.href = 'owner-dashboard.html';
        } else {
            window.location.href = 'tenant-dashboard.html';
        }
    },

    // Check if user is logged in (for public pages)
    getCurrentUser: function () {
        return JSON.parse(localStorage.getItem('ejari_user'));
    },

    isLoggedIn: function () {
        return !!this.getCurrentUser();
    }
};

// Handle login form
document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const btn = loginForm.querySelector('button[type="submit"]');

            // Loading effect
            const originalText = btn.innerHTML;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري الدخول...';
            btn.disabled = true;

            setTimeout(() => {
                const success = AuthManager.login(email, password);
                if (!success) {
                    btn.innerHTML = originalText;
                    btn.disabled = false;
                }
            }, 1000);
        });
    }

    // Handle signup form
    const signupForm = document.getElementById('signupForm');
    if (signupForm) {
        signupForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const name = document.getElementById('name').value;
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const phone = document.getElementById('phone').value;
            const role = document.getElementById('role').value;

            const btn = signupForm.querySelector('button[type="submit"]');
            const originalText = btn.innerHTML;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري التسجيل...';
            btn.disabled = true;

            setTimeout(() => {
                const success = AuthManager.signup({ name, email, password, phone, role });
                if (!success) {
                    btn.innerHTML = originalText;
                    btn.disabled = false;
                }
            }, 1000);
        });
    }
});
