import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../dzone_app/dzone_app.dart'; // Updated import

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  void _launchDZoneApp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DZoneApp(), // Updated class name
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DLR Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DLR Zone Administration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (user != null) ...[
              Text('Signed in as: ${user.email}'),
              const SizedBox(height: 30),
            ],

            // Admin Functions Section
            const Text(
              'Admin Functions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to user management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User Management - Coming Soon'),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('Manage Users'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to app settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App Settings - Coming Soon')),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('App Settings'),
            ),

            const SizedBox(height: 30),

            // DZone App Section
            const Text(
              'DZone App:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _launchDZoneApp(context),
              icon: const Icon(Icons.launch),
              label: const Text('Launch DZone App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
