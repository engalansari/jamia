importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBG2AvkA9uORu2U1KSvle5698BLDmCdAVI',
  appId: '1:1025246578239:web:a6edc34d9e4f869278da8a',
  messagingSenderId: '1025246578239',
  projectId: 'jamiaq8',
  authDomain: 'jamiaq8.firebaseapp.com',
  storageBucket: 'jamiaq8.firebasestorage.app',
  measurementId: 'G-DX2P1W9QN2',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const notification = message.notification || {};
  const data = message.data || {};
  const title = notification.title || data.title || 'جمعية';
  const options = {
    body: notification.body || data.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: {
      url: data.url || '/',
    },
  };

  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url || '/';

  event.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clients) => {
        for (const client of clients) {
          if ('focus' in client) {
            client.focus();
            if ('navigate' in client) {
              return client.navigate(url);
            }
            return undefined;
          }
        }
        if (self.clients.openWindow) {
          return self.clients.openWindow(url);
        }
        return undefined;
      }),
  );
});
