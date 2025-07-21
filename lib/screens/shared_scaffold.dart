import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_update_screen.dart';

class SharedScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final void Function(int) onTabTapped;

  const SharedScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green[700],
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 16.0),
        //     child: Row(
        //       children: [
        //         const Text(
        //           "Ramu",
        //           style: TextStyle(fontSize: 16, color: Colors.white),
        //         ),
        //         const SizedBox(width: 8),
        //         const CircleAvatar(
        //           backgroundImage: AssetImage('assets/images/farmer_icon.png'),
        //           radius: 18,
        //         ),
        //       ],
        //     ),
        //   )
        // ],
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
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
                onTabTapped(0);
              },
            ),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
            ),
            const ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
            ),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          Navigator.pop(context);
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileUpdateScreen()),
              );
              break;
            default:
              onTabTapped(index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assistant_outlined), label: 'AI Assitant'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
