// Javascript Handler
// https://inappwebview.dev/docs/webview/javascript/communication/#javascript-handlers
window.addEventListener('flutterInAppWebViewPlatformReady', function (event) {
  const args = [{ route: '/settings/your-profile' }];

  const jsButtonHandler = document.getElementById('jsHandlerButton');

  jsButtonHandler.addEventListener('click', () => {
    window.flutter_inappwebview.callHandler(
      'secondScreenNavigationHandler',
      ...args
    );
  });
});

// Web Message Listeners
// https://inappwebview.dev/docs/webview/javascript/communication/#web-message-listeners
const messageHandlerButton = document.getElementById('messageHandlerButton');
messageHandlerButton.addEventListener('click', () => {
  appRouteHandler.postMessage(
    JSON.stringify({
      route: '/settings/your-profile',
    })
  );
});
