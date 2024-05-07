import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:in_appwebview_javscript_channel/screens/second_screen.dart';
import 'package:universal_io/io.dart' as uio;

class AppWebBrowser extends StatefulWidget {
  final String url;
  final String? title;
  final bool clearCache;

  const AppWebBrowser({
    super.key,
    required this.url,
    this.title,
    this.clearCache = true,
  });

  @override
  _AppWebBrowserState createState() => _AppWebBrowserState();
}

class _AppWebBrowserState extends State<AppWebBrowser> {
  late PullToRefreshController _pullToRefreshController;
  late InAppWebViewSettings settings;

  final GlobalKey _webViewKey = GlobalKey(debugLabel: 'webView');

  InAppWebViewController? _webViewController;

  final Map<String, String> _headers = {};

  @override
  void initState() {
    super.initState();
    settings = InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      useShouldInterceptAjaxRequest: false,
      clearCache: widget.clearCache,
      javaScriptCanOpenWindowsAutomatically: true,
      useHybridComposition: true,
      supportMultipleWindows: true,
      allowsInlineMediaPlayback: true,
    );
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (uio.Platform.isAndroid) {
          _webViewController?.reload();
        } else if (uio.Platform.isIOS) {
          _webViewController?.loadUrl(
            urlRequest: URLRequest(
              url: await _webViewController?.getUrl() ?? WebUri(widget.url),
              headers: _headers,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              key: _webViewKey,
              gestureRecognizers: {}..add(
                  Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer(),
                  ),
                ),
              initialSettings: settings,
              pullToRefreshController: _pullToRefreshController,
              onWebViewCreated: (controller) async {
                _webViewController = controller;
                if (_webViewController == null) return;

                bool isSupported = await WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER);
                if (defaultTargetPlatform != TargetPlatform.android || isSupported) {
                  await _webViewController!.addWebMessageListener(WebMessageListener(
                    jsObjectName: "appRouteHandler",
                    allowedOriginRules: {'*'},
                    onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) {
                      final routesRawData = message?.data;
                      if (routesRawData == null) return;

                      final routesData = jsonDecode(routesRawData);
                      final route = routesData["route"] ?? '';

                      if (route == '/settings/your-profile') {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SecondScreen(),
                          ),
                        );
                      }
                    },
                  ));
                }

                _webViewController!.addJavaScriptHandler(
                  handlerName: 'secondScreenNavigationHandler',
                  callback: (args) {
                    if (args.isEmpty) return;
                    final route = args[0]['route'];

                    if (route == '/settings/your-profile') {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecondScreen(),
                        ),
                      );
                    }
                  },
                );

                await controller.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
              },
              onLoadStart: (controller, url) async {},
              onCreateWindow: (controller, createWindowAction) async {
                final Uri? uri = createWindowAction.request.url;
                if (uri == null) {
                  return false;
                }
                return true;
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              shouldOverrideUrlLoading: (
                controller,
                NavigationAction navigationAction,
              ) async {
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                _pullToRefreshController.endRefreshing();
              },
              onReceivedError: (controller, request, error) {
                _pullToRefreshController.endRefreshing();
              },
              onProgressChanged: (controller, progress) {},
              onConsoleMessage: (controller, consoleMessage) {
                log(consoleMessage.toString(), name: 'AWB-Console');
              },
            ),
          ),
        ],
      ),
    );
  }
}
