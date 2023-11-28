import 'package:flavours_example/my_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'saved_articles_provider.dart';
import 'app_state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AppState(),
        ),
        ChangeNotifierProvider(
          create: (context) => SavedArticlesProvider(),
        ),
      ],
      child: const MyApp(
        flavor: 'production app 2',
      ),
    ),
  );
}
