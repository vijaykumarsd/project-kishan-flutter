
import 'package:flutter/material.dart';

class SharedScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final Function(int) onTabTapped;

  const SharedScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green[700],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: const [
                Text(
                  "Ramu",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/farmer_icon.png'),
                  radius: 18,
                ),
              ],
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Vijay Kumar"),
              accountEmail: const Text("vijay@example.com"),
              currentAccountPicture: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: Image.network(
                    "https://i.pravatar.cc/150?img=3",
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/images/user.png', fit: BoxFit.cover);
                    },
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
              decoration: const BoxDecoration(color: Colors.green),
            ),
            const ListTile(leading: Icon(Icons.home), title: Text("Home")),
            const ListTile(leading: Icon(Icons.settings), title: Text("Settings")),
            const ListTile(leading: Icon(Icons.logout), title: Text("Logout")),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        onTap: onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
