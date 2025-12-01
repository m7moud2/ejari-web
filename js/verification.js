/**
 * Unified Verification Flow Manager
 * Handles ID Upload, Selfie Verification, and E-Signature
 */

const VerificationManager = {
    modal: null,
    modalContent: null,
    stream: null,
    type: null, // 'property' or 'car'

    init: function () {
        // Create Modal HTML if not exists
        if (!document.getElementById('verificationModal')) {
            const modalHTML = `
                <div id="verificationModal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); z-index: 3000; align-items: center; justify-content: center;">
                    <div id="verificationContent" style="background: white; width: 90%; max-width: 500px; border-radius: 20px; padding: 2rem; text-align: center; position: relative;">
                        <button onclick="VerificationManager.close()" style="position: absolute; top: 1rem; right: 1rem; background: none; border: none; font-size: 1.5rem; cursor: pointer;">&times;</button>
                        <div id="v-step-content"></div>
                    </div>
                </div>
                <style>
                    .step-icon { width: 80px; height: 80px; background: #eff6ff; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 2rem; color: #3b82f6; margin: 0 auto 1.5rem; }
                    .btn-verify { background: #3b82f6; color: white; border: none; padding: 1rem 2rem; border-radius: 12px; font-size: 1.1rem; font-weight: bold; cursor: pointer; width: 100%; margin-top: 1.5rem; }
                    .btn-verify:hover { background: #2563eb; }
                    .upload-box { border: 2px dashed #cbd5e1; padding: 2rem; border-radius: 12px; margin: 1rem 0; cursor: pointer; }
                    .upload-box:hover { border-color: #3b82f6; background: #f8fafc; }
                </style>
            `;
            document.body.insertAdjacentHTML('beforeend', modalHTML);
        }

        this.modal = document.getElementById('verificationModal');
        this.modalContent = document.getElementById('v-step-content');
    },

    start: function (type) {
        this.init();
        this.type = type;
        this.modal.style.display = 'flex';
        this.renderUploadStep();
    },

    close: function () {
        this.modal.style.display = 'none';
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
        }
    },

    // Step 1: Document Upload
    renderUploadStep: function () {
        this.modalContent.innerHTML = `
            <div class="step-header">
                <div class="step-icon"><i class="fas fa-id-card"></i></div>
                <h2>التحقق من الهوية</h2>
                <p style="color: #64748b;">لضمان أمان المنصة، يرجى رفع صورة الهوية الوطنية أو جواز السفر.</p>
            </div>
            
            <div class="upload-box" onclick="document.getElementById('id-upload').click()">
                <i class="fas fa-cloud-upload-alt" style="font-size: 2rem; color: #94a3b8; margin-bottom: 0.5rem;"></i>
                <p>اضغط لرفع صورة الهوية</p>
                <input type="file" id="id-upload" hidden accept="image/*" onchange="VerificationManager.handleFileSelect(this)">
                <p id="file-name" style="font-size: 0.85rem; color: #3b82f6; margin-top: 0.5rem;"></p>
            </div>

            <button class="btn-verify" onclick="VerificationManager.renderCameraStep()">المتابعة</button>
        `;
    },

    handleFileSelect: function (input) {
        if (input.files[0]) {
            document.getElementById('file-name').textContent = 'تم اختيار: ' + input.files[0].name;
        }
    },

    // Step 2: AI Camera Verification
    renderCameraStep: function () {
        this.modalContent.innerHTML = `
            <div class="step-header">
                <div class="step-icon"><i class="fas fa-camera"></i></div>
                <h2>التحقق بالذكاء الاصطناعي</h2>
                <p style="color: #64748b;">يرجى النظر للكاميرا لالتقاط صورة سيلفي لمطابقتها مع الهوية.</p>
            </div>
            
            <div style="background: #000; border-radius: 12px; overflow: hidden; margin: 1rem 0; height: 300px; position: relative;">
                <video id="camera-feed" autoplay playsinline style="width: 100%; height: 100%; object-fit: cover;"></video>
                <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); border: 2px solid rgba(255,255,255,0.5); width: 200px; height: 250px; border-radius: 50%;"></div>
            </div>

            <button class="btn-verify" onclick="VerificationManager.captureAndVerify()">التقاط وتحقق</button>
        `;

        this.startCameraStream();
    },

    startCameraStream: async function () {
        try {
            this.stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' } });
            document.getElementById('camera-feed').srcObject = this.stream;
        } catch (err) {
            alert('لا يمكن الوصول للكاميرا. يرجى السماح بالوصول.');
        }
    },

    captureAndVerify: function () {
        const btn = document.querySelector('.btn-verify');
        btn.textContent = 'جاري التحليل...';
        btn.disabled = true;

        // Simulate AI Processing
        setTimeout(() => {
            if (this.stream) {
                this.stream.getTracks().forEach(track => track.stop());
            }
            this.renderSignatureStep();
        }, 2000);
    },

    // Step 3: E-Signature
    renderSignatureStep: function () {
        this.modalContent.innerHTML = `
            <div class="step-header">
                <div class="step-icon"><i class="fas fa-file-signature"></i></div>
                <h2>توقيع العقد الإلكتروني</h2>
                <p style="color: #64748b; margin-bottom: 1rem;">يرجى التوقيع أدناه للموافقة على الشروط.</p>
            </div>
            
            <div style="background: #f8fafc; padding: 1rem; border-radius: 8px; margin-bottom: 1rem; height: 100px; overflow-y: auto; font-size: 0.8rem; border: 1px solid #e2e8f0; text-align: right;">
                <strong>بنود العقد:</strong><br>
                1. يلتزم الطرف الثاني بدفع القيمة المتفق عليها.<br>
                2. الحفاظ على العين المؤجرة.<br>
                3. هذا العقد ملزم للطرفين قانونياً.<br>
            </div>

            <div style="border: 2px dashed #cbd5e1; border-radius: 12px; background: white; touch-action: none; position: relative;">
                <canvas id="signature-pad" width="400" height="200" style="width: 100%; height: 200px; cursor: crosshair;"></canvas>
                <div style="position: absolute; bottom: 5px; left: 10px; font-size: 0.7rem; color: #94a3b8;">منطقة التوقيع</div>
            </div>
            
            <div style="text-align: left; margin-top: 0.5rem;">
                <button onclick="VerificationManager.clearSignature()" style="background: none; border: none; color: #ef4444; cursor: pointer; font-size: 0.9rem;">مسح التوقيع</button>
            </div>

            <button class="btn-verify" onclick="VerificationManager.submitSignature()">تأكيد التوقيع والدفع</button>
        `;

        setTimeout(() => this.initCanvas(), 100);
    },

    initCanvas: function () {
        const canvas = document.getElementById('signature-pad');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        ctx.strokeStyle = "#000";
        ctx.lineWidth = 2;
        let isDrawing = false;

        const getPos = (e) => {
            const rect = canvas.getBoundingClientRect();
            const clientX = e.touches ? e.touches[0].clientX : e.clientX;
            const clientY = e.touches ? e.touches[0].clientY : e.clientY;
            return { x: clientX - rect.left, y: clientY - rect.top };
        };

        const startDraw = (e) => {
            isDrawing = true;
            const pos = getPos(e);
            ctx.beginPath();
            ctx.moveTo(pos.x, pos.y);
        };

        const draw = (e) => {
            if (!isDrawing) return;
            e.preventDefault();
            const pos = getPos(e);
            ctx.lineTo(pos.x, pos.y);
            ctx.stroke();
        };

        const stopDraw = () => { isDrawing = false; };

        canvas.addEventListener('mousedown', startDraw);
        canvas.addEventListener('mousemove', draw);
        canvas.addEventListener('mouseup', stopDraw);

        canvas.addEventListener('touchstart', startDraw);
        canvas.addEventListener('touchmove', draw);
        canvas.addEventListener('touchend', stopDraw);
    },

    clearSignature: function () {
        const canvas = document.getElementById('signature-pad');
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
    },

    submitSignature: function () {
        const canvas = document.getElementById('signature-pad');
        const blank = document.createElement('canvas');
        blank.width = canvas.width;
        blank.height = canvas.height;

        if (canvas.toDataURL() === blank.toDataURL()) {
            alert('يرجى التوقيع على العقد للمتابعة.');
            return;
        }

        // Save signature to booking
        const booking = JSON.parse(localStorage.getItem('currentBooking'));
        if (booking) {
            booking.signature = canvas.toDataURL();
            booking.contractSigned = true;
            localStorage.setItem('currentBooking', JSON.stringify(booking));
        }

        window.location.href = 'payment.html';
    }
};
