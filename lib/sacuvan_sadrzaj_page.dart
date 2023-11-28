import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flavours_example/web_view_controller.dart';
import 'package:flavours_example/web_view_screen.dart';
import 'package:provider/provider.dart';
import 'shared_drawer.dart';
import 'saved_articles_provider.dart';

class SacuvanSadrzajPage extends StatelessWidget {
  const SacuvanSadrzajPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appBarColor = Color(0xFFFFFFFF);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        leading: Builder(builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        title: const Text(
          'Sačuvan sadržaj',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
          ),
        ),
        actions: const [
          // Remove the account_balance icon from the actions list
        ],
      ),
      body: Container(
        color: appBarColor,
        child: Consumer<SavedArticlesProvider>(
          builder: (context, savedArticles, child) {
            return ListView.builder(
              itemCount: savedArticles.savedArticles.length,
              itemBuilder: (context, index) {
                String articleUrl = savedArticles.savedArticles[index];
                return FutureBuilder<ArticleData>(
                  future: extractArticleData(articleUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: double.infinity,
                        height: 100.0,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Container(
                        width: double.infinity,
                        height: 100.0,
                        alignment: Alignment.center,
                        child: const Icon(Icons.error),
                      );
                    } else {
                      ArticleData data = snapshot.data!;
                      return InkWell(
                        onTap: () {
                          // Navigate to WebViewScreen with the current article URL
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewScreen(
                                url: articleUrl,
                                manager: WebViewManager(customUrl: articleUrl),
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: 120.0,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Card(
                              color: appBarColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      data.thumbnailImageUrl,
                                      width: 100.0,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          data.date,
                                          style: const TextStyle(
                                            color: Color(0xFFBC251A),
                                            fontSize: 12.0,
                                          ),
                                        ),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          data.title,
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
      drawer: const SharedDrawer(),
    );
  }

  Future<ArticleData> extractArticleData(String articleUrl) async {
    try {
      final response = await http.get(Uri.parse(articleUrl));
      final document = parser.parse(response.body);
      final imageElement = document.querySelector('img');
      final dateElement = document.querySelector('.date.article-date');
      final titleElement = document.querySelector('#title');
      String thumbnailImageUrl = imageElement?.attributes['src'] ?? '';
      String date = dateElement?.text ?? '';
      String title = titleElement?.text ?? '';
      return ArticleData(
        thumbnailImageUrl: thumbnailImageUrl,
        date: date,
        title: title,
      );
    } catch (e) {
      print('Error extracting article data: $e');
      return ArticleData(
        thumbnailImageUrl: '',
        date: '',
        title: '',
      );
    }
  }
}

class ArticleData {
  final String thumbnailImageUrl;
  final String date;
  final String title;

  ArticleData({
    required this.thumbnailImageUrl,
    required this.date,
    required this.title,
  });
}
