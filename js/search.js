// Enhanced search functionality
class SearchManager {
    constructor() {
        this.searchInput = document.querySelector('.search-box input');
        this.searchButton = document.querySelector('.search-box .btn-primary');
        this.filterButton = document.querySelector('.search-box .btn-outline');
        this.init();
    }

    init() {
        if (this.searchButton) {
            this.searchButton.addEventListener('click', () => this.performSearch());
        }

        if (this.searchInput) {
            this.searchInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.performSearch();
                }
            });
        }

        if (this.filterButton) {
            this.filterButton.addEventListener('click', () => this.showFilters());
        }
    }

    performSearch() {
        const query = this.searchInput?.value.trim();
        if (query) {
            // Store search query
            sessionStorage.setItem('searchQuery', query);
            // Redirect to properties page
            window.location.href = 'properties.html?q=' + encodeURIComponent(query);
        } else {
            this.showNotification('الرجاء إدخال كلمة بحث', 'warning');
        }
    }

    showFilters() {
        // Create filter modal
        const filterModal = document.createElement('div');
        filterModal.className = 'filter-modal';
        filterModal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10001;
        `;

        filterModal.innerHTML = `
            <div style="background: white; border-radius: 12px; padding: 2rem; max-width: 500px; width: 90%;">
                <h3 style="margin: 0 0 1.5rem 0; color: #2c3e50;">فلترة متقدمة</h3>
                
                <div style="margin-bottom: 1rem;">
                    <label style="display: block; margin-bottom: 0.5rem; color: #6b7280;">نوع العقار</label>
                    <select id="propertyType" style="width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px;">
                        <option value="">الكل</option>
                        <option value="apartment">شقة</option>
                        <option value="villa">فيلا</option>
                        <option value="office">مكتب</option>
                        <option value="shop">محل</option>
                    </select>
                </div>

                <div style="margin-bottom: 1rem;">
                    <label style="display: block; margin-bottom: 0.5rem; color: #6b7280;">السعر (ج.م/شهر)</label>
                    <div style="display: flex; gap: 1rem;">
                        <input type="number" id="minPrice" placeholder="من" style="flex: 1; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px;">
                        <input type="number" id="maxPrice" placeholder="إلى" style="flex: 1; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px;">
                    </div>
                </div>

                <div style="margin-bottom: 1rem;">
                    <label style="display: block; margin-bottom: 0.5rem; color: #6b7280;">عدد الغرف</label>
                    <select id="bedrooms" style="width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px;">
                        <option value="">الكل</option>
                        <option value="1">1 غرفة</option>
                        <option value="2">2 غرفة</option>
                        <option value="3">3 غرف</option>
                        <option value="4">4 غرف</option>
                        <option value="5">5+ غرف</option>
                    </select>
                </div>

                <div style="margin-bottom: 1.5rem;">
                    <label style="display: block; margin-bottom: 0.5rem; color: #6b7280;">المنطقة</label>
                    <select id="area" style="width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px;">
                        <option value="">الكل</option>
                        <option value="maadi">المعادي</option>
                        <option value="nasr-city">مدينة نصر</option>
                        <option value="downtown">وسط البلد</option>
                        <option value="fifth-settlement">التجمع الخامس</option>
                        <option value="6-october">6 أكتوبر</option>
                    </select>
                </div>

                <div style="display: flex; gap: 1rem;">
                    <button onclick="applyFilters()" style="flex: 1; padding: 0.75rem; background: #667eea; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: 500;">
                        تطبيق
                    </button>
                    <button onclick="closeFilterModal()" style="flex: 1; padding: 0.75rem; background: white; color: #374151; border: 1px solid #d1d5db; border-radius: 6px; cursor: pointer; font-weight: 500;">
                        إلغاء
                    </button>
                </div>
            </div>
        `;

        document.body.appendChild(filterModal);

        // Add global functions
        window.applyFilters = () => {
            const filters = {
                type: document.getElementById('propertyType').value,
                minPrice: document.getElementById('minPrice').value,
                maxPrice: document.getElementById('maxPrice').value,
                bedrooms: document.getElementById('bedrooms').value,
                area: document.getElementById('area').value
            };

            // Store filters
            sessionStorage.setItem('filters', JSON.stringify(filters));

            // Redirect to properties page
            window.location.href = 'properties.html';
        };

        window.closeFilterModal = () => {
            filterModal.remove();
        };

        // Close on background click
        filterModal.addEventListener('click', (e) => {
            if (e.target === filterModal) {
                filterModal.remove();
            }
        });
    }

    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${type === 'warning' ? '#f39c12' : '#667eea'};
            color: white;
            padding: 1rem 1.5rem;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 10002;
            animation: slideIn 0.3s ease;
        `;
        notification.textContent = message;
        document.body.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }
}

// Initialize search manager
document.addEventListener('DOMContentLoaded', () => {
    new SearchManager();
});
