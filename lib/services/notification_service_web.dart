import 'dart:js' as js;

void initWebNotifications() {
  try {
    js.context.callMethod('eval', [
      """
      window.showWebNotification = function(title, body) {
        if (Notification.permission === 'granted') {
          try {
            new Notification(title, { body: body });
          } catch (e) {
            console.error('Notification creation failed:', e);
          }
        } else if (Notification.permission !== 'denied') {
          Notification.requestPermission().then(function(permission) {
            if (permission === 'granted') {
              new Notification(title, { body: body });
            }
          });
        }
      };
      if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
        Notification.requestPermission();
      }
      """
    ]);
  } catch (e) {
    print('Web Notification init error: $e');
  }
}

void showWebNotification(String title, String body) {
  try {
    js.context.callMethod('showWebNotification', [title, body]);
  } catch (e) {
    print('Web Notification error: $e');
  }
}
