import 'dart:async';
import 'dart:convert';
import 'dart:io'; // New import
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewManager {
  final String? customUrl;
  WebViewManager({this.customUrl});
  final urlController = StreamController<String>.broadcast();
  final _urlSpecificController = StreamController<bool>.broadcast();
  final List<Completer<WebViewController>> _controllers =
      List.generate(7, (_) => Completer<WebViewController>());
  final List<WebViewController?> _webViewControllers =
      List.filled(7, null, growable: false);

  int _currentIndex = 0;

  List<String> get urls => _urls;

  final List<String> _urls = Platform.isIOS
      ? [
          'https://krik.mpanel.app/api/v1/ios/getMenu/10/html',
          'https://krik.mpanel.app/api/v1/ios/getMenu/2/html',
          'https://krik.mpanel.app/api/v1/ios/getMenu/3/html',
          'https://krik.mpanel.app/api/v1/ios/getMenu/7/html',
          'https://krik.mpanel.app/api/v1/ios/getMenu/6/html',
          'https://krik.mpanel.app/api/v1/ios/getMenu/5/html',
          'https://krik.mpanel.app/api/v1/ios/getSearch'
        ]
      : [
          'https://krik.mpanel.app/api/v1/android/getMenu/10/html',
          'https://krik.mpanel.app/api/v1/android/getMenu/2/html',
          'https://krik.mpanel.app/api/v1/android/getMenu/3/html',
          'https://krik.mpanel.app/api/v1/android/getMenu/7/html',
          'https://krik.mpanel.app/api/v1/android/getMenu/6/html',
          'https://krik.mpanel.app/api/v1/android/getMenu/5/html',
          'https://krik.mpanel.app/api/v1/android/getSearch'
        ];

  StreamController<bool> articleController = StreamController<bool>();

  Stream<bool> get specificUrlStream => _urlSpecificController.stream;

  get isSpecificUrl => null;

  void onUrlChanged(String url) {
    urlController.sink.add(url);
    _urlSpecificController.sink.add(url.startsWith('https://www.krik.rs/'));
    _currentArticleUrl = url;
  }

  void dispose() {
    urlController.close();
    _urlSpecificController.close();
    for (var controller in _loadingControllers) {
      controller.close();
    }
  }

  final List<StreamController<bool>> _loadingControllers =
      List.generate(7, (_) => StreamController<bool>.broadcast());

  Future<bool> onWillPopOrGoBack(BuildContext context) async {
    if (_webViewControllers[_currentIndex] != null &&
        await _webViewControllers[_currentIndex]!.canGoBack()) {
      await _webViewControllers[_currentIndex]!.goBack();
      _webViewControllers[_currentIndex]!.currentUrl().then((url) {
        if (url != null) {
          onUrlChanged(url);
        }
      });
      return false;
    } else {
      if (context.mounted) {
        Navigator.of(context).maybePop();
      }
      return true;
    }
  }

  // A variable to keep track of the current URL
  String? _currentArticleUrl;

  // Getter for currentArticleUrl
  String? get currentArticleUrl => _currentArticleUrl;

  Widget buildWebView(int index) {
    return Stack(
      children: [
        WebView(
          initialUrl: customUrl ?? _urls[index],
          javascriptMode: JavascriptMode.unrestricted,
          gestureNavigationEnabled: false,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer()..onUpdate = (e) => {},
            ),
          },
          onWebViewCreated: (WebViewController webViewController) async {
            _webViewControllers[index] = webViewController;
            _controllers[index].complete(webViewController);
            await _webViewControllers[index]?.runJavascriptReturningResult("""
            console.log = function(message) {
                Console.postMessage(message);
            };
            document.addEventListener('click', function(e) { 
                console.log('Clicked: ' + e.target); 
            });
          """);
          },
          onPageStarted: (String url) {
            _loadingControllers[index].sink.add(true); // Show loading screen
          },
          onPageFinished: (String url) async {
            setFontSize('19px');
            onUrlChanged(url);
            _loadingControllers[index].sink.add(false); // Hide loading screen
            articleController.sink.add(url.startsWith(
                    'https://krik.mpanel.app/api/v1/ios/getArticle/') ||
                url.startsWith(
                    'https://krik.mpanel.app/api/v1/android/getArticle/'));
            _currentArticleUrl = url; // Store the current URL
            if (Platform.isAndroid) {
              await _initializeWAI(_webViewControllers[index]!);
            }
          },
          navigationDelegate: (NavigationRequest request) async {
            print('Processing request for: ${request.url}');
            if (request.url.startsWith('imag://openArticle/')) {
              final articleId = request.url.split('/').last;
              final String articleUrl =
                  'https://krik.mpanel.app/api/v1/ios/getArticle/$articleId/html';
              _webViewControllers[index]?.loadUrl(articleUrl);
              return NavigationDecision.prevent;
            } else if (request.url.startsWith('imag://video/')) {
              final videoUrl = request.url.replaceFirst('imag://video/', '');
              if (await canLaunchUrl(Uri.parse(videoUrl))) {
                await launchUrl(Uri.parse(videoUrl));
              } else {
                throw 'Could not launch $videoUrl';
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          javascriptChannels: <JavascriptChannel>{
            _createConsoleJavascriptChannel(),
            _createVideoOpenJavascriptChannel(),
            if (Platform.isAndroid) _createArticleOpenJavascriptChannel(),
          },
        ),
        Positioned.fill(
          child: StreamBuilder<bool>(
            stream: _loadingControllers[index].stream,
            initialData: true,
            builder: (context, snapshot) {
              if (snapshot.data!) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                    Container(
                      padding: const EdgeInsets.all(0.8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'K',
                        style: TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }

  void loadUrlForTab(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      _webViewControllers[_currentIndex]?.loadUrl(_urls[_currentIndex]);
    }
  }

//increasing the frontsize of webview
  void setFontSize(String size) {
    for (int i = 0; i < _webViewControllers.length; i++) {
      if (_webViewControllers[i] != null) {
        List<String> tags = ['p', 'h1', 'h2', 'h3', 'div', 'span', 'a'];

        for (String tag in tags) {
          _webViewControllers[i]!.runJavascriptReturningResult(
              "var elements = document.getElementsByTagName('$tag'); for (var i = 0; i < elements.length; i++) { elements[i].style.fontSize = '$size'; }");
        }
      }
    }
  }

  JavascriptChannel _createConsoleJavascriptChannel() {
    return JavascriptChannel(
      name: 'Console',
      onMessageReceived: (JavascriptMessage message) {
        print('JS Console: ${message.message}');
      },
    );
  }

  JavascriptChannel _createVideoOpenJavascriptChannel() {
    return JavascriptChannel(
      name: 'VideoOpen',
      onMessageReceived: (JavascriptMessage message) async {
        final videoData = jsonDecode(message.message);
        final platform = videoData['platform'];
        final id = videoData['id'];
        switch (platform) {
          case 'youtube':
            final videoUrl = 'https://www.youtube.com/watch?v=$id';
            if (await canLaunchUrl(Uri.parse(videoUrl))) {
              await launchUrl(Uri.parse(videoUrl));
            } else {
              throw 'Could not launch $videoUrl';
            }
            break;
          // handle other platforms here...
        }
      },
    );
  }

  Future<void> _initializeWAI(WebViewController controller) async {
    const String initializeScript = """
      (function() {
        window._wai = window._wai || {
          openArticle: function(id) {
            ArticleOpen.postMessage(id);
          },
          video: function(platform, id) {
            VideoOpen.postMessage(JSON.stringify({platform: platform, id: id}));
          }
        };

        Object.defineProperty(window, 'WAI', {
          value: window._wai,
          writable: false
        });
      })();
    """;
    await controller.runJavascriptReturningResult(initializeScript);
  }

  JavascriptChannel _createArticleOpenJavascriptChannel() {
    return JavascriptChannel(
      name: 'ArticleOpen',
      onMessageReceived: (JavascriptMessage message) {
        final int articleId = int.parse(message.message);
        final String articleUrl =
            'https://krik.mpanel.app/api/v1/android/getArticle/$articleId/html';
        _webViewControllers[_currentIndex]?.loadUrl(articleUrl);

        // Add true to articleController to signify that an article is opened
        articleController.sink.add(true);

        // Retrieve the actual URL
        String actualUrl = articleUrl;
        print(actualUrl); // or use the actual URL in your code
      },
    );
  }

  final _loadingController = StreamController<bool>.broadcast();

  Widget buildaccountWebView() {
    {
      return Stack(
        children: [
          WebView(
            initialUrl: 'https://www.krik.rs/podrzi-nas',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) async {
              // Add any additional setup code for the WebView here
            },
            onPageStarted: (String url) {
              // Show loading screen
              _loadingController.sink.add(true);
            },
            onPageFinished: (String url) {
              // Hide loading screen
              _loadingController.sink.add(false);
            },
            navigationDelegate: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
            // Add any additional JavascriptChannels here
          ),
          StreamBuilder<bool>(
            stream: _loadingController.stream,
            initialData: true,
            builder: (context, snapshot) {
              if (snapshot.data!) {
                return const Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                      Text(
                        'K',
                        style: TextStyle(
                          fontSize: 35.0, // Increase the size here
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      );
    }
  }
}
