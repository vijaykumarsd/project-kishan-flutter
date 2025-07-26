// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyD74SYxy8dG8dqR0KuRAC_CNl3v10W_7_0",
  authDomain: "project-kisan-app-467108.firebaseapp.com",
  projectId: "project-kisan-app-467108",
  storageBucket: "project-kisan-app-467108.firebasestorage.app",
  messagingSenderId: "261844974018",
  appId: "1:261844974018:web:11a73ee6aafe0bc1cdfe5b"
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