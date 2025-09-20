// Firebase Messaging Service Worker Template
// Replace API key and configuration with your actual Firebase project details

importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'YOUR_FIREBASE_WEB_API_KEY',
  authDomain: 'your-firebase-project-id.firebaseapp.com',
  projectId: 'your-firebase-project-id',
  storageBucket: 'your-firebase-project-id.firebasestorage.app',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  appId: 'YOUR_WEB_APP_ID'
});

const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/flutter_assets/assets/icons/app_icon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});