import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'web_view_controller.dart';
import 'shared_drawer.dart'; // import the SharedDrawer
import 'package:provider/provider.dart';
import 'saved_articles_provider.dart';

class WebViewScreen extends StatefulWidget {
  final String url; // Declare `url` as a class field.

  final WebViewManager manager;
  const WebViewScreen({
    Key? key,
    required this.manager,
    required this.url,
  }) : super(key: key);

  @override
  WebViewScreenState createState() => WebViewScreenState();
}

class WebViewScreenState extends State<WebViewScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _pageController = PageController(initialPage: 0);

    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Color(0xFFFFFFFF)));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: widget.manager.urlController.stream,
      initialData: '',
      builder: (context, urlSnapshot) {
        String currentUrl = urlSnapshot.data!;
        return StreamBuilder<bool>(
          stream: widget.manager.articleController.stream,
          initialData: false,
          builder: (context, snapshot) {
            return Scaffold(
              key: _scaffoldKey,
              appBar: currentUrl.startsWith('https://www.krik.rs/')
                  ? _buildSpecificAppBar(context, widget.manager)
                  : (snapshot.data!
                      ? _buildArticleAppBar(context, widget.manager)
                      : _buildMainAppBar(context)),
              drawer: const SharedDrawer(),
              body: WillPopScope(
                onWillPop: () => widget.manager.onWillPopOrGoBack(context),
                child: PageView.builder(
                  controller: _pageController,
                  physics: (currentUrl.startsWith(
                              'https://krik.mpanel.app/api/v1/ios/getArticle/') ||
                          currentUrl.startsWith(
                              'https://krik.mpanel.app/api/v1/android/getArticle/') ||
                          currentUrl.startsWith('https://www.krik.rs/'))
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    _tabController.animateTo(index);
                    widget.manager.loadUrlForTab(index);
                  },
                  itemCount: widget.manager.urls.length,
                  itemBuilder: (context, index) {
                    return TransformPageView(
                      page: index,
                      controller: _pageController,
                      backgroundImage: 'assets/images/pic1.jpg',
                      scale: 1.0,
                      child: widget.manager.buildWebView(index),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  AppBar _buildMainAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      actions: [
        IconButton(
          onPressed: () {
            int lastTabIndex = _tabController.length - 1;
            _tabController.animateTo(lastTabIndex);
            _pageController.jumpToPage(lastTabIndex);
          },
          icon: const Icon(Icons.search, color: Colors.black),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Container(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/images/krik_logo2.png',
                        fit: BoxFit.cover,
                        width: 120,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    iconTheme: const IconThemeData(color: Colors.black),
                  ),
                  body: widget.manager.buildaccountWebView(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.account_balance, color: Colors.black),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFFBC251A), // Set the indicator color
        labelColor: const Color(0xFF010101),
        tabs: const [
          Tab(text: 'Ne propusti'),
          Tab(text: 'Novo'),
          Tab(text: 'Istražili smo'),
          Tab(text: 'Intervju'),
          Tab(text: 'Mišljenja'),
          Tab(text: 'RasKRIKavanje'),
          Tab(text: 'Pretraži članke'), // your new tab
        ],
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
      ),
      title: Container(
        alignment: const Alignment(-1.2, 0),
        child: Image.asset(
          'assets/images/krik_logo2.png',
          fit: BoxFit.cover,
          width: 120,
        ),
      ),
      leading: IconButton(
        onPressed: () {
          _scaffoldKey.currentState!.openDrawer();
        },
        icon: const Icon(Icons.menu, color: Colors.black),
      ),
    );
  }

  AppBar _buildArticleAppBar(BuildContext context, WebViewManager manager) {
    final String? currentArticleUrl = manager.currentArticleUrl;
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () async {
          await manager.onWillPopOrGoBack(context);
        },
      ),
      title: Image.asset(
        'assets/images/krik_logo2.png',
        fit: BoxFit.cover,
        width: 120,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black),
          onPressed: () {
            final String? currentArticleUrl = manager.currentArticleUrl;
            if (currentArticleUrl!.startsWith(
                    'https://krik.mpanel.app/api/v1/ios/getArticle/') ||
                currentArticleUrl.startsWith(
                    'https://krik.mpanel.app/api/v1/android/getArticle/')) {
              Share.share(currentArticleUrl);
            }
          },
        ),
        IconButton(
          icon: context
                  .watch<SavedArticlesProvider>()
                  .isArticleSaved(currentArticleUrl!)
              ? const Icon(Icons.star,
                  color: Colors.black) // Filled star for saved articles
              : const Icon(Icons.star_border,
                  color: Colors.black), // Unfilled star for unsaved articles
          onPressed: () {
            if (context
                .read<SavedArticlesProvider>()
                .isArticleSaved(currentArticleUrl)) {
              context.read<SavedArticlesProvider>().removeArticle(
                  currentArticleUrl); // Remove the article if it is already saved
            } else {
              context.read<SavedArticlesProvider>().addArticle(
                  currentArticleUrl); // Save the article if it's not saved yet
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.format_size, color: Colors.black),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Select Font Size'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: const Text('Normal'),
                        onTap: () {
                          manager.setFontSize('19px');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.format_size),
                        title: const Text('Big'),
                        onTap: () {
                          manager.setFontSize('24px');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  AppBar _buildSpecificAppBar(BuildContext context, WebViewManager manager) {
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () async {
          await manager.onWillPopOrGoBack(context);
        },
      ),
      title: Container(
        alignment: const Alignment(-1.2, 0),
        child: Image.asset(
          'assets/images/krik_logo2.png',
          fit: BoxFit.cover,
          width: 120,
        ),
      ),
    );
  }
}

class TransformPageView extends StatelessWidget {
  final int page;
  final PageController controller;
  final Widget child;
  final String backgroundImage;
  final double scale;

  const TransformPageView({
    Key? key,
    required this.page,
    required this.controller,
    required this.child,
    required this.backgroundImage,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        double value = 1.0;
        if (controller.position.haveDimensions) {
          value = controller.page! - page;
          if (value < 0) {
            value = 1.0;
          } else if (value < 1.0) {
            value = 1 - value;
          } else {
            value = 0.0;
          }
        }
        return Stack(
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                //alignment:
                alignment: const FractionalOffset(
                    0.5, 0.5), // Shift the image further to the right
                //  Alignment.centerRight, // Align the image to the right
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(backgroundImage),
                    fit: BoxFit.cover,
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            Transform.rotate(
              angle: -(1 - value) * (30 * pi / 180),
              child: Container(
                color: Colors
                    .white, // or any other color that matches your WebView background
                child: child,
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
