// Initialize Charts
document.addEventListener('DOMContentLoaded', function() {
    initializePaymentsChart();
    setupEventListeners();
    initializeNotifications();
});

function initializePaymentsChart() {
    const ctx = document.getElementById('paymentsChart').getContext('2d');
    new Chart(ctx, {
        type: 'line',
        data: {
            labels: ['يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو'],
            datasets: [{
                label: 'المدفوعات',
                data: [12000, 19000, 15000, 15500, 14000, 18000],
                borderColor: '#4A90E2',
                backgroundColor: 'rgba(74, 144, 226, 0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        borderDash: [2, 4]
                    }
                },
                x: {
                    grid: {
                        display: false
                    }
                }
            }
        }
    });
}

function setupEventListeners() {
    // Sidebar Toggle
    const menuToggle = document.querySelector('.menu-toggle');
    const sidebar = document.querySelector('.sidebar');
    
    menuToggle?.addEventListener('click', () => {
        sidebar.classList.toggle('collapsed');
    });

    // Notifications
    document.querySelectorAll('.btn-icon').forEach(btn => {
        btn.addEventListener('click', function(e) {
            const dropdown = this.nextElementSibling;
            if (dropdown?.classList.contains('dropdown-content')) {
                dropdown.classList.toggle('show');
                e.stopPropagation();
            }
        });
    });

    // Close dropdowns when clicking outside
    document.addEventListener('click', function(e) {
        document.querySelectorAll('.dropdown-content.show').forEach(dropdown => {
            if (!dropdown.contains(e.target)) {
                dropdown.classList.remove('show');
            }
        });
    });
}

function initializeNotifications() {
    const notifications = {
        showNotification: function(message, type = 'info') {
            const container = document.getElementById('notifications-container');
            const notification = document.createElement('div');
            notification.className = `notification ${type}`;
            notification.innerHTML = `
                <i class="fas fa-info-circle"></i>
                <span>${message}</span>
                <button onclick="this.parentElement.remove()">
                    <i class="fas fa-times"></i>
                </button>
            `;
            container.appendChild(notification);
            setTimeout(() => notification.remove(), 5000);
        }
    };

    window.notifications = notifications;
}

// Property Slider Functions
let currentSlide = 0;
function slideProperties(direction) {
    const track = document.querySelector('.properties-track');
    const slides = document.querySelectorAll('.property-card');
    const slideWidth = slides[0].offsetWidth + 20; // Including margin

    if (direction === 'next' && currentSlide < slides.length - 1) {
        currentSlide++;
    } else if (direction === 'prev' && currentSlide > 0) {
        currentSlide--;
    }

    track.style.transform = `translateX(${currentSlide * slideWidth}px)`;
}

// Favorite Toggle Function
function toggleFavorite(propertyId) {
    const btn = event.currentTarget;
    const icon = btn.querySelector('i');
    
    if (icon.classList.contains('far')) {
        icon.classList.replace('far', 'fas');
        icon.style.color = '#E74C3C';
        notifications.showNotification('تمت إضافة العقار إلى المفضلة', 'success');
    } else {
        icon.classList.replace('fas', 'far');
        icon.style.color = '';
        notifications.showNotification('تم إزالة العقار من المفضلة', 'info');
    }
}

// Booking Modal Functions
function showBookingModal(propertyId) {
    const modal = document.getElementById('modal-container');
    // Implement booking modal logic
}

function showPropertyDetails(propertyId) {
    // Implement property details view logic
}

function logout() {
    // Implement logout logic
    notifications.showNotification('جاري تسجيل الخروج...', 'info');
    setTimeout(() => {
        window.location.href = 'login.html';
    }, 1500);
}