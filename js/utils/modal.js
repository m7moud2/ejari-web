// نظام النوافذ المنبثقة
class Modal {
    constructor() {
        this.activeModals = [];
        this.initializeModalSystem();
    }

    initializeModalSystem() {
        // إضافة مستمع للنقر خارج النافذة المنبثقة
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal')) {
                this.closeTopModal();
            }
        });

        // إضافة مستمع لمفتاح ESC
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeTopModal();
            }
        });
    }

    show({ title, content, actions = [], size = 'medium', closable = true }) {
        const modal = document.createElement('div');
        modal.className = `modal ${size}`;
        
        modal.innerHTML = `
            <div class="modal-content">
                <div class="modal-header">
                    <h2>${title}</h2>
                    ${closable ? '<button class="modal-close">&times;</button>' : ''}
                </div>
                <div class="modal-body">${content}</div>
                ${actions.length ? `
                    <div class="modal-footer">
                        ${actions.map(action => `
                            <button class="btn ${action.class || ''}" 
                                    ${action.id ? `id="${action.id}"` : ''}>
                                ${action.icon ? `<i class="fas fa-${action.icon}"></i>` : ''}
                                ${action.text}
                            </button>
                        `).join('')}
                    </div>
                ` : ''}
            </div>
        `;

        document.body.appendChild(modal);
        this.activeModals.push(modal);

        // إضافة مستمعي الأحداث
        if (closable) {
            modal.querySelector('.modal-close').addEventListener('click', () => this.close(modal));
        }

        // إضافة مستمعي الأحداث للأزرار
        actions.forEach(action => {
            if (action.id) {
                const button = modal.querySelector(`#${action.id}`);
                if (button && action.onClick) {
                    button.addEventListener('click', () => {
                        action.onClick();
                        if (action.closeOnClick !== false) {
                            this.close(modal);
                        }
                    });
                }
            }
        });

        // تفعيل النافذة المنبثقة
        setTimeout(() => modal.classList.add('show'), 50);
        return modal;
    }

    close(modal) {
        modal.classList.remove('show');
        setTimeout(() => {
            modal.remove();
            this.activeModals = this.activeModals.filter(m => m !== modal);
        }, 300);
    }

    closeTopModal() {
        if (this.activeModals.length) {
            this.close(this.activeModals[this.activeModals.length - 1]);
        }
    }

    closeAll() {
        [...this.activeModals].forEach(modal => this.close(modal));
    }

    // نوافذ منبثقة جاهزة للاستخدام
    showConfirmation({ title, message, onConfirm, onCancel }) {
        return this.show({
            title,
            content: `<p class="confirmation-message">${message}</p>`,
            actions: [
                {
                    text: 'تأكيد',
                    class: 'btn-primary',
                    onClick: onConfirm
                },
                {
                    text: 'إلغاء',
                    class: 'btn-outline',
                    onClick: onCancel || (() => {})
                }
            ]
        });
    }

    showAlert({ title, message, type = 'info' }) {
        return this.show({
            title,
            content: `
                <div class="alert alert-${type}">
                    <i class="fas fa-${this.getAlertIcon(type)}"></i>
                    <p>${message}</p>
                </div>
            `,
            actions: [{
                text: 'حسناً',
                class: 'btn-primary'
            }]
        });
    }

    showForm({ title, fields, onSubmit }) {
        const formContent = `
            <form class="modal-form" id="modalForm">
                ${fields.map(field => this.createFormField(field)).join('')}
            </form>
        `;

        return this.show({
            title,
            content: formContent,
            actions: [
                {
                    text: 'حفظ',
                    class: 'btn-primary',
                    onClick: () => {
                        const form = document.getElementById('modalForm');
                        const formData = new FormData(form);
                        const data = Object.fromEntries(formData.entries());
                        onSubmit(data);
                    }
                },
                {
                    text: 'إلغاء',
                    class: 'btn-outline'
                }
            ]
        });
    }

    createFormField(field) {
        switch (field.type) {
            case 'text':
            case 'email':
            case 'number':
            case 'tel':
            case 'date':
                return `
                    <div class="form-group">
                        <label for="${field.name}">${field.label}</label>
                        <input type="${field.type}" 
                               id="${field.name}"
                               name="${field.name}"
                               ${field.required ? 'required' : ''}
                               ${field.value ? `value="${field.value}"` : ''}
                               class="form-control"
                               placeholder="${field.placeholder || ''}">
                    </div>
                `;
            case 'select':
                return `
                    <div class="form-group">
                        <label for="${field.name}">${field.label}</label>
                        <select id="${field.name}"
                                name="${field.name}"
                                ${field.required ? 'required' : ''}
                                class="form-control">
                            ${field.options.map(option => `
                                <option value="${option.value}" 
                                        ${option.value === field.value ? 'selected' : ''}>
                                    ${option.label}
                                </option>
                            `).join('')}
                        </select>
                    </div>
                `;
            case 'textarea':
                return `
                    <div class="form-group">
                        <label for="${field.name}">${field.label}</label>
                        <textarea id="${field.name}"
                                  name="${field.name}"
                                  ${field.required ? 'required' : ''}
                                  class="form-control"
                                  rows="${field.rows || 3}"
                                  placeholder="${field.placeholder || ''}">${field.value || ''}</textarea>
                    </div>
                `;
        }
    }

    getAlertIcon(type) {
        const icons = {
            success: 'check-circle',
            error: 'exclamation-circle',
            warning: 'exclamation-triangle',
            info: 'info-circle'
        };
        return icons[type] || icons.info;
    }
}

// تصدير نظام النوافذ المنبثقة
export const modal = new Modal();