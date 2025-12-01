/**
 * Car Rental Verification Flow
 * Handles document upload, e-contract signing, and AI camera verification
 */

const CarFlowManager = {
    currentStep: 1,
    bookingData: null,

    init: function () {
        this.createModalHTML();
        this.setupEventListeners();
    },

    createModalHTML: function () {
        const modalHTML = `
        <div id="carVerificationModal" class="verification-modal" style="display: none;">
            <div class="verification-content">
                <div class="verification-header">
                    <h3>إجراءات تأجير السيارة</h3>
                    <button class="close-btn" onclick="CarFlowManager.close()"><i class="fas fa-times"></i></button>
                </div>
                
                <div class="progress-bar">
                    <div class="step active" data-step="1">1. المستندات</div>
                    <div class="step" data-step="2">2. العقد</div>
                    <div class="step" data-step="3">3. التحقق</div>
                </div>

                <!-- Step 1: Documents -->
                <div class="flow-step active" id="step1">
                    <h4>رفع المستندات المطلوبة</h4>
                    <p class="step-desc">يرجى رفع صور واضحة للمستندات التالية للتحقق من هويتك.</p>
                    
                    <div class="upload-grid">
                        <div class="upload-box">
                            <i class="fas fa-id-card"></i>
                            <span>بطاقة الرقم القومي / جواز السفر</span>
                            <input type="file" accept="image/*">
                        </div>
                        <div class="upload-box">
                            <i class="fas fa-car"></i>
                            <span>رخصة القيادة (سارية)</span>
                            <input type="file" accept="image/*">
                        </div>
                        <div class="upload-box">
                            <i class="fas fa-money-bill-wave"></i>
                            <span>إثبات دخل / كشف حساب</span>
                            <input type="file" accept="image/*">
                        </div>
                        <div class="upload-box">
                            <i class="fas fa-users"></i>
                            <span>كارنيه النادي (اختياري)</span>
                            <input type="file" accept="image/*">
                        </div>
                    </div>
                    <button class="btn-next" onclick="CarFlowManager.nextStep()">التالي: توقيع العقد</button>
                </div>

                <!-- Step 2: E-Contract -->
                <div class="flow-step" id="step2">
                    <h4>العقد الإلكتروني الموحد</h4>
                    <div class="contract-viewer">
                        <p><strong>بند 1:</strong> يقر المستأجر باستلام السيارة بحالة جيدة...</p>
                        <p><strong>بند 2:</strong> يلتزم المستأجر بدفع قيمة الإيجار المتفق عليها...</p>
                        <p><strong>بند 3:</strong> يتحمل المستأجر المسؤولية الكاملة عن أي مخالفات مرورية...</p>
                        <p><strong>بند 4:</strong> يجب إعادة السيارة بنفس كمية الوقود...</p>
                        <br><br>
                        <p>أقر أنا الموقع أدناه بصحة البيانات والموافقة على الشروط.</p>
                    </div>
                    <div class="signature-area">
                        <label>التوقيع الإلكتروني:</label>
                        <div class="signature-pad" id="signaturePad">
                            <!-- Canvas placeholder -->
                            <canvas id="sigCanvas" width="400" height="150" style="border: 1px dashed #ccc; background: #fff;"></canvas>
                            <button class="clear-sig" onclick="CarFlowManager.clearSignature()">مسح</button>
                        </div>
                        <label class="checkbox-label">
                            <input type="checkbox" id="contractConsent"> أوافق على الشروط والأحكام
                        </label>
                    </div>
                    <button class="btn-next" onclick="CarFlowManager.nextStep()">التالي: التحقق بالذكاء الاصطناعي</button>
                </div>

                <!-- Step 3: AI Verification -->
                <div class="flow-step" id="step3">
                    <h4>التحقق من الهوية (AI)</h4>
                    <p class="step-desc">لإتمام العملية، يرجى التقاط صورة سيلفي للتأكد من مطابقة الهوية.</p>
                    
                    <div class="camera-container">
                        <video id="cameraFeed" autoplay playsinline></video>
                        <canvas id="photoCanvas" style="display:none;"></canvas>
                        <div class="camera-overlay">
                            <div class="face-guide"></div>
                        </div>
                    </div>
                    
                    <div class="camera-controls">
                        <button class="btn-camera" onclick="CarFlowManager.startCamera()"><i class="fas fa-camera"></i> فتح الكاميرا</button>
                        <button class="btn-capture" onclick="CarFlowManager.capturePhoto()" disabled><i class="fas fa-circle"></i> التقاط</button>
                    </div>

                    <div id="verificationStatus" style="margin-top: 1rem; text-align: center; font-weight: bold;"></div>

                    <button class="btn-next" onclick="CarFlowManager.finish()" disabled id="finishBtn">إتمام والذهاب للدفع</button>
                </div>
            </div>
        </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHTML);
        this.addStyles();
    },

    addStyles: function () {
        const style = document.createElement('style');
        style.textContent = `
            .verification-modal {
                position: fixed; top: 0; left: 0; width: 100%; height: 100%;
                background: rgba(0,0,0,0.8); z-index: 20000;
                display: flex; align-items: center; justify-content: center;
            }
            .verification-content {
                background: white; width: 90%; max-width: 600px;
                border-radius: 15px; padding: 2rem; max-height: 90vh; overflow-y: auto;
            }
            .verification-header {
                display: flex; justify-content: space-between; align-items: center;
                margin-bottom: 2rem; border-bottom: 1px solid #eee; padding-bottom: 1rem;
            }
            .progress-bar {
                display: flex; justify-content: space-between; margin-bottom: 2rem;
                background: #f3f4f6; padding: 0.5rem; border-radius: 30px;
            }
            .step {
                padding: 0.5rem 1rem; border-radius: 20px; color: #9ca3af; font-size: 0.9rem;
            }
            .step.active {
                background: #667eea; color: white; font-weight: bold;
            }
            .flow-step { display: none; animation: fadeIn 0.5s; }
            .flow-step.active { display: block; }
            
            .upload-grid {
                display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 2rem;
            }
            .upload-box {
                border: 2px dashed #ccc; padding: 1.5rem; text-align: center;
                border-radius: 10px; cursor: pointer; transition: all 0.3s;
                display: flex; flex-direction: column; align-items: center; gap: 0.5rem;
            }
            .upload-box:hover { border-color: #667eea; background: #f0f4ff; }
            .upload-box i { font-size: 2rem; color: #667eea; }
            .upload-box input { display: none; }

            .contract-viewer {
                background: #f9fafb; padding: 1rem; border: 1px solid #e5e7eb;
                height: 150px; overflow-y: auto; margin-bottom: 1rem; font-size: 0.9rem;
            }
            .btn-next {
                width: 100%; background: #667eea; color: white; padding: 1rem;
                border: none; border-radius: 10px; font-weight: bold; cursor: pointer;
                margin-top: 1rem;
            }
            .btn-next:disabled { background: #ccc; cursor: not-allowed; }

            .camera-container {
                width: 100%; height: 300px; background: #000; border-radius: 10px;
                position: relative; overflow: hidden; margin-bottom: 1rem;
            }
            #cameraFeed { width: 100%; height: 100%; object-fit: cover; }
            .camera-overlay {
                position: absolute; top: 0; left: 0; width: 100%; height: 100%;
                display: flex; align-items: center; justify-content: center;
                pointer-events: none;
            }
            .face-guide {
                width: 200px; height: 250px; border: 2px solid rgba(255,255,255,0.5);
                border-radius: 50%; box-shadow: 0 0 0 9999px rgba(0,0,0,0.5);
            }
            .camera-controls { display: flex; justify-content: center; gap: 1rem; }
            .btn-camera, .btn-capture {
                padding: 0.5rem 1rem; border-radius: 20px; border: none; cursor: pointer;
            }
            .btn-camera { background: #e5e7eb; }
            .btn-capture { background: #ef4444; color: white; }
            
            @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        `;
        document.head.appendChild(style);
    },

    setupEventListeners: function () {
        // Upload boxes click trigger
        document.addEventListener('click', (e) => {
            if (e.target.closest('.upload-box')) {
                const input = e.target.closest('.upload-box').querySelector('input');
                if (input) input.click();
            }
        });

        // Canvas drawing logic (Simple)
        const canvas = document.getElementById('sigCanvas');
        if (canvas) {
            const ctx = canvas.getContext('2d');
            let isDrawing = false;

            canvas.addEventListener('mousedown', (e) => { isDrawing = true; ctx.beginPath(); ctx.moveTo(e.offsetX, e.offsetY); });
            canvas.addEventListener('mousemove', (e) => { if (isDrawing) { ctx.lineTo(e.offsetX, e.offsetY); ctx.stroke(); } });
            canvas.addEventListener('mouseup', () => { isDrawing = false; });
        }
    },

    open: function () {
        document.getElementById('carVerificationModal').style.display = 'flex';
        this.currentStep = 1;
        this.updateSteps();
    },

    close: function () {
        document.getElementById('carVerificationModal').style.display = 'none';
        this.stopCamera();
    },

    nextStep: function () {
        if (this.currentStep === 1) {
            // Validate uploads (Mock)
            // In real app, check if files are selected
        }
        if (this.currentStep === 2) {
            if (!document.getElementById('contractConsent').checked) {
                alert('يجب الموافقة على الشروط والأحكام');
                return;
            }
        }

        this.currentStep++;
        this.updateSteps();
    },

    updateSteps: function () {
        document.querySelectorAll('.flow-step').forEach(el => el.classList.remove('active'));
        document.getElementById(`step${this.currentStep}`).classList.add('active');

        document.querySelectorAll('.step').forEach(el => {
            el.classList.remove('active');
            if (parseInt(el.dataset.step) === this.currentStep) el.classList.add('active');
        });
    },

    clearSignature: function () {
        const canvas = document.getElementById('sigCanvas');
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
    },

    // Camera Logic
    stream: null,
    startCamera: async function () {
        try {
            this.stream = await navigator.mediaDevices.getUserMedia({ video: true });
            const video = document.getElementById('cameraFeed');
            video.srcObject = this.stream;
            document.querySelector('.btn-capture').disabled = false;
        } catch (err) {
            alert('لا يمكن الوصول للكاميرا. يرجى التأكد من الصلاحيات.');
            console.error(err);
        }
    },

    stopCamera: function () {
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
        }
    },

    capturePhoto: function () {
        const video = document.getElementById('cameraFeed');
        const canvas = document.getElementById('photoCanvas');
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        canvas.getContext('2d').drawImage(video, 0, 0);

        // Simulate AI Verification
        this.stopCamera();
        document.getElementById('verificationStatus').innerHTML = '<i class="fas fa-spinner fa-spin"></i> جاري التحقق من الهوية...';

        setTimeout(() => {
            document.getElementById('verificationStatus').innerHTML = '<span style="color: green;"><i class="fas fa-check-circle"></i> تم التحقق بنجاح!</span>';
            document.getElementById('finishBtn').disabled = false;
        }, 2000);
    },

    finish: function () {
        this.close();
        window.location.href = 'checkout.html';
    }
};

// Global Trigger
function startCarVerificationFlow() {
    CarFlowManager.init(); // Ensure HTML is injected
    CarFlowManager.open();
}
