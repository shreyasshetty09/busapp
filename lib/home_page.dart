import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_bus_page.dart';
import 'manage_buses_page.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LoginPage()), // Navigate to LoginPage after logout
      );
    } catch (e) {
      // Handle logout errors if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.home,
                  size: 100,
                  color: Colors.white,
                ),
                SizedBox(height: 40),
                _buildHomeButton(
                  context,
                  'Manage Buses',
                  Icons.directions_bus,
                  Colors.green,
                  ManageBusesPage(),
                ),
                SizedBox(height: 20),
                _buildHomeButton(
                  context,
                  'Add Bus',
                  Icons.add,
                  Colors.orange,
                  AddBusPage(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context, String text, IconData icon,
      Color color, Widget page) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      icon: Icon(icon, size: 30),
      label: Text(
        text,
        style: TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        textStyle: TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
        shadowColor: Colors.black,
      ),
    );
  }
}
