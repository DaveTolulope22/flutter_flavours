import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'podesavanja_page.dart';
import 'sacuvan_sadrzaj_page.dart';
import 'web_view_controller.dart';
import 'web_view_screen.dart';

class SharedDrawer extends StatelessWidget {
  const SharedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250, // Adjust the width as per your preference
      child: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.home, color: Colors.black),
              title:
                  const Text('Naslovna', style: TextStyle(color: Colors.black)),
              tileColor: Provider.of<AppState>(context).selectedDrawerIndex == 0
                  ? const Color(0xFFBC251A)
                  : null,
              onTap: () {
                Provider.of<AppState>(context, listen: false)
                    .selectedDrawerIndex = 0;
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => WebViewScreen(
                          manager: WebViewManager(),
                          url: '',
                        )));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text('Podešavanja',
                  style: TextStyle(color: Colors.black)),
              tileColor: Provider.of<AppState>(context).selectedDrawerIndex == 1
                  ? const Color(0xFFBC251A)
                  : null,
              onTap: () {
                Provider.of<AppState>(context, listen: false)
                    .selectedDrawerIndex = 1;
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) =>
                        const PodesavanjaPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download, color: Colors.black),
              title: const Text('Sačuvan sadržaj',
                  style: TextStyle(color: Colors.black)),
              tileColor: Provider.of<AppState>(context).selectedDrawerIndex == 2
                  ? const Color(0xFFBC251A)
                  : null,
              onTap: () {
                Provider.of<AppState>(context, listen: false)
                    .selectedDrawerIndex = 2;
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) =>
                        const SacuvanSadrzajPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
