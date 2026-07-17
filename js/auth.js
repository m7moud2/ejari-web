/**
 * Auth Manager - Ejari
 * Handles login, signup, and session management using Express API backend
 */

const API_BASE_URL = 'http://localhost:5050/api';

const AuthManager = {
    // Login function with API call
    login: async function (email, password) {
        // Validation
        if (!email || !password) {
            alert('الرجاء إدخال البريد الإلكتروني وكلمة المرور');
            return false;
        }

        try {
            const response = await fetch(`${API_BASE_URL}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ email, password })
            });

            const result = await response.json();

            if (!response.ok || !result.success) {
                alert(result.error || 'بيانات الدخول غير صحيحة. يرجى المحاولة مرة أخرى.');
                return false;
            }

            // Save token
            localStorage.setItem('ejari_token', result.token);

            // Fetch user details
            const userResponse = await fetch(`${API_BASE_URL}/auth/me`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${result.token}`
                }
            });

            const userResult = await userResponse.json();

            if (!userResponse.ok || !userResult.success) {
                alert('فشل جلب بيانات الملف الشخصي.');
                return false;
            }

            // Save user session
            localStorage.setItem('ejari_user', JSON.stringify(userResult.data));

            // Redirect based on role
            this.redirectUser(userResult.data.role);
            return true;
        } catch (error) {
            console.error('Login Error:', error);
            alert('حدث خطأ أثناء الاتصال بالخادم. الرجاء التأكد من تشغيل السيرفر.');
            return false;
        }
    },

    signup: async function (userData) {
        try {
            // Note: Our backend schema also requires address. We will send a default empty address if not provided.
            const registerData = {
                name: userData.name,
                email: userData.email,
                password: userData.password,
                role: userData.role || 'tenant',
                phone: userData.phone || '',
                address: userData.address || 'القاهرة، مصر'
            };

            const response = await fetch(`${API_BASE_URL}/auth/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(registerData)
            });

            const result = await response.json();

            if (!response.ok || !result.success) {
                alert(result.error || 'فشل إنشاء حساب جديد. يرجى المحاولة لاحقاً.');
                return false;
            }

            // Save token
            localStorage.setItem('ejari_token', result.token);

            // Fetch user details
            const userResponse = await fetch(`${API_BASE_URL}/auth/me`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${result.token}`
                }
            });

            const userResult = await userResponse.json();

            if (!userResponse.ok || !userResult.success) {
                alert('فشل جلب بيانات الملف الشخصي بعد التسجيل.');
                return false;
            }

            // Save user session
            localStorage.setItem('ejari_user', JSON.stringify(userResult.data));

            // Redirect
            this.redirectUser(userResult.data.role);
            return true;
        } catch (error) {
            console.error('Signup Error:', error);
            alert('حدث خطأ أثناء الاتصال بالخادم. الرجاء التأكد من تشغيل السيرفر.');
            return false;
        }
    },

    logout: async function () {
        try {
            const token = localStorage.getItem('ejari_token');
            if (token) {
                await fetch(`${API_BASE_URL}/auth/logout`, {
                    method: 'GET',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });
            }
        } catch (error) {
            console.error('Logout Error:', error);
        }
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

// Handle login form submission
document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const btn = loginForm.querySelector('button[type="submit"]');

            // Loading effect
            const originalText = btn.innerHTML;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري الدخول...';
            btn.disabled = true;

            const success = await AuthManager.login(email, password);
            if (!success) {
                btn.innerHTML = originalText;
                btn.disabled = false;
            }
        });
    }

    // Handle signup form (if present in the page context)
    const signupForm = document.getElementById('signupForm');
    const nameInput = document.getElementById('name');
    if (signupForm && nameInput) {
        signupForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const name = nameInput.value;
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const phone = document.getElementById('phone').value;
            const role = document.getElementById('role').value;

            const btn = signupForm.querySelector('button[type="submit"]');
            const originalText = btn.innerHTML;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري التسجيل...';
            btn.disabled = true;

            const success = await AuthManager.signup({ name, email, password, phone, role });
            if (!success) {
                btn.innerHTML = originalText;
                btn.disabled = false;
            }
        });
    }
});
