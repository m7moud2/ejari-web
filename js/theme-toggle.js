// Ejari Elite - Theme Toggle Logic
document.addEventListener('DOMContentLoaded', () => {
    const theme = localStorage.getItem('ejari-theme') || 'light';
    document.body.setAttribute('data-theme', theme);
    updateToggleIcons(theme);

    // Listen for toggle clicks (if elements exist)
    const toggleBtn = document.getElementById('themeToggle');
    if (toggleBtn) {
        toggleBtn.addEventListener('click', () => {
            const currentTheme = document.body.getAttribute('data-theme');
            const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            
            document.body.setAttribute('data-theme', newTheme);
            localStorage.setItem('ejari-theme', newTheme);
            updateToggleIcons(newTheme);
        });
    }
});

function updateToggleIcons(theme) {
    const sunIcon = document.querySelector('#themeToggle .fa-sun');
    const moonIcon = document.querySelector('#themeToggle .fa-moon');
    
    if (sunIcon && moonIcon) {
        if (theme === 'dark') {
            sunIcon.style.display = 'block';
            moonIcon.style.display = 'none';
        } else {
            sunIcon.style.display = 'none';
            moonIcon.style.display = 'block';
        }
    }
}
