/*
*   A JavaScript file to attach event listeners and get the application up and running...
*/

// The night mode button at the top right corner of the application...
const TOGGLE_BUTTON = document.querySelector('.theme-toggle');

// Driver function for toggling themes...
function toggle_theme() {
    document.body.classList.toggle('dark');
    const toggle = document.querySelector('.theme-toggle');
    toggle.textContent = document.body.classList.contains('dark') ? '☀️' : '🌙';
    let night_day_pref = document.body.classList.contains('dark') ? 'night' : 'day';
    localStorage.setItem('night_day_pref', night_day_pref);
}

// Attach the above function as part of a callback; however, also ensure that the user's preference 
// for light and night mode is saved...
document.addEventListener('DOMContentLoaded', function() {
    const NIGHT_DAY_THRESHOLD_HIGH = 18;
    const NIGHT_DAY_THRESHOLD_LOW = 7
    let night_day_pref = localStorage.getItem('night_day_pref');
    if (!night_day_pref) {
        let current_hour = new Date().getHours()
        night_day_pref = current_hour >= NIGHT_DAY_THRESHOLD_HIGH || current_hour <= NIGHT_DAY_THRESHOLD_LOW ? 'night' : 'day'
        localStorage.setItem('night_day_pref', night_day_pref);
    }
    if (night_day_pref === 'night') toggle_theme()
})

// Add the toggle_theme() function as a callback here:
TOGGLE_BUTTON.addEventListener('click', toggle_theme);