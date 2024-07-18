window.addEventListener('message', function(event) {
    const data = event.data
    if (data.action == 'update') {
        updateNotificationNumber(data.data.count);
        const notification = document.querySelector('.notification');
        if (data.data.count >= 1) {
            notification.style.transition = 'opacity 0.5s ease-in-out';
            notification.style.opacity = '1';
        } else {
            notification.style.transition = 'opacity 0.5s ease-in-out';
            notification.style.opacity = '0';
        }
    }

    if (data.action == 'close') {
        updateNotificationNumber(0);
        const notification = document.querySelector('.notification');
        notification.style.transition = 'opacity 0.5s ease-in-out';
        notification.style.opacity = '0';
    }
});

function updateNotificationNumber(number) {
    document.getElementById('notification-number').textContent = number;
}