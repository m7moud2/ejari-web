/**
 * Ejari Dashboard Engine
 * Handles logic for Tenant, Owner, and Admin dashboards
 * Manages Data Persistence via LocalStorage
 */

const DashboardEngine = {
    currentUser: null,
    data: {
        users: [],
        properties: [],
        bookings: [],
        maintenanceRequests: [],
        payments: []
    },

    init: async function () {
        this.checkAuth();
        await this.loadData();
        this.renderCommonElements();
        this.routeDashboard();
    },

    // --- Data Management ---
    loadData: async function () {
        this.data.users = JSON.parse(localStorage.getItem('ejari_users')) || this.seedUsers();
        
        const token = localStorage.getItem('ejari_token');
        const API_BASE_URL = 'http://localhost:5050/api';

        try {
            // 1. Fetch properties
            const propertiesResponse = await fetch(`${API_BASE_URL}/properties`, { method: 'GET' });
            const propertiesResult = await propertiesResponse.json();
            if (propertiesResponse.ok && propertiesResult.success) {
                this.data.properties = propertiesResult.data;
            } else {
                this.data.properties = JSON.parse(localStorage.getItem('ejari_properties')) || this.seedProperties();
            }

            if (!this.data.properties || this.data.properties.length === 0) {
                try {
                    const localSeed = await fetch('egary_apartments_mock_data.json');
                    if (localSeed.ok) {
                        this.data.properties = await localSeed.json();
                        localStorage.setItem('ejari_seed_properties', JSON.stringify(this.data.properties));
                    }
                } catch (_) {}
            }

            // If not logged in, we skip protected data
            if (!token) return;

            // 2. Fetch bookings
            const bookingsResponse = await fetch(`${API_BASE_URL}/bookings`, {
                method: 'GET',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const bookingsResult = await bookingsResponse.json();
            if (bookingsResponse.ok && bookingsResult.success) {
                this.data.bookings = bookingsResult.data;
            } else {
                this.data.bookings = [];
            }

            // 3. Fetch maintenance requests
            const maintenanceResponse = await fetch(`${API_BASE_URL}/maintenance`, {
                method: 'GET',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const maintenanceResult = await maintenanceResponse.json();
            if (maintenanceResponse.ok && maintenanceResult.success) {
                this.data.maintenanceRequests = maintenanceResult.data;
            } else {
                this.data.maintenanceRequests = [];
            }
        } catch (error) {
            console.error('Error loading dashboard data:', error);
            this.data.properties = JSON.parse(localStorage.getItem('ejari_properties')) || JSON.parse(localStorage.getItem('ejari_seed_properties')) || this.seedProperties();
            this.data.bookings = [];
            this.data.maintenanceRequests = [];
        }
    },

    seedUsers: function () {
        return [
            { id: 1, name: 'أحمد محمد', role: 'tenant', email: 'ahmed@test.com', avatar: 'images/tenant-2.jpg', plan: 'gold', status: 'active' },
            { id: 2, name: 'شركة العقارات الحديثة', role: 'owner', email: 'owner@test.com', avatar: 'images/owner-avatar.jpg', plan: 'premium', status: 'active' },
            { id: 99, name: 'Admin', role: 'admin', email: 'admin@ejari.app', avatar: 'images/logo.png', status: 'active' }
        ];
    },

    seedProperties: function () {
        return [
            { id: 101, title: 'شقة فاخرة بالمعادي', ownerId: 2, price: 12000, status: 'active', location: 'المعادي' },
            { id: 102, title: 'فيلا بالتجمع', ownerId: 2, price: 45000, status: 'rented', location: 'التجمع الخامس' }
        ];
    },

    checkAuth: function () {
        const currentPath = window.location.href;
        let forcedRole = null;

        if (currentPath.includes('owner-dashboard')) forcedRole = 'owner';
        else if (currentPath.includes('admin-dashboard')) forcedRole = 'admin';
        else if (currentPath.includes('tenant-dashboard')) forcedRole = 'tenant';

        const storedUser = JSON.parse(localStorage.getItem('ejari_user'));

        if (forcedRole) {
            const demoUser = this.data.users.find(u => u.role === forcedRole) || this.seedUsers().find(u => u.role === forcedRole);

            if (!storedUser || storedUser.role !== forcedRole) {
                this.currentUser = demoUser;
                localStorage.setItem('ejari_user', JSON.stringify(demoUser));
            } else {
                this.currentUser = storedUser;
            }
        } else {
            this.currentUser = storedUser;
        }
    },

    routeDashboard: function () {
        if (window.location.href.includes('tenant-dashboard')) this.initTenantDashboard();
        if (window.location.href.includes('owner-dashboard')) this.initOwnerDashboard();
        if (window.location.href.includes('admin-dashboard')) this.initAdminDashboard();
    },

    renderCommonElements: function () {
        const nameEls = document.querySelectorAll('.user-name');
        const roleEls = document.querySelectorAll('.user-role');
        const avatarEls = document.querySelectorAll('.user-avatar img');

        if (this.currentUser) {
            // Check verification status
            const isVerified = this.currentUser.verificationStatus === 'verified';
            const verificationBadge = isVerified ?
                '<i class="fas fa-check-circle" style="color: #3b82f6; margin-right: 0.5rem;" title="حساب موثق"></i>' : '';

            nameEls.forEach(el => el.innerHTML = this.currentUser.name + verificationBadge);
            avatarEls.forEach(el => el.src = this.currentUser.avatar);

            let roleText = 'مستخدم';
            if (this.currentUser.role === 'tenant') roleText = 'مستأجر مميز';
            if (this.currentUser.role === 'owner') roleText = 'شريك عقاري';
            if (this.currentUser.role === 'admin') roleText = 'مدير النظام';
            roleEls.forEach(el => el.textContent = roleText);

            // Show/Hide Verify Button for Owners
            if (this.currentUser.role === 'owner') {
                const verifyBtn = document.getElementById('verify-btn');
                if (verifyBtn) {
                    if (isVerified) {
                        verifyBtn.style.display = 'none';
                    } else if (this.currentUser.verificationStatus === 'pending') {
                        verifyBtn.style.display = 'flex';
                        verifyBtn.innerHTML = '<i class="fas fa-clock"></i> قيد المراجعة';
                        verifyBtn.disabled = true;
                        verifyBtn.style.background = '#f1f5f9';
                        verifyBtn.style.color = '#64748b';
                    } else {
                        verifyBtn.style.display = 'flex';
                    }
                }
            }
        }

        document.querySelectorAll('.logout-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                localStorage.removeItem('ejari_user');
                window.location.href = 'index.html';
            });
        });

        // Global Verification Submit Handler
        window.submitVerification = (e) => {
            e.preventDefault();
            const type = document.getElementById('v-type').value;
            const number = document.getElementById('v-number').value;
            const frontDoc = document.getElementById('v-doc-front').files[0];
            const backDoc = document.getElementById('v-doc-back').files[0];

            if (!frontDoc || !backDoc) {
                alert('يرجى رفع صور الهوية المطلوبة');
                return;
            }

            // Update User Status
            this.currentUser.verificationStatus = 'pending';
            this.currentUser.verificationData = {
                type,
                number,
                date: new Date().toISOString()
            };

            // Save to Storage
            localStorage.setItem('ejari_user', JSON.stringify(this.currentUser));

            const users = JSON.parse(localStorage.getItem('ejari_users')) || [];
            const userIndex = users.findIndex(u => u.id === this.currentUser.id);
            if (userIndex !== -1) {
                users[userIndex] = this.currentUser;
                localStorage.setItem('ejari_users', JSON.stringify(users));
            }

            // Add to Verification Requests (for Admin)
            const requests = JSON.parse(localStorage.getItem('ejari_verification_requests')) || [];
            requests.push({
                id: Date.now(),
                userId: this.currentUser.id,
                userName: this.currentUser.name,
                type,
                number,
                status: 'pending',
                date: new Date().toISOString()
            });
            localStorage.setItem('ejari_verification_requests', JSON.stringify(requests));

            document.getElementById('verificationModal').style.display = 'none';
            alert('تم إرسال طلب التوثيق بنجاح! سيتم مراجعته من قبل الإدارة.');
            location.reload(); // Reload to update UI
        };
    },

    // --- EJARI AI ASSISTANT LOGIC ---
    openChat: function (userName = 'المساعد الذكي') {
        if (!document.getElementById('chatModal')) {
            const chatHTML = `
                <div id="chatModal" style="display: none; position: fixed; bottom: 30px; right: 30px; width: 380px; height: 550px; background: var(--elite-navy); border-radius: 24px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); z-index: 5000; flex-direction: column; overflow: hidden; border: 1px solid var(--elite-gold);">
                    <!-- Chat Header -->
                    <div style="background: linear-gradient(135deg, var(--elite-navy), #1a237e); color: white; padding: 1.5rem; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid rgba(197, 160, 89, 0.3);">
                        <div style="display: flex; align-items: center; gap: 1rem;">
                            <div style="width: 45px; height: 45px; background: rgba(197, 160, 89, 0.1); border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 1px solid var(--elite-gold);">
                                <i class="fas fa-brain" style="color: var(--elite-gold);"></i>
                            </div>
                            <div>
                                <div style="font-weight: bold; font-size: 1rem;">إيجاري AI</div>
                                <div style="font-size: 0.75rem; color: var(--elite-accent); display: flex; align-items: center; gap: 4px;">
                                    <span style="width: 8px; height: 8px; background: var(--elite-accent); border-radius: 50%; display: inline-block;"></span> متصل الآن
                                </div>
                            </div>
                        </div>
                        <button onclick="document.getElementById('chatModal').style.display='none'" style="background: none; border: none; color: white; cursor: pointer; font-size: 1.2rem; opacity: 0.7;"><i class="fas fa-times"></i></button>
                    </div>

                    <!-- Messages Container -->
                    <div id="chat-messages" style="flex: 1; padding: 1.5rem; overflow-y: auto; background: #0a192f; display: flex; flex-direction: column; gap: 1rem;">
                        <div style="align-self: flex-start; background: rgba(255,255,255,0.05); color: white; padding: 1rem; border-radius: 18px 18px 18px 0; max-width: 85%; border: 1px solid rgba(255,255,255,0.1); font-size: 0.95rem;">
                            أهلاً بك يا ${this.currentUser.name.split(' ')[0]}! أنا مساعدك الذكي في إيجاري إيليت. كيف يمكنني مساعدتك اليوم؟
                        </div>
                        
                        <!-- Smart Suggestion Bubbles -->
                        <div id="chat-suggestions" style="display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px;">
                            <button onclick="DashboardEngine.sendSmartMessage('كيف أبدأ؟')" style="background: rgba(197, 160, 89, 0.1); border: 1px solid var(--elite-gold); color: var(--elite-gold); padding: 6px 12px; border-radius: 20px; font-size: 0.8rem; cursor: pointer;">كيف أبدأ؟</button>
                            <button onclick="DashboardEngine.sendSmartMessage('ما هي العمولات؟')" style="background: rgba(197, 160, 89, 0.1); border: 1px solid var(--elite-gold); color: var(--elite-gold); padding: 6px 12px; border-radius: 20px; font-size: 0.8rem; cursor: pointer;">ما هي العمولات؟</button>
                            <button onclick="DashboardEngine.sendSmartMessage('حالة توثيق حسابي')" style="background: rgba(197, 160, 89, 0.1); border: 1px solid var(--elite-gold); color: var(--elite-gold); padding: 6px 12px; border-radius: 20px; font-size: 0.8rem; cursor: pointer;">حالة التوثيق</button>
                        </div>
                    </div>

                    <!-- Typing Indicator (Hidden) -->
                    <div id="typing-indicator" style="display: none; padding: 0 1.5rem 1rem; color: var(--elite-accent); font-size: 0.8rem; font-style: italic;">
                        إيجاري AI يكتب الآن...
                    </div>

                    <!-- Chat Input -->
                    <div style="padding: 1.5rem; background: rgba(0,0,0,0.2); border-top: 1px solid rgba(197, 160, 89, 0.2); display: flex; gap: 0.75rem;">
                        <input type="text" id="chat-input" placeholder="اسألني أي شيء..." style="flex: 1; padding: 0.75rem 1.2rem; border: 1px solid rgba(197, 160, 89, 0.3); border-radius: 30px; outline: none; background: rgba(255,255,255,0.05); color: white;">
                        <button onclick="DashboardEngine.sendChatMessage()" style="background: var(--elite-gold); color: var(--elite-navy); border: none; width: 45px; height: 45px; border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.3s ease;"><i class="fas fa-paper-plane"></i></button>
                    </div>
                </div>
            `;
            document.body.insertAdjacentHTML('beforeend', chatHTML);

            document.getElementById('chat-input').addEventListener('keypress', (e) => {
                if (e.key === 'Enter') DashboardEngine.sendChatMessage();
            });
        }

        document.getElementById('chatModal').style.display = 'flex';
    },

    sendSmartMessage: function (text) {
        document.getElementById('chat-input').value = text;
        this.sendChatMessage();
    },

    sendChatMessage: async function () {
        const input = document.getElementById('chat-input');
        const msg = input.value.trim();
        if (!msg) return;

        const container = document.getElementById('chat-messages');
        const suggestions = document.getElementById('chat-suggestions');
        if (suggestions) suggestions.style.display = 'none';

        // رسالة المستخدم
        container.innerHTML += `
            <div style="align-self: flex-end; background: var(--elite-gold); color: var(--elite-navy); padding: 1rem; border-radius: 18px 18px 0 18px; max-width: 85%; font-weight: 500; font-size: 0.95rem; margin-bottom: 0.75rem;">
                ${msg}
            </div>
        `;
        input.value = '';
        container.scrollTop = container.scrollHeight;

        // مؤشر التفكير
        const typing = document.getElementById('typing-indicator');
        typing.style.display = 'block';

        try {
            const API_BASE_URL = 'http://localhost:5050/api';
            const response = await fetch(`${API_BASE_URL}/ai/chat`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: msg })
            });

            typing.style.display = 'none';

            if (!response.ok) throw new Error('AI server error');
            const result = await response.json();
            const { reply, matchedProperties } = result.data;

            // فقاعة رد الذكاء الاصطناعي
            container.innerHTML += `
                <div style="align-self: flex-start; background: rgba(255,255,255,0.05); color: white; padding: 1rem; border-radius: 18px 18px 18px 0; max-width: 85%; border: 1px solid rgba(255,255,255,0.1); font-size: 0.95rem; margin-bottom: 0.75rem; line-height: 1.6;">
                    <span style="color: var(--elite-gold); font-weight: 700; font-size: 0.8rem; display: block; margin-bottom: 0.4rem;">✨ إيجاري كونسيرج</span>
                    ${reply}
                </div>
            `;

            // كروت العقارات المقترحة
            if (matchedProperties && matchedProperties.length > 0) {
                const cardsHTML = matchedProperties.map(p => `
                    <div onclick="window.open('property-details.html?id=${p._id || p.id}', '_blank')"
                         style="min-width: 175px; background: rgba(255,255,255,0.07); border-radius: 16px; border: 1px solid rgba(197,160,89,0.25); overflow: hidden; cursor: pointer; transition: all 0.25s ease; flex-shrink: 0;"
                         onmouseover="this.style.transform='translateY(-4px)'; this.style.borderColor='rgba(197,160,89,0.6)'; this.style.boxShadow='0 12px 30px rgba(0,0,0,0.4)'"
                         onmouseout="this.style.transform='none'; this.style.borderColor='rgba(197,160,89,0.25)'; this.style.boxShadow='none'">
                        <img src="${p.images?.[0] || 'images/home1.jpg'}" alt="${p.title}"
                             style="width: 100%; height: 110px; object-fit: cover;" onerror="this.src='images/home1.jpg'">
                        <div style="padding: 0.75rem;">
                            <div style="font-size: 0.78rem; font-weight: 700; color: white; margin-bottom: 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${p.title}</div>
                            <div style="font-size: 0.82rem; color: var(--elite-gold); font-weight: 700; margin-bottom: 4px;">${(p.price || 0).toLocaleString('ar-EG')} ج.م</div>
                            <div style="font-size: 0.7rem; color: #94a3b8;">
                                🛏 ${p.features?.bedrooms || 0} &nbsp;🚿 ${p.features?.bathrooms || 0} &nbsp;📐 ${p.features?.area || 0}م²
                            </div>
                        </div>
                    </div>
                `).join('');

                container.innerHTML += `
                    <div style="display: flex; gap: 12px; overflow-x: auto; padding: 4px 0 12px 0; margin-bottom: 0.5rem; scrollbar-width: thin; scrollbar-color: rgba(197,160,89,0.3) transparent;">
                        ${cardsHTML}
                    </div>
                `;
            }

        } catch (error) {
            typing.style.display = 'none';
            container.innerHTML += `
                <div style="align-self: flex-start; background: rgba(248,113,113,0.08); color: #fca5a5; padding: 1rem; border-radius: 18px 18px 18px 0; max-width: 85%; border: 1px solid rgba(248,113,113,0.2); font-size: 0.9rem; margin-bottom: 0.75rem;">
                    ⚠️ تعذّر الاتصال بالمساعد الذكي. يرجى التأكد من تشغيل الخادم والمحاولة مجدداً.
                </div>
            `;
        }

        container.scrollTop = container.scrollHeight;
    },

    // --- DIGITAL SIGNATURE & CONTRACT LOGIC ---
    // This provides a high-end "Signing" experience for the demo
    initSignaturePad: function () {
        const canvas = document.getElementById('signature-pad');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        let drawing = false;

        // Set line style
        ctx.strokeStyle = '#0a192f';
        ctx.lineWidth = 3;
        ctx.lineJoin = 'round';
        ctx.lineCap = 'round';

        const getPos = (e) => {
            const rect = canvas.getBoundingClientRect();
            return {
                x: (e.clientX || e.touches[0].clientX) - rect.left,
                y: (e.clientY || e.touches[0].clientY) - rect.top
            };
        };

        const startDrawing = (e) => {
            drawing = true;
            const pos = getPos(e);
            ctx.beginPath();
            ctx.moveTo(pos.x, pos.y);
        };

        const draw = (e) => {
            if (!drawing) return;
            e.preventDefault();
            const pos = getPos(e);
            ctx.lineTo(pos.x, pos.y);
            ctx.stroke();
        };

        const stopDrawing = () => {
            drawing = false;
        };

        canvas.addEventListener('mousedown', startDrawing);
        canvas.addEventListener('mousemove', draw);
        canvas.addEventListener('mouseup', stopDrawing);
        
        canvas.addEventListener('touchstart', startDrawing);
        canvas.addEventListener('touchmove', draw);
        canvas.addEventListener('touchend', stopDrawing);

        window.clearSignature = () => {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
        };
    },

    openSignModal: function (bookingId) {
        if (!document.getElementById('signModal')) {
            const modalHTML = `
                <div id="signModal" style="display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.8); backdrop-filter: blur(8px); z-index: 6000; align-items: center; justify-content: center; padding: 20px;">
                    <div style="background: white; width: 100%; max-width: 500px; border-radius: 30px; overflow: hidden; animation: fadeInUp 0.5s ease;">
                        <div style="background: var(--elite-navy); color: white; padding: 2rem; text-align: center;">
                            <h2 style="color: var(--elite-gold);">التوقيع الرقمي المعتمد</h2>
                            <p style="opacity: 0.8; font-size: 0.9rem;">يرجى رسم توقيعك في المربع أدناه</p>
                        </div>
                        <div style="padding: 2rem; text-align: center;">
                            <canvas id="signature-pad" width="400" height="200" style="border: 2px dashed #cbd5e1; border-radius: 12px; cursor: crosshair; background: #f8fafc; touch-action: none;"></canvas>
                            <div style="display: flex; gap: 1rem; margin-top: 1.5rem;">
                                <button onclick="clearSignature()" style="flex: 1; padding: 1rem; border: 1px solid #cbd5e1; background: none; border-radius: 12px; cursor: pointer;">مسح التوقيع</button>
                                <button onclick="DashboardEngine.processSigning('${bookingId}')" style="flex: 2; padding: 1rem; background: var(--elite-navy); color: var(--elite-gold); border: none; border-radius: 12px; font-weight: bold; cursor: pointer; border: 1px solid var(--elite-gold);">حفظ وتوليد العقد</button>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            document.body.insertAdjacentHTML('beforeend', modalHTML);
        }
        document.getElementById('signModal').style.display = 'flex';
        this.initSignaturePad();
    },

    processSigning: function (bookingId) {
        const canvas = document.getElementById('signature-pad');
        const signatureData = canvas.toDataURL();
        
        // Hide modal
        document.getElementById('signModal').style.display = 'none';
        
        // Open the contract with the real signature
        this.renderFinalContract(bookingId, signatureData);
    },

    renderFinalContract: function (bookingId, signatureData) {
        // Find data
        const booking = this.data.bookings.find(b => b.id == bookingId) ||
            { itemTitle: 'عقار إيليت المميز', totalCost: 12000, startDate: new Date() };

        const contractWindow = window.open('', '_blank');
        contractWindow.document.write(`
            <html dir="rtl">
            <head>
                <title>عقد إيجاري إيليت الموثق</title>
                <style>
                    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;700&display=swap');
                    body { font-family: 'Cairo', sans-serif; padding: 60px; line-height: 1.8; color: #0a192f; }
                    .watermark { position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%) rotate(-45deg); font-size: 8rem; color: rgba(0,0,0,0.03); z-index: -1; white-space: nowrap; }
                    .header { text-align: center; border-bottom: 3px double #c5a059; padding-bottom: 20px; margin-bottom: 40px; }
                    .ejari-seal { width: 100px; height: 100px; border: 4px solid #c5a059; border-radius: 50%; color: #c5a059; display: flex; align-items: center; justify-content: center; font-weight: 800; margin: 0 auto 20px; font-size: 0.8rem; text-align: center; }
                    .section { margin-bottom: 30px; background: #fff; padding: 20px; border-right: 5px solid #c5a059; }
                    .signature-box { margin-top: 60px; display: flex; justify-content: space-between; align-items: center; }
                    .sign-place { text-align: center; flex: 1; }
                    .sign-img { max-height: 80px; border-bottom: 2px solid #0a192f; padding-bottom: 10px; }
                </style>
            </head>
            <body>
                <div class="watermark">EJARI ELITE</div>
                <div class="header">
                    <div class="ejari-seal">EJARI<br>CERTIFIED</div>
                    <h1>عقد إيجار رقمي موثق</h1>
                    <p>هذا العقد معتمد من منصة إيجاري ومحمي بتقنية Blockchain (محاكاة)</p>
                </div>
                
                <div class="section">
                    <h3>1. أطراف التعاقد</h3>
                    <p>الطرف الأول (المؤجر): شركة إيجاري إيليت لإدارة الأصول</p>
                    <p>الطرف الثاني (المستأجر): ${this.currentUser.name}</p>
                </div>

                <div class="section">
                    <h3>2. موضوع التعاقد</h3>
                    <p>العقار/الخدمة: ${booking.itemTitle || 'فيلا السكينة - التجمع الخامس'}</p>
                    <p>القيمة: ${parseInt(booking.totalCost || 12000).toLocaleString()} ج.م</p>
                </div>

                <div class="section">
                    <h3>3. الإقرارات</h3>
                    <p>يقر الطرفان بصحة البيانات وبالتزامهم ببنود العقد الإلكتروني الموحد.</p>
                </div>

                <div class="signature-box">
                    <div class="sign-place">
                        <p>ختم المنصة</p>
                        <i style="color: #c5a059;">(ختم رقمي مشفر)</i>
                    </div>
                    <div class="sign-place">
                        <p>توقيع المستأجر</p>
                        <img src="${signatureData}" class="sign-img" alt="Signature">
                        <p style="font-size: 0.7rem; color: #64748b;">توقيع إلكتروني موثق من عنوان IP: 192.168.1.1</p>
                    </div>
                </div>

                <script>setTimeout(() => window.print(), 500);</script>
            </body>
            </html>
        `);
        contractWindow.document.close();
    },

    downloadContract: function (bookingId) {
        this.openSignModal(bookingId);
    },

    // --- TENANT LOGIC ---
    initTenantDashboard: function () {
        this.renderTenantStats();
        this.renderTenantBookings();
        this.renderTenantMaintenance();
        this.renderRewards();
        this.setupTenantActions();
    },

    renderTenantStats: function () {
        const activeRentals = this.data.bookings.filter(b => b.userId === this.currentUser.id && b.status === 'active').length;
        const totalSpent = this.data.bookings
            .filter(b => b.userId === this.currentUser.id)
            .reduce((acc, curr) => acc + parseInt(curr.totalCost || 0), 0);

        // Ensure user has points property
        if (typeof this.currentUser.points === 'undefined') {
            this.currentUser.points = 0;
            // Update storage
            const users = JSON.parse(localStorage.getItem('ejari_users')) || [];
            const userIndex = users.findIndex(u => u.id === this.currentUser.id);
            if (userIndex !== -1) {
                users[userIndex].points = 0;
                localStorage.setItem('ejari_users', JSON.stringify(users));
            }
            localStorage.setItem('ejari_user', JSON.stringify(this.currentUser));
        }

        const activeEl = document.getElementById('stat-active-rentals');
        const spentEl = document.getElementById('stat-total-spent');
        const pointsEl = document.getElementById('stat-points');
        const headerPointsEl = document.getElementById('header-points');

        if (activeEl) activeEl.textContent = activeRentals;
        if (spentEl) spentEl.textContent = totalSpent.toLocaleString() + ' ج.م';
        if (pointsEl) pointsEl.textContent = this.currentUser.points;
        if (headerPointsEl) headerPointsEl.textContent = this.currentUser.points;

        // --- TENANT VERIFICATION STATUS UPDATE ---
        const verifyBtn = document.getElementById('tenant-verify-btn');
        const verifyAlert = document.getElementById('tenant-verification-alert');
        const isVerified = this.currentUser.verificationStatus === 'verified';
        const isPending = this.currentUser.verificationStatus === 'pending';

        if (verifyBtn) {
            if (isVerified) {
                verifyBtn.style.display = 'none';
            } else if (isPending) {
                verifyBtn.style.display = 'flex';
                verifyBtn.innerHTML = '<i class="fas fa-clock"></i> قيد المراجعة';
                verifyBtn.disabled = true;
                verifyBtn.style.background = '#94a3b8';
            } else {
                verifyBtn.style.display = 'flex';
            }
        }

        if (verifyAlert) {
            if (isVerified || isPending) {
                verifyAlert.style.display = 'none';
            } else {
                verifyAlert.style.display = 'flex';
            }
        }
    },

    renderRewards: function () {
        const pointsDisplay = document.getElementById('rewards-points-display');
        const pointsValue = document.getElementById('points-value');
        const historyList = document.getElementById('points-history-list');

        if (pointsDisplay) pointsDisplay.textContent = this.currentUser.points || 0;
        if (pointsValue) pointsValue.textContent = ((this.currentUser.points || 0) * 0.1).toFixed(2); // 1 point = 0.1 EGP

        if (historyList) {
            const history = this.currentUser.pointsHistory || [];
            if (history.length === 0) {
                historyList.innerHTML = '<div style="padding: 2rem; text-align: center; color: #94a3b8;">لا يوجد سجل نقاط حتى الآن</div>';
            } else {
                historyList.innerHTML = history.map(item => `
                    <div class="booking-item">
                        <div style="width: 50px; height: 50px; background: ${item.type === 'earn' ? '#dcfce7' : '#fee2e2'}; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: ${item.type === 'earn' ? '#16a34a' : '#ef4444'}; font-size: 1.5rem;">
                            <i class="fas ${item.type === 'earn' ? 'fa-arrow-up' : 'fa-arrow-down'}"></i>
                        </div>
                        <div class="booking-info">
                            <h4>${item.description}</h4>
                            <p>${new Date(item.date).toLocaleDateString('ar-EG')}</p>
                        </div>
                        <div style="font-weight: bold; color: ${item.type === 'earn' ? '#16a34a' : '#ef4444'};">
                            ${item.type === 'earn' ? '+' : '-'}${item.amount} نقطة
                        </div>
                    </div>
                `).join('');
            }
        }
    },

    downloadInvoice: function (bookingId) {
        // Mock invoice generation
        const invoiceContent = `
            <html>
            <head>
                <title>فاتورة ضريبية</title>
                <style>
                    body { font-family: 'Cairo', sans-serif; direction: rtl; padding: 2rem; }
                    .header { text-align: center; margin-bottom: 2rem; border-bottom: 2px solid #eee; padding-bottom: 1rem; }
                    .details { margin-bottom: 2rem; }
                    .table { width: 100%; border-collapse: collapse; margin-bottom: 2rem; }
                    .table th, .table td { border: 1px solid #ddd; padding: 1rem; text-align: right; }
                    .total { text-align: left; font-size: 1.5rem; font-weight: bold; }
                    .footer { margin-top: 3rem; text-align: center; color: #666; font-size: 0.9rem; }
                </style>
            </head>
            <body>
                <div class="header">
                    <h1>إيجاري - فاتورة ضريبية</h1>
                    <p>رقم الفاتورة: INV-${Date.now()}</p>
                    <p>التاريخ: ${new Date().toLocaleDateString('ar-EG')}</p>
                </div>
                <div class="details">
                    <h3>بيانات العميل:</h3>
                    <p>الاسم: ${this.currentUser.name}</p>
                    <p>البريد الإلكتروني: ${this.currentUser.email}</p>
                </div>
                <table class="table">
                    <thead>
                        <tr>
                            <th>البند</th>
                            <th>القيمة</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>إيجار وحدة سكنية - شهر نوفمبر</td>
                            <td>12,000 ج.م</td>
                        </tr>
                        <tr>
                            <td>رسوم خدمة</td>
                            <td>200 ج.م</td>
                        </tr>
                    </tbody>
                </table>
                <div class="total">
                    الإجمالي: 12,200 ج.م
                </div>
                <div class="footer">
                    <p>تم إصدار هذه الفاتورة إلكترونياً من منصة إيجاري</p>
                    <p>سجل تجاري: 123456 - بطاقة ضريبية: 789-456-123</p>
                </div>
                <script>window.print();</script>
            </body>
            </html>
        `;

        const win = window.open('', '_blank');
        win.document.write(invoiceContent);
        win.document.close();
    },

    renderTenantBookings: function () {
        const container = document.getElementById('tenant-bookings-list');
        if (!container) return;

        // Backend bookings are already filtered by the server for the logged-in user, but support local fallback just in case
        const myBookings = this.data.bookings.filter(b => !b.user || b.user._id === this.currentUser._id || b.user === this.currentUser.id || b.userId === this.currentUser.id);
        const localBooking = JSON.parse(localStorage.getItem('currentBooking')) || null;
        if (myBookings.length === 0 && localBooking) {
            myBookings.push({
                ...localBooking,
                status: localBooking.status || 'pending',
                userId: this.currentUser.id,
                property: {
                    title: localBooking.itemTitle,
                    images: [localBooking.itemImage || 'images/home1.jpg'],
                    location: { address: localBooking.location || '' },
                    price: localBooking.totalCost || localBooking.price || 0
                }
            });
        }

        if (myBookings.length === 0) {
            const emptyHTML = '<div style="grid-column: 1/-1; text-align: center; padding: 3rem; background: white; border-radius: 12px;"><h3>لا توجد حجوزات نشطة</h3><p style="color: #6b7280; margin-bottom: 1rem;">لم تقم بأي عمليات حجز حتى الآن.</p><a href="properties.html" class="btn-primary" style="display: inline-block; text-decoration: none;">تصفح العقارات</a></div>';
            container.innerHTML = emptyHTML;

            const recentContainer = document.getElementById('recent-bookings-list');
            if (recentContainer) recentContainer.innerHTML = emptyHTML;
            return;
        }

        const bookingsHTML = myBookings.map(booking => {
            const propImage = (booking.property?.images && booking.property.images[0]) || booking.itemImage || 'images/home1.jpg';
            const propTitle = booking.property?.title || booking.itemTitle || 'عقار إيليت';
            const propLocation = booking.property?.location?.address || booking.location || 'القاهرة';
            const propPrice = booking.property?.price || booking.totalCost || booking.price || 0;
            const bId = booking.id || booking._id;
            return `
            <div class="booking-item">
                <img src="${propImage}" class="booking-img" alt="Item">
                <div class="booking-info">
                    <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
                        <span class="status-badge active">${booking.status || 'نشط'}</span>
                        <span style="font-size: 0.85rem; color: #64748b;">${booking.type === 'car' ? 'تأجير سيارة' : 'إيجار عقار'}</span>
                    </div>
                    <h4>${propTitle}</h4>
                    <p><i class="fas fa-map-marker-alt"></i> ${propLocation}</p>
                    <p class="date"><i class="far fa-calendar-alt"></i> ينتهي في: ${this.calculateEndDate(booking.startDate, booking.duration || 1, booking.durationUnit || 'months')}</p>
                </div>
                <div style="text-align: left;">
                    <div style="font-weight: bold; margin-bottom: 0.5rem;">${parseInt(propPrice).toLocaleString()} ج.م</div>
                    <button class="btn-primary" style="font-size: 0.85rem; padding: 0.5rem 1rem;" onclick="DashboardEngine.downloadContract('${bId}')">تحميل العقد</button>
                </div>
            </div>
        `; }).join('');

        container.innerHTML = bookingsHTML;

        const recentContainer = document.getElementById('recent-bookings-list');
        if (recentContainer) recentContainer.innerHTML = bookingsHTML;

        const maintenanceSelect = document.getElementById('m-property');
        if (maintenanceSelect) {
            maintenanceSelect.innerHTML = '<option value="">اختر العقار...</option>' +
                myBookings.map(b => {
                    const propId = b.property?._id || b.property || '';
                    const propTitle = b.property?.title || b.itemTitle || '';
                    return `<option value="${propId}">${propTitle}</option>`;
                }).join('');
        }
    },

    renderTenantMaintenance: function () {
        const container = document.getElementById('maintenance-requests-list');
        if (!container) return;

        const myRequests = this.data.maintenanceRequests || [];

        if (myRequests.length > 0) {
            container.innerHTML = myRequests.map(req => `
                <div class="booking-item">
                    <div style="width: 50px; height: 50px; background: #fff7ed; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: #f97316; font-size: 1.5rem;">
                        <i class="fas fa-tools"></i>
                    </div>
                    <div class="booking-info">
                        <h4>${req.title}</h4>
                        <p>${req.property}</p>
                        <p style="font-size: 0.85rem;">${req.desc}</p>
                    </div>
                    <span class="status-badge pending">قيد المعالجة</span>
                </div>
            `).join('');
        }
    },

    setupTenantActions: function () {
        window.submitMaintenance = async (e) => {
            e.preventDefault();
            const propertyId = document.getElementById('m-property').value;
            const type = document.getElementById('m-type').value;
            const desc = document.getElementById('m-desc').value;

            if (!propertyId || !type || !desc) {
                alert('اليجاء اختيار العقار وتحديد نوع ووصف الصيانة');
                return;
            }

            const token = localStorage.getItem('ejari_token');
            const API_BASE_URL = 'http://localhost:5050/api';

            try {
                const response = await fetch(`${API_BASE_URL}/maintenance`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify({
                        property: propertyId,
                        type: type,
                        description: desc
                    })
                });

                const result = await response.json();

                if (!response.ok || !result.success) {
                    alert(result.error || 'فشل إرسال طلب الصيانة');
                    return;
                }

                alert('تم إرسال طلب الصيانة بنجاح. سيتم التواصل معك قريباً.');
                document.getElementById('maintenanceModal').style.display = 'none';

                // Reload data
                await this.loadData();
                this.renderTenantMaintenance();
            } catch (error) {
                console.error(error);
                alert('حدث خطأ أثناء الاتصال بالخادم لإرسال طلب الصيانة.');
            }
        };

        // --- OPEN TENANT VERIFICATION MODAL ---
        window.openTenantVerificationModal = () => {
            document.getElementById('tenantVerificationModal').style.display = 'flex';
        };

        // --- TENANT VERIFICATION ---
        window.submitTenantVerification = (e) => {
            e.preventDefault();

            const fullname = document.getElementById('tv-fullname').value;
            const idNumber = document.getElementById('tv-id-number').value;

            // Mock file upload
            const idFront = document.getElementById('tv-id-front').files[0];
            const photo = document.getElementById('tv-photo').files[0];

            if (!idFront || !photo) {
                alert('يرجى رفع جميع المستندات المطلوبة');
                return;
            }

            // Create verification request
            const verificationRequest = {
                id: Date.now(),
                userId: this.currentUser.id,
                userType: 'tenant',
                fullname: fullname,
                idNumber: idNumber,
                idFront: 'mock_id_front.jpg', // Mock
                photo: 'mock_photo.jpg', // Mock
                status: 'pending',
                date: new Date().toISOString()
            };

            // Save to verification requests
            let requests = JSON.parse(localStorage.getItem('ejari_verification_requests')) || [];
            requests.push(verificationRequest);
            localStorage.setItem('ejari_verification_requests', JSON.stringify(requests));

            // Update user status
            this.currentUser.verificationStatus = 'pending';
            this.currentUser.verificationData = {
                fullname,
                idNumber
            };
            this.saveUser();

            document.getElementById('tenantVerificationModal').style.display = 'none';
            alert('تم إرسال طلب التوثيق بنجاح! سيتم مراجعته من قبل الإدارة.');
        };

        // --- TENANT REDEEM POINTS ---
        window.openTenantRedeemPointsModal = () => {
            const modal = document.getElementById('tenantRedeemPointsModal');
            const display = document.getElementById('tenant-modal-points-display');
            if (display) display.textContent = this.currentUser.points;
            modal.style.display = 'flex';
        };

        window.redeemTenantPoints = (type) => {
            if (type === 'rent') {
                if (this.currentUser.points < 100) {
                    alert('عفواً، رصيد نقاطك غير كافٍ. الحد الأدنى 100 نقطة.');
                    return;
                }
                const discount = Math.floor(this.currentUser.points / 100) * 10; // 10 EGP per 100 points
                const pointsUsed = Math.floor(this.currentUser.points / 100) * 100;

                if (confirm(`هل تريد استبدال ${pointsUsed} نقطة مقابل ${discount} ج.م خصم على الإيجار القادم؟`)) {
                    this.currentUser.points -= pointsUsed;

                    // Store discount for next booking
                    this.currentUser.pendingDiscount = (this.currentUser.pendingDiscount || 0) + discount;

                    alert(`تم استبدال ${pointsUsed} نقطة!\nلديك خصم ${discount} ج.م سيتم تطبيقه على حجزك القادم.`);

                    // Add history
                    if (!this.currentUser.pointsHistory) this.currentUser.pointsHistory = [];
                    this.currentUser.pointsHistory.unshift({
                        amount: pointsUsed,
                        description: 'استبدال نقاط بخصم على الإيجار',
                        date: new Date().toISOString(),
                        type: 'spend'
                    });

                    this.saveUser();
                    this.renderTenantStats();
                    this.renderRewards();
                    document.getElementById('tenantRedeemPointsModal').style.display = 'none';
                }
            } else if (type === 'voucher') {
                if (this.currentUser.points < 500) {
                    alert('عفواً، رصيد نقاطك غير كافٍ. تحتاج 500 نقطة لهذا العرض.');
                    return;
                }
                if (confirm('هل تريد استبدال 500 نقطة مقابل قسيمة شرائية بقيمة 50 ج.م؟')) {
                    this.currentUser.points -= 500;

                    // Generate voucher code
                    const voucherCode = 'EJARI-' + Math.random().toString(36).substr(2, 8).toUpperCase();

                    alert(`تم إنشاء القسيمة بنجاح!\nكود القسيمة: ${voucherCode}\nالقيمة: 50 ج.م`);

                    // Add history
                    if (!this.currentUser.pointsHistory) this.currentUser.pointsHistory = [];
                    this.currentUser.pointsHistory.unshift({
                        amount: 500,
                        description: `قسيمة شرائية (${voucherCode})`,
                        date: new Date().toISOString(),
                        type: 'spend'
                    });

                    this.saveUser();
                    this.renderTenantStats();
                    this.renderRewards();
                    document.getElementById('tenantRedeemPointsModal').style.display = 'none';
                }
            }
        };
    },

    // --- OWNER LOGIC ---
    initOwnerDashboard: function () {
        console.log('Initializing Owner Dashboard...');

        // Ensure User Data Exists (Mock Data for Demo)
        if (!this.currentUser.points) {
            this.currentUser.points = 150; // Start with some points
            this.currentUser.subscriptionPlan = 'basic';
            this.currentUser.verificationStatus = this.currentUser.verificationStatus || 'unverified';
            this.saveUser();
        }

        // Generate Rental Transactions from Bookings (Backfill)
        this.generateRentalTransactions();

        this.renderOwnerStats();
        this.renderOwnerProperties();
        this.renderOwnerTenants();
        this.renderOwnerContracts();
        this.renderOwnerWallet();

        // renderRewards is generic and handles history list, so we use it.
        this.renderRewards();

        this.setupOwnerActions();
        console.log('Owner Dashboard Initialized. Points:', this.currentUser.points);
    },

    generateRentalTransactions: function () {
        if (!this.currentUser.walletTransactions) {
            this.currentUser.walletTransactions = [];
        }

        const myProps = this.data.properties.filter(p => p.ownerId === this.currentUser.id);
        const myPropIds = myProps.map(p => p.id);
        const bookings = this.data.bookings.filter(b => myPropIds.includes(b.propertyId) && b.paymentStatus === 'paid');

        // Check if bookings are already in transactions to avoid duplicates
        // We assume transaction ID for rental is 'rent_' + bookingId
        const existingTransactionIds = this.currentUser.walletTransactions.map(t => t.id);

        let newTransactions = false;
        bookings.forEach(booking => {
            const transactionId = 'rent_' + booking.id;
            if (!existingTransactionIds.includes(transactionId)) {
                // Find Tenant Name
                const tenant = this.data.users.find(u => u.id === booking.userId);
                const tenantName = tenant ? tenant.name : 'مستأجر';

                this.currentUser.walletTransactions.unshift({
                    id: transactionId,
                    type: 'credit',
                    amount: booking.totalCost * 0.95, // 95% after platform fee
                    description: `إيراد إيجار من: ${tenantName} (${booking.itemTitle})`,
                    date: booking.paymentDate || new Date().toISOString(),
                    source: tenantName
                });
                newTransactions = true;
            }
        });

        if (newTransactions) {
            // Sort by date desc
            this.currentUser.walletTransactions.sort((a, b) => new Date(b.date) - new Date(a.date));
            this.saveUser();
        }

        // --- FORCE MOCK DATA FOR DEMO IF EMPTY ---
        // If only reward transaction exists (or none), let's add some rental income for demo
        if (this.currentUser.walletTransactions.length <= 1) {
            const mockRentals = [
                {
                    id: 'mock_rent_1',
                    type: 'credit',
                    amount: 4750, // 5000 - 5%
                    description: 'إيراد إيجار من: محمد أحمد (شقة الدقي)',
                    date: new Date(Date.now() - 86400000 * 2).toISOString(), // 2 days ago
                    source: 'محمد أحمد'
                },
                {
                    id: 'mock_rent_2',
                    type: 'credit',
                    amount: 8550, // 9000 - 5%
                    description: 'إيراد إيجار من: سارة علي (فيلا الساحل)',
                    date: new Date(Date.now() - 86400000 * 10).toISOString(), // 10 days ago
                    source: 'سارة علي'
                }
            ];

            // Add if not exists
            mockRentals.forEach(m => {
                if (!this.currentUser.walletTransactions.find(t => t.id === m.id)) {
                    this.currentUser.walletTransactions.push(m);
                }
            });

            this.currentUser.walletTransactions.sort((a, b) => new Date(b.date) - new Date(a.date));
            this.saveUser();

            // Refresh view immediately
            this.renderOwnerStats();
            this.renderOwnerWallet();
        }
    },

    setupOwnerActions: function () {
        window.openAddPropertyModal = () => document.getElementById('addPropertyModal').style.display = 'flex';
        window.closeAddPropertyModal = () => document.getElementById('addPropertyModal').style.display = 'none';

        window.openRedeemPointsModal = () => {
            const modal = document.getElementById('redeemPointsModal');
            const display = document.getElementById('modal-points-display');
            if (display) display.textContent = this.currentUser.points;
            modal.style.display = 'flex';
        };

        window.redeemPoints = (type) => {
            if (type === 'wallet') {
                if (this.currentUser.points < 100) {
                    alert('عفواً، رصيد نقاطك غير كافٍ. الحد الأدنى 100 نقطة.');
                    return;
                }
                const amount = Math.floor(this.currentUser.points / 100) * 10; // 10 EGP per 100 points
                const pointsUsed = Math.floor(this.currentUser.points / 100) * 100;

                if (confirm(`هل تريد استبدال ${pointsUsed} نقطة مقابل ${amount} ج.م تضاف لمحفظتك؟`)) {
                    this.currentUser.points -= pointsUsed;

                    // Update Wallet Balance
                    this.currentUser.walletBalance = (this.currentUser.walletBalance || 0) + amount;

                    // Add Wallet Transaction
                    if (!this.currentUser.walletTransactions) this.currentUser.walletTransactions = [];
                    this.currentUser.walletTransactions.unshift({
                        id: Date.now(),
                        type: 'credit',
                        amount: amount,
                        description: 'استبدال نقاط مكافآت',
                        date: new Date().toISOString()
                    });

                    alert(`تم تحويل ${amount} ج.م إلى محفظتك بنجاح!`);

                    // Add Points History
                    if (!this.currentUser.pointsHistory) this.currentUser.pointsHistory = [];
                    this.currentUser.pointsHistory.unshift({
                        amount: pointsUsed,
                        description: 'استبدال نقاط لرصيد المحفظة',
                        date: new Date().toISOString(),
                        type: 'spend'
                    });

                    this.saveUser();
                    this.renderOwnerStats();
                    this.renderOwnerWallet(); // Refresh wallet view
                    this.renderRewards();
                    document.getElementById('redeemPointsModal').style.display = 'none';
                }
            } else if (type === 'commission') {
                if (this.currentUser.points < 500) {
                    alert('عفواً، رصيد نقاطك غير كافٍ. تحتاج 500 نقطة لهذا العرض.');
                    return;
                }
                if (confirm('هل تريد استبدال 500 نقطة مقابل خصم 50% على العمولة لمدة شهر؟')) {
                    this.currentUser.points -= 500;
                    alert('تم تفعيل الخصم بنجاح!');

                    // Add history
                    if (!this.currentUser.pointsHistory) this.currentUser.pointsHistory = [];
                    this.currentUser.pointsHistory.unshift({
                        amount: 500,
                        description: 'استبدال نقاط بخصم عمولة',
                        date: new Date().toISOString(),
                        type: 'spend'
                    });

                    this.saveUser();
                    this.renderOwnerStats();
                    this.renderRewards();
                    document.getElementById('redeemPointsModal').style.display = 'none';
                }
            }
        };

        // --- WITHDRAWAL LOGIC ---
        window.requestWithdrawal = () => {
            const modal = document.getElementById('withdrawalModal');
            const balanceDisplay = document.getElementById('w-available-balance');
            if (balanceDisplay) balanceDisplay.textContent = (this.currentWalletBalance || 0).toLocaleString();
            modal.style.display = 'flex';
        };

        window.calculateWithdrawalFees = () => {
            const amount = parseFloat(document.getElementById('w-amount').value) || 0;
            // Fee: 1.55 EGP per 1000 EGP
            const fee = (amount / 1000) * 1.55;
            const net = amount - fee;

            document.getElementById('w-summary-amount').textContent = amount.toLocaleString() + ' ج.م';
            document.getElementById('w-summary-fees').textContent = fee.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' ج.م';
            document.getElementById('w-summary-net').textContent = net.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' ج.م';
        };

        window.submitWithdrawal = () => {
            const amount = parseFloat(document.getElementById('w-amount').value);
            const method = document.getElementById('w-method').value;
            const currentBalance = this.currentWalletBalance || 0;

            if (!amount || amount <= 0) {
                alert('يرجى إدخال مبلغ صحيح.');
                return;
            }

            if (amount > currentBalance) {
                alert('عفواً، الرصيد غير كافٍ.');
                return;
            }

            if (amount < 500) {
                alert('الحد الأدنى للسحب هو 500 ج.م');
                return;
            }

            // Fee: 1.55 EGP per 1000 EGP
            const fee = (amount / 1000) * 1.55;
            const net = amount - fee;

            if (confirm(`تأكيد سحب مبلغ ${amount} ج.م؟\nسيتم خصم رسوم ${fee.toFixed(2)} ج.م\nصافي المبلغ المستلم: ${net.toFixed(2)} ج.م`)) {
                // Add Transaction
                if (!this.currentUser.walletTransactions) this.currentUser.walletTransactions = [];

                this.currentUser.walletTransactions.unshift({
                    id: Date.now(),
                    type: 'debit',
                    amount: amount, // Deduct full amount including fees
                    description: `سحب رصيد إلى ${method === 'bank' ? 'حساب بنكي' : 'محفظة إلكترونية'}`,
                    date: new Date().toISOString(),
                    fee: fee,
                    net: net
                });

                // Reset legacy walletBalance if it exists to avoid double counting
                this.currentUser.walletBalance = 0;

                this.saveUser();
                this.renderOwnerStats();
                this.renderOwnerWallet();

                document.getElementById('withdrawalModal').style.display = 'none';

                // Notification
                this.sendNotification('تم استلام طلب السحب بنجاح. سيتم التحويل خلال 24 ساعة.', 'success');
            }
        };

        // Helper for Notifications
        this.sendNotification = (message, type = 'info') => {
            // Mock notification - in real app push to DB
            alert(message);

            // Add to local notifications list if we had a UI for it
            /*
            if (!this.currentUser.notifications) this.currentUser.notifications = [];
            this.currentUser.notifications.unshift({
                id: Date.now(),
                message: message,
                type: type,
                read: false,
                date: new Date().toISOString()
            });
            this.saveUser();
            */
        };

        window.submitNewProperty = (e) => {
            e.preventDefault();
            const title = document.getElementById('p-title').value;
            const price = document.getElementById('p-price').value;
            const location = document.getElementById('p-location').value;
            const address = document.getElementById('p-address').value;
            const gps = document.getElementById('p-gps').value;
            const images = document.getElementById('p-images').files;
            const video = document.getElementById('p-video').files;

            if (images.length < 3) {
                alert('يجب رفع 3 صور على الأقل للعقار.');
                return;
            }
            if (video.length === 0) {
                alert('فيديو الجولة التفصيلية إجباري.');
                return;
            }

            const newProp = {
                id: Date.now(),
                title: title,
                price: parseInt(price),
                location: location,
                address: address,
                gps: gps,
                ownerId: this.currentUser.id,
                status: 'active',
                image: 'images/home3.jpg'
            };

            this.data.properties.push(newProp);
            localStorage.setItem('ejari_properties', JSON.stringify(this.data.properties));

            // Add points for new property
            this.addPoints(50, 'إضافة عقار جديد: ' + title);

            this.renderOwnerProperties();
            this.renderOwnerStats();
            window.closeAddPropertyModal();
            alert('تم إضافة العقار بنجاح! وتم إضافة 50 نقطة لرصيدك.');
        };

        window.submitEditProperty = (e) => {
            e.preventDefault();
            const id = parseInt(document.getElementById('edit-p-id').value);
            const title = document.getElementById('edit-p-title').value;
            const price = document.getElementById('edit-p-price').value;
            const location = document.getElementById('edit-p-location').value;
            const address = document.getElementById('edit-p-address').value;
            const status = document.getElementById('edit-p-status').value;

            const propIndex = this.data.properties.findIndex(p => p.id === id);
            if (propIndex === -1) return;

            this.data.properties[propIndex] = {
                ...this.data.properties[propIndex],
                title: title,
                price: parseInt(price),
                location: location,
                address: address,
                status: status
            };

            localStorage.setItem('ejari_properties', JSON.stringify(this.data.properties));
            this.renderOwnerProperties();
            this.renderOwnerStats();
            document.getElementById('editPropertyModal').style.display = 'none';
            alert('تم تعديل بيانات العقار بنجاح.');
        };

        window.openLinkMethodModal = () => document.getElementById('linkMethodModal').style.display = 'flex';

        window.submitLinkMethod = (e) => {
            e.preventDefault();
            const type = document.getElementById('method-type').value;
            const details = document.getElementById('method-details').value;

            const methods = JSON.parse(localStorage.getItem('ejari_payment_methods')) || [];
            methods.push({ type, details, ownerId: this.currentUser.id });
            localStorage.setItem('ejari_payment_methods', JSON.stringify(methods));

            this.renderOwnerWallet();
            document.getElementById('linkMethodModal').style.display = 'none';
            alert('تم ربط وسيلة السحب بنجاح');
        };



        DashboardEngine.deleteProperty = function (id) {
            if (confirm('هل أنت متأكد من حذف هذا العقار؟')) {
                this.data.properties = this.data.properties.filter(p => p.id !== id);
                localStorage.setItem('ejari_properties', JSON.stringify(this.data.properties));
                this.renderOwnerProperties();
                this.renderOwnerStats();
            }
        }.bind(this);
    },

    renderOwnerStats: function () {
        const myProps = this.data.properties.filter(p => p.ownerId === this.currentUser.id);
        const rentedProps = myProps.filter(p => p.status === 'rented');

        const income = rentedProps.reduce((acc, curr) => acc + curr.price, 0);
        const occupancy = myProps.length ? Math.round((rentedProps.length / myProps.length) * 100) : 0;

        // Ensure user has points property
        if (typeof this.currentUser.points === 'undefined') {
            this.currentUser.points = 0;
            this.saveUser();
        }

        // --- POINTS UPDATE ---
        const pointsEl = document.getElementById('stat-points');
        const headerPointsEl = document.getElementById('header-points');
        const rewardsPointsEl = document.getElementById('rewards-points-display');
        const pointsValueEl = document.getElementById('points-value');

        if (pointsEl) pointsEl.textContent = this.currentUser.points;
        if (headerPointsEl) headerPointsEl.textContent = this.currentUser.points;
        if (rewardsPointsEl) rewardsPointsEl.textContent = this.currentUser.points;
        if (pointsValueEl) pointsValueEl.textContent = (this.currentUser.points * 0.1).toFixed(2); // 1 Point = 0.1 EGP

        // --- VERIFICATION STATUS UPDATE ---
        const verifyBtn = document.getElementById('verify-btn');
        const verifyAlert = document.getElementById('verification-alert');
        const isVerified = this.currentUser.verificationStatus === 'verified';
        const isPending = this.currentUser.verificationStatus === 'pending';

        if (verifyBtn) {
            if (isVerified) {
                verifyBtn.style.display = 'none';
            } else if (isPending) {
                verifyBtn.style.display = 'flex';
                verifyBtn.innerHTML = '<i class="fas fa-clock"></i> قيد المراجعة';
                verifyBtn.disabled = true;
                verifyBtn.style.background = '#94a3b8';
            } else {
                verifyBtn.style.display = 'flex';
            }
        }

        if (verifyAlert) {
            if (isVerified || isPending) {
                verifyAlert.style.display = 'none';
            } else {
                verifyAlert.style.display = 'flex';
            }
        }

        // --- INCOME & OCCUPANCY ---
        const incomeEl = document.getElementById('owner-income');
        const occupancyEl = document.getElementById('owner-occupancy');

        if (incomeEl) incomeEl.textContent = income.toLocaleString() + ' ج.م';
        if (occupancyEl) occupancyEl.textContent = occupancy + '%';

        // Wallet Balance Calculation from Ledger (Transactions)
        const transactions = this.currentUser.walletTransactions || [];
        const totalBalance = transactions.reduce((acc, t) => {
            return t.type === 'credit' ? acc + t.amount : acc - t.amount;
        }, 0) + (this.currentUser.walletBalance || 0); // Add legacy balance if any, though we should migrate it.

        // Let's just use the calculated balance as the truth for display
        // But wait, if we have 'walletBalance' stored from previous step (redeem points), we should include it?
        // Actually, redeem points adds a transaction now. So transactions cover everything.
        // EXCEPT the initial 'walletBalance' if it wasn't converted to a transaction.
        // For safety, let's rely on transactions sum.

        const balanceEl = document.getElementById('wallet-balance');
        if (balanceEl) balanceEl.textContent = totalBalance.toLocaleString() + ' ج.م';

        // Store calculated balance for withdrawal check
        this.currentWalletBalance = totalBalance;

        // Render Subscriptions
        this.renderOwnerSubscriptions();
    },

    renderOwnerSubscriptions: function () {
        const container = document.getElementById('view-subscriptions');
        if (!container) return;

        // Default to 'basic' if not set
        const currentPlan = this.currentUser.subscriptionPlan || 'basic';

        // Update UI based on plan
        const plans = [
            { id: 'basic', name: 'الباقة الأساسية', price: 'مجاناً' },
            { id: 'pro', name: 'باقة المحترفين', price: '499 ج.م' },
            { id: 'enterprise', name: 'باقة الشركات', price: '1999 ج.م' }
        ];

        // This is a simplified logic to update button text. 
        // In a real app, we would regenerate the HTML or toggle classes.
        // Here we will assume the HTML structure is static and just update buttons.

        // Basic Plan Button
        const basicBtn = container.querySelector('.stat-card:nth-child(1) button');
        if (basicBtn) {
            if (currentPlan === 'basic') {
                basicBtn.textContent = 'الباقة الحالية';
                basicBtn.disabled = true;
                basicBtn.style.background = '#e2e8f0';
                basicBtn.style.color = '#475569';
            } else {
                basicBtn.textContent = 'تخفيض للباقة';
                basicBtn.disabled = false;
                basicBtn.onclick = () => this.switchPlan('basic');
            }
        }

        // Pro Plan Button
        const proBtn = container.querySelector('.stat-card:nth-child(2) button');
        if (proBtn) {
            if (currentPlan === 'pro') {
                proBtn.textContent = 'الباقة الحالية';
                proBtn.disabled = true;
                proBtn.style.background = '#e2e8f0';
                proBtn.style.color = '#475569';
            } else {
                proBtn.textContent = currentPlan === 'enterprise' ? 'تخفيض للباقة' : 'ترقية الآن';
                proBtn.disabled = false;
                proBtn.onclick = () => this.switchPlan('pro');
            }
        }

        // Enterprise Plan Button
        const entBtn = container.querySelector('.stat-card:nth-child(3) button');
        if (entBtn) {
            if (currentPlan === 'enterprise') {
                entBtn.textContent = 'الباقة الحالية';
                entBtn.disabled = true;
                entBtn.style.background = '#e2e8f0';
                entBtn.style.color = '#475569';
            } else {
                entBtn.textContent = 'ترقية الآن';
                entBtn.disabled = false;
                entBtn.onclick = () => this.switchPlan('enterprise');
            }
        }
    },

    switchPlan: function (planId) {
        if (confirm('هل أنت متأكد من تغيير الباقة؟')) {
            this.currentUser.subscriptionPlan = planId;
            this.saveUser();
            this.renderOwnerSubscriptions();
            alert('تم تغيير الباقة بنجاح!');
        }
    },

    saveUser: function () {
        localStorage.setItem('ejari_user', JSON.stringify(this.currentUser));
        const users = JSON.parse(localStorage.getItem('ejari_users')) || [];
        const index = users.findIndex(u => u.id === this.currentUser.id);
        if (index !== -1) {
            users[index] = this.currentUser;
            localStorage.setItem('ejari_users', JSON.stringify(users));
        }
    },

    addPoints: function (amount, description) {
        if (!this.currentUser) return;

        this.currentUser.points = (this.currentUser.points || 0) + amount;

        if (!this.currentUser.pointsHistory) {
            this.currentUser.pointsHistory = [];
        }

        this.currentUser.pointsHistory.unshift({
            amount: amount,
            description: description,
            date: new Date().toISOString(),
            type: 'earn'
        });

        // Update local storage
        localStorage.setItem('ejari_user', JSON.stringify(this.currentUser));

        const users = JSON.parse(localStorage.getItem('ejari_users')) || [];
        const userIndex = users.findIndex(u => u.id === this.currentUser.id);
        if (userIndex !== -1) {
            users[userIndex] = this.currentUser;
            localStorage.setItem('ejari_users', JSON.stringify(users));
        }

        this.renderRewards();
    },

    renderOwnerProperties: function () {
        const container = document.getElementById('owner-properties-list');
        if (!container) return;

        const myProps = this.data.properties.filter(p => {
            const ownerId = p.ownerId || p.owner?.id || p.owner?._id || p.owner;
            return String(ownerId) === String(this.currentUser.id) || String(ownerId) === String(this.currentUser._id);
        });

        if (myProps.length === 0) {
            container.innerHTML = '<div style="padding: 2rem; text-align: center; color: #9ca3af;">لا توجد عقارات مضافة بعد. ابدأ بإضافة عقارك الأول أو استورد البيانات التجريبية.</div>';
            return;
        }

        container.innerHTML = myProps.map(prop => `
            <div class="property-row">
                <img src="${prop.image || prop.images?.[0] || 'images/home1.jpg'}" class="prop-img">
                <div class="prop-info">
                    <h4>${prop.title}</h4>
                    <p><i class="fas fa-map-marker-alt"></i> ${prop.location?.city || prop.location || 'مصر'}</p>
                    ${prop.address || prop.location?.address ? `<p style="font-size: 0.85rem; color: #64748b; margin-top: 0.25rem;"><i class="fas fa-home"></i> ${prop.address || prop.location?.address}</p>` : ''}
                    ${prop.gps ? `<p style="font-size: 0.75rem; color: #10b981; margin-top: 0.25rem;"><i class="fas fa-map-pin"></i> GPS متاح</p>` : ''}
                </div>
                <div class="status-badge ${prop.status === 'active' || prop.status === 'available' ? 'active' : 'rented'}">${prop.status === 'active' || prop.status === 'available' ? 'متاح' : 'مؤجر'}</div>
                <div style="font-weight: bold; margin: 0 1rem;">${Number(prop.price || prop.price_egp_monthly || 0).toLocaleString()} ج.م</div>
                <div class="prop-actions">
                    <button class="btn-icon" onclick="DashboardEngine.openEditPropertyModal(${prop.id})"><i class="fas fa-edit"></i></button>
                    <button class="btn-icon delete" onclick="DashboardEngine.deleteProperty(${prop.id})"><i class="fas fa-trash"></i></button>
                </div>
            </div>
        `).join('');

        const recentContainer = document.getElementById('recent-properties-list');
        if (recentContainer) recentContainer.innerHTML = container.innerHTML;
    },

    openEditPropertyModal: function (id) {
        const prop = this.data.properties.find(p => p.id === id);
        if (!prop) return;

        document.getElementById('edit-p-id').value = prop.id;
        document.getElementById('edit-p-title').value = prop.title;
        document.getElementById('edit-p-price').value = prop.price;
        document.getElementById('edit-p-location').value = prop.location?.city || prop.location || '';
        document.getElementById('edit-p-address').value = prop.address || prop.location?.address || '';
        document.getElementById('edit-p-gps').value = prop.gps || '';
        document.getElementById('edit-p-status').value = prop.status || 'available';

        document.getElementById('editPropertyModal').style.display = 'flex';
    },

    deleteProperty: function (id) {
        if (confirm('هل أنت متأكد من حذف هذا العقار؟ لا يمكن التراجع عن هذا الإجراء.')) {
            this.data.properties = this.data.properties.filter(p => p.id !== id);
            localStorage.setItem('ejari_properties', JSON.stringify(this.data.properties));
            this.renderOwnerProperties();
            this.renderOwnerStats();
            alert('تم حذف العقار بنجاح.');
        }
    },

    renderOwnerTenants: function () {
        const container = document.getElementById('owner-tenants-list');
        if (!container) return;
        const myRentedProps = this.data.properties.filter(p => p.ownerId === this.currentUser.id && p.status === 'rented');

        if (myRentedProps.length > 0) {
            container.innerHTML = myRentedProps.map(prop => `
                <div class="property-row">
                    <div class="user-avatar" style="margin-left: 1rem;"><img src="images/tenant-2.jpg" style="width: 50px; height: 50px; margin: 0;"></div>
                    <div class="prop-info">
                        <h4>أحمد محمد</h4>
                        <p>مستأجر: ${prop.title}</p>
                    </div>
                    <div class="status-badge active">منتظم</div>
                    <button class="btn-sm btn-outline" style="margin-right: 1rem;" onclick="DashboardEngine.openChat('أحمد محمد')"><i class="far fa-comment-dots"></i> مراسلة</button>
                </div>
            `).join('');
        } else {
            container.innerHTML = '<div style="padding: 2rem; text-align: center; color: #94a3b8;">لا يوجد مستأجرين حالياً</div>';
        }
    },

    renderOwnerContracts: function () {
        const container = document.getElementById('owner-contracts-list');
        if (!container) return;
        const myRentedProps = this.data.properties.filter(p => p.ownerId === this.currentUser.id && p.status === 'rented');

        if (myRentedProps.length > 0) {
            container.innerHTML = myRentedProps.map(prop => `
                <div class="property-row">
                    <div style="font-size: 2rem; color: #cbd5e1; margin-left: 1rem;"><i class="fas fa-file-pdf"></i></div>
                    <div class="prop-info">
                        <h4>عقد إيجار - ${prop.title}</h4>
                        <p>تاريخ التوثيق: 2024/11/01</p>
                    </div>
                    <button class="btn-sm btn-primary" onclick="DashboardEngine.downloadContract(${prop.id})"><i class="fas fa-download"></i> تحميل PDF</button>
                </div>
            `).join('');
        } else {
            container.innerHTML = '<div style="padding: 2rem; text-align: center; color: #94a3b8;">لا توجد عقود موثقة حالياً</div>';
        }
    },

    // Global Verification Submit Handler
    submitVerification: function (e) {
        e.preventDefault();
        const type = document.getElementById('v-type').value;
        const number = document.getElementById('v-number').value;
        const frontDoc = document.getElementById('v-doc-front').files[0];
        const backDoc = document.getElementById('v-doc-back').files[0];
        const personalDoc = document.getElementById('v-doc-personal').files[0];
        const ownershipDoc = document.getElementById('v-doc-ownership').files[0];

        if (!frontDoc || !backDoc || !personalDoc || !ownershipDoc) {
            alert('يرجى رفع جميع المستندات المطلوبة (الهوية، الصورة الشخصية، إثبات الملكية)');
            return;
        }

        // Update User Status
        this.currentUser.verificationStatus = 'pending';
        this.currentUser.verificationData = {
            type,
            number,
            date: new Date().toISOString()
        };

        // Save to Storage
        localStorage.setItem('ejari_user', JSON.stringify(this.currentUser));

        const users = JSON.parse(localStorage.getItem('ejari_users')) || [];
        const userIndex = users.findIndex(u => u.id === this.currentUser.id);
        if (userIndex !== -1) {
            users[userIndex] = this.currentUser;
            localStorage.setItem('ejari_users', JSON.stringify(users));
        }

        // Add to Verification Requests (for Admin)
        const requests = JSON.parse(localStorage.getItem('ejari_verification_requests')) || [];
        requests.push({
            id: Date.now(),
            userId: this.currentUser.id,
            userName: this.currentUser.name,
            type,
            number,
            status: 'pending',
            date: new Date().toISOString(),
            // In a real app, we would upload these files. Here we simulate by not storing blobs to avoid quota limits.
            hasDocuments: true
        });
        localStorage.setItem('ejari_verification_requests', JSON.stringify(requests));

        document.getElementById('verificationModal').style.display = 'none';
        alert('تم إرسال طلب التوثيق بنجاح! سيتم مراجعته من قبل الإدارة.');
        location.reload(); // Reload to update UI
    }.bind(this),

    renderOwnerWallet: function () {
        const container = document.getElementById('linked-methods-list');
        if (!container) return;

        const methods = JSON.parse(localStorage.getItem('ejari_payment_methods')) || [];
        const myMethods = methods.filter(m => m.ownerId === this.currentUser.id);

        const addBtn = `<div class="method-card" style="border-style: dashed; justify-content: center; cursor: pointer;" onclick="openLinkMethodModal()">
                            <span style="color: var(--primary); font-weight: 600;">+ ربط حساب بنكي / محفظة</span>
                        </div>`;

        const methodsHTML = myMethods.map(m => {
            let typeName = '';
            switch (m.type) {
                case 'bank':
                    typeName = 'حساب بنكي';
                    break;
                case 'wallet':
                    typeName = 'محفظة إلكترونية';
                    break;
                case 'instapay':
                    typeName = 'InstaPay';
                    break;
                case 'prepaid':
                    typeName = 'كارت مسبق الدفع';
                    break;
                default:
                    typeName = m.type;
            }

            return `
            <div class="method-card">
                <div>
                    <div style="font-weight: bold;">${typeName}</div>
                    <div style="font-size: 0.9rem; color: #64748b;">${m.details}</div>
                </div>
                <i class="fas fa-check-circle" style="color: #10b981;"></i>
            </div>
        `;
        }).join('');

        container.innerHTML = methodsHTML + addBtn;

        // Render Transactions
        const transactionsContainer = document.getElementById('wallet-transactions-list');
        if (transactionsContainer) {
            const transactions = this.currentUser.walletTransactions || [];
            if (transactions.length === 0) {
                transactionsContainer.innerHTML = '<p style="color: #94a3b8; text-align: center;">لا توجد معاملات سابقة</p>';
            } else {
                transactionsContainer.innerHTML = transactions.map(t => `
                    <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.75rem; border-bottom: 1px solid #f1f5f9;">
                        <div style="display: flex; align-items: center; gap: 0.75rem;">
                            <div style="width: 32px; height: 32px; background: ${t.type === 'credit' ? '#dcfce7' : '#fee2e2'}; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: ${t.type === 'credit' ? '#16a34a' : '#ef4444'};">
                                <i class="fas ${t.type === 'credit' ? 'fa-arrow-down' : 'fa-arrow-up'}"></i>
                            </div>
                            <div>
                                <div style="font-weight: 600; font-size: 0.9rem;">${t.description}</div>
                                <div style="font-size: 0.8rem; color: #64748b;">${new Date(t.date).toLocaleDateString('ar-EG')}</div>
                            </div>
                        </div>
                        <div style="font-weight: bold; color: ${t.type === 'credit' ? '#16a34a' : '#ef4444'};">
                            ${t.type === 'credit' ? '+' : '-'}${t.amount.toLocaleString()} ج.م
                        </div>
                    </div>
                `).join('');
            }
        }
    },

    // --- ADMIN LOGIC ---
    initAdminDashboard: function () {
        this.renderAdminStats();
        this.renderAdminTables();
        this.renderAdminVerifications();
    },

    renderAdminStats: function () {
        const usersEl = document.getElementById('total-users');
        const bookingsEl = document.getElementById('total-bookings');

        if (usersEl) usersEl.textContent = this.data.users.length;
        if (bookingsEl) bookingsEl.textContent = this.data.bookings.length;

        const activityList = document.getElementById('recent-activity-list');
        if (activityList) {
            activityList.innerHTML = `
                <tr>
                    <td>تسجيل مستخدم جديد</td>
                    <td>أحمد محمد</td>
                    <td>منذ 5 دقائق</td>
                    <td><span class="status-badge active">مكتمل</span></td>
                </tr>
                <tr>
                    <td>حجز عقار جديد</td>
                    <td>سارة علي</td>
                    <td>منذ 2 ساعة</td>
                    <td><span class="status-badge pending">قيد الانتظار</span></td>
                </tr>
            `;
        }
    },

    renderAdminTables: function () {
        const usersTable = document.getElementById('users-table-body');
        if (usersTable) {
            usersTable.innerHTML = this.data.users.map(user => `
                <tr id="user-row-${user.id}" style="cursor: pointer;" onclick="DashboardEngine.openUserDetailModal(${user.id})">
                    <td>#${user.id}</td>
                    <td>
                        <div style="display: flex; align-items: center; gap: 0.5rem;">
                            <img src="${user.avatar}" style="width: 32px; height: 32px; border-radius: 50%;">
                            <span>${user.name}</span>
                            ${user.verificationStatus === 'verified' ? '<i class="fas fa-check-circle" style="color: #3b82f6;" title="موثق"></i>' : ''}
                        </div>
                    </td>
                    <td><span class="status-badge ${user.role === 'admin' ? 'active' : 'pending'}">${user.role}</span></td>
                    <td><span class="status-badge ${user.status === 'banned' ? 'banned' : 'active'}">${user.status === 'banned' ? 'محظور' : 'نشط'}</span></td>
                    <td>
                        <button class="action-btn" style="background: #e2e8f0;" onclick="event.stopPropagation(); DashboardEngine.openUserDetailModal(${user.id})"><i class="fas fa-eye"></i></button>
                    </td>
                </tr>
            `).join('');
        }

        const propsTable = document.getElementById('properties-table-body');
        if (propsTable) {
            propsTable.innerHTML = this.data.properties.map(prop => `
                <tr id="prop-row-${prop.id}">
                    <td>${prop.title}</td>
                    <td>ID: ${prop.ownerId}</td>
                    <td>${prop.price.toLocaleString()} ج.م</td>
                    <td><span class="status-badge ${prop.status === 'active' ? 'active' : 'pending'}">${prop.status}</span></td>
                    <td>
                        <button class="action-btn btn-danger" onclick="DashboardEngine.deleteProperty(${prop.id})">حذف</button>
                    </td>
                </tr>
            `).join('');
        }
    },

    renderAdminVerifications: function () {
        const container = document.getElementById('verifications-table-body');
        if (!container) return;

        const requests = JSON.parse(localStorage.getItem('ejari_verification_requests')) || [];
        const pendingRequests = requests.filter(r => r.status === 'pending');

        if (pendingRequests.length === 0) {
            container.innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 2rem;">لا توجد طلبات توثيق معلقة</td></tr>';
            return;
        }

        container.innerHTML = pendingRequests.map(req => {
            // Get user info
            const user = this.data.users.find(u => u.id === req.userId);
            const userName = user ? user.name : (req.userName || req.fullname || 'مستخدم');
            const userType = req.userType || (user && user.role) || 'owner';

            // Determine document type
            let docType = '';
            if (req.type) {
                docType = req.type === 'national_id' ? 'بطاقة قومية' : req.type === 'passport' ? 'جواز سفر' : 'سجل تجاري';
            } else if (req.idNumber) {
                docType = 'بطاقة شخصية';
            } else {
                docType = 'مستندات';
            }

            const docNumber = req.number || req.idNumber || 'غير محدد';

            return `
            <tr>
                <td>${userName} <span style="font-size: 0.8rem; color: #64748b;">(${userType === 'tenant' ? 'مستأجر' : 'مالك'})</span></td>
                <td>${docType}</td>
                <td>${docNumber}</td>
                <td>${new Date(req.date).toLocaleDateString('ar-EG')}</td>
                <td>
                    <button class="action-btn" onclick="DashboardEngine.openVerificationReviewModal(${req.id})"><i class="fas fa-eye"></i> مراجعة المستندات</button>
                </td>
                <td>
                    <button class="action-btn btn-success" onclick="DashboardEngine.approveVerification(${req.id})">قبول</button>
                    <button class="action-btn btn-danger" onclick="DashboardEngine.rejectVerification(${req.id})">رفض</button>
                </td>
            </tr>
        `;
        }).join('');
    },

    openUserDetailModal: function (userId) {
        const user = this.data.users.find(u => u.id === userId);
        if (!user) return;

        const modal = document.getElementById('userDetailsModal');
        const content = document.getElementById('user-details-content');

        // Find user activity
        const userProps = this.data.properties.filter(p => p.ownerId === userId);
        const userBookings = this.data.bookings.filter(b => b.userId === userId || (this.data.properties.find(p => p.id === b.propertyId)?.ownerId === userId));

        content.innerHTML = `
            <div style="text-align: center; margin-bottom: 2rem;">
                <img src="${user.avatar}" style="width: 100px; height: 100px; border-radius: 50%; margin-bottom: 1rem;">
                <h3>${user.name} ${user.verificationStatus === 'verified' ? '<i class="fas fa-check-circle" style="color: #3b82f6;"></i>' : ''}</h3>
                <p style="color: #64748b;">${user.role === 'owner' ? 'شريك عقاري' : 'مستأجر'}</p>
                <div style="margin-top: 1rem;">
                    <span class="status-badge ${user.status === 'active' ? 'active' : 'banned'}">${user.status === 'active' ? 'نشط' : 'محظور'}</span>
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 2rem;">
                <div style="background: #f8fafc; padding: 1rem; border-radius: 8px;">
                    <div style="color: #64748b; font-size: 0.9rem;">تاريخ الانضمام</div>
                    <div style="font-weight: 600;">${new Date().toLocaleDateString('ar-EG')}</div>
                </div>
                <div style="background: #f8fafc; padding: 1rem; border-radius: 8px;">
                    <div style="color: #64748b; font-size: 0.9rem;">البريد الإلكتروني</div>
                    <div style="font-weight: 600;">user@example.com</div>
                </div>
            </div>

            <h4 style="margin-bottom: 1rem;">الإحصائيات</h4>
            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-bottom: 2rem;">
                <div style="text-align: center; background: #fff7ed; padding: 1rem; border-radius: 8px;">
                    <div style="font-size: 1.5rem; font-weight: 800; color: #d97706;">${user.points || 0}</div>
                    <div style="font-size: 0.8rem; color: #9a3412;">نقاط المكافآت</div>
                </div>
                <div style="text-align: center; background: #eff6ff; padding: 1rem; border-radius: 8px;">
                    <div style="font-size: 1.5rem; font-weight: 800; color: #1d4ed8;">${userProps.length}</div>
                    <div style="font-size: 0.8rem; color: #1e40af;">عقارات</div>
                </div>
                <div style="text-align: center; background: #f0fdf4; padding: 1rem; border-radius: 8px;">
                    <div style="font-size: 1.5rem; font-weight: 800; color: #15803d;">${userBookings.length}</div>
                    <div style="font-size: 0.8rem; color: #166534;">حجوزات</div>
                </div>
            </div>

            <div style="display: flex; gap: 1rem;">
                <button class="btn-danger" style="flex: 1; padding: 0.75rem; border-radius: 8px; border: none; cursor: pointer;" onclick="DashboardEngine.banUser(${user.id})">
                    ${user.status === 'banned' ? 'فك الحظر' : 'حظر المستخدم'}
                </button>
                <button class="btn-primary" style="flex: 1; justify-content: center;" onclick="alert('تم إرسال رسالة تذكير للمستخدم')">
                    <i class="fas fa-envelope"></i> مراسلة
                </button>
            </div>
        `;

        modal.style.display = 'flex';
    },

    openVerificationReviewModal: function (reqId) {
        const requests = JSON.parse(localStorage.getItem('ejari_verification_requests')) || [];
        const req = requests.find(r => r.id === reqId);
        if (!req) return;

        const modal = document.getElementById('verificationReviewModal');
        const content = document.getElementById('verification-review-content');
        const btnApprove = document.getElementById('btn-approve-req');
        const btnReject = document.getElementById('btn-reject-req');

        // Mock Images for demonstration since we can't store real blobs easily
        const mockIdFront = 'https://via.placeholder.com/400x250/e2e8f0/475569?text=ID+Front+Image';
        const mockIdBack = 'https://via.placeholder.com/400x250/e2e8f0/475569?text=ID+Back+Image';
        const mockPersonal = 'https://via.placeholder.com/200x200/e2e8f0/475569?text=Personal+Photo';
        const mockOwnership = 'https://via.placeholder.com/400x600/e2e8f0/475569?text=Ownership+Document';

        content.innerHTML = `
            <div style="display: grid; grid-template-columns: 1fr 2fr; gap: 2rem;">
                <div>
                    <h4 style="margin-bottom: 1rem;">بيانات الطلب</h4>
                    <div style="margin-bottom: 1rem;">
                        <label style="color: #64748b; font-size: 0.9rem;">مقدم الطلب</label>
                        <div style="font-weight: 600;">${req.userName}</div>
                    </div>
                    <div style="margin-bottom: 1rem;">
                        <label style="color: #64748b; font-size: 0.9rem;">نوع الهوية</label>
                        <div style="font-weight: 600;">${req.type === 'national_id' ? 'بطاقة رقم قومي' : 'جواز سفر'}</div>
                    </div>
                    <div style="margin-bottom: 1rem;">
                        <label style="color: #64748b; font-size: 0.9rem;">رقم الهوية</label>
                        <div style="font-weight: 600;">${req.number}</div>
                    </div>
                    <div style="margin-bottom: 1rem;">
                        <label style="color: #64748b; font-size: 0.9rem;">تاريخ الطلب</label>
                        <div style="font-weight: 600;">${new Date(req.date).toLocaleString('ar-EG')}</div>
                    </div>
                </div>
                
                <div>
                    <h4 style="margin-bottom: 1rem;">المستندات المرفقة</h4>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                        <div>
                            <p style="font-size: 0.8rem; margin-bottom: 0.5rem;">صورة الهوية (أمام)</p>
                            <img src="${mockIdFront}" style="width: 100%; border-radius: 8px; border: 1px solid #cbd5e1;">
                        </div>
                        <div>
                            <p style="font-size: 0.8rem; margin-bottom: 0.5rem;">صورة الهوية (خلف)</p>
                            <img src="${mockIdBack}" style="width: 100%; border-radius: 8px; border: 1px solid #cbd5e1;">
                        </div>
                    </div>
                    <div style="display: grid; grid-template-columns: 1fr 2fr; gap: 1rem;">
                        <div>
                            <p style="font-size: 0.8rem; margin-bottom: 0.5rem;">الصورة الشخصية</p>
                            <img src="${mockPersonal}" style="width: 100%; border-radius: 8px; border: 1px solid #cbd5e1;">
                        </div>
                        <div>
                            <p style="font-size: 0.8rem; margin-bottom: 0.5rem;">مستند الملكية</p>
                            <img src="${mockOwnership}" style="width: 100%; border-radius: 8px; border: 1px solid #cbd5e1;">
                        </div>
                    </div>
                </div>
            </div>
        `;

        btnApprove.onclick = () => {
            this.approveVerification(reqId);
            modal.style.display = 'none';
        };

        btnReject.onclick = () => {
            this.rejectVerification(reqId);
            modal.style.display = 'none';
        };

        modal.style.display = 'flex';
    },

    approveVerification: function (reqId) {
        const requests = JSON.parse(localStorage.getItem('ejari_verification_requests')) || [];
        const reqIndex = requests.findIndex(r => r.id === reqId);

        if (reqIndex === -1) return;

        const req = requests[reqIndex];
        req.status = 'approved';
        requests[reqIndex] = req;
        localStorage.setItem('ejari_verification_requests', JSON.stringify(requests));

        // Update User Status
        const users = this.data.users;
        const userIndex = users.findIndex(u => u.id === req.userId);
        if (userIndex !== -1) {
            users[userIndex].verificationStatus = 'verified';
            localStorage.setItem('ejari_users', JSON.stringify(users));
        }

        this.renderAdminVerifications();
        this.renderAdminTables();
        alert('تم قبول طلب التوثيق بنجاح');
    },

    rejectVerification: function (reqId) {
        const requests = JSON.parse(localStorage.getItem('ejari_verification_requests')) || [];
        const reqIndex = requests.findIndex(r => r.id === reqId);

        if (reqIndex === -1) return;

        const req = requests[reqIndex];
        req.status = 'rejected';
        requests[reqIndex] = req;
        localStorage.setItem('ejari_verification_requests', JSON.stringify(requests));

        // Update User Status
        const users = this.data.users;
        const userIndex = users.findIndex(u => u.id === req.userId);
        if (userIndex !== -1) {
            users[userIndex].verificationStatus = 'rejected';
            localStorage.setItem('ejari_users', JSON.stringify(users));
        }

        this.renderAdminVerifications();
        alert('تم رفض طلب التوثيق');
    },

    banUser: function (id) {
        const user = this.data.users.find(u => u.id === id);
        if (user) {
            user.status = user.status === 'banned' ? 'active' : 'banned';
            localStorage.setItem('ejari_users', JSON.stringify(this.data.users));
            this.renderAdminTables();
            alert(`تم تغيير حالة المستخدم ${user.name} بنجاح`);
        }
    },

    deleteUser: function (id) {
        if (confirm('هل أنت متأكد من حذف هذا المستخدم نهائياً؟')) {
            this.data.users = this.data.users.filter(u => u.id !== id);
            localStorage.setItem('ejari_users', JSON.stringify(this.data.users));
            this.renderAdminTables();
            this.renderAdminStats();
        }
    },

    calculateEndDate: function (start, duration, unit) {
        const date = new Date(start);
        const dur = parseInt(duration);
        if (unit === 'days') date.setDate(date.getDate() + dur);
        if (unit === 'months') date.setMonth(date.getMonth() + dur);
        return date.toLocaleDateString('ar-EG');
    }
};

document.addEventListener('DOMContentLoaded', () => {
    DashboardEngine.init();
});
