// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyBqvaarXGhE0eRhlzLrgQQmXNeAUkDf9oA",
  authDomain: "project-kisan-app.firebaseapp.com",
  projectId: "project-kisan-app",
  storageBucket: "project-kisan-app.firebasestorage.app",
  messagingSenderId: "247743444691",
  appId: "1:247743444691:web:d7cd9200b16b5c0fcd0626"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // Customize notification here
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/firebase-logo.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});