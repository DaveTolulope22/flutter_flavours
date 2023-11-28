import 'package:flutter/material.dart';
import 'shared_drawer.dart';

class PodesavanjaPage extends StatefulWidget {
  const PodesavanjaPage({Key? key}) : super(key: key);

  @override
  PodesavanjaPageState createState() => PodesavanjaPageState();
}

class PodesavanjaPageState extends State<PodesavanjaPage> {
  bool najvaznijeEnabled = true;
  bool test1Enabled = false;
  bool pushNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        leading: Builder(builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }),
        title: const Text(
          'Podešavanja',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
          ),
        ),
        actions: const [
          // Remove the account_balance icon from the actions list
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  'Obaveštenja',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text('Najvažnije'),
                  trailing: CustomCheckbox(
                    value: najvaznijeEnabled,
                    onChanged: (value) {
                      setState(() {
                        najvaznijeEnabled = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Test 1'),
                  trailing: CustomCheckbox(
                    value: test1Enabled,
                    onChanged: (value) {
                      setState(() {
                        test1Enabled = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Push Notifications'),
                  trailing: CustomCheckbox(
                    value: pushNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        pushNotificationsEnabled = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: const SharedDrawer(),
    );
  }
}

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const CustomCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.black,
      checkColor: Colors.white,
    );
  }
}
