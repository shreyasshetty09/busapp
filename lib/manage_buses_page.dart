import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageBusesPage extends StatefulWidget {
  @override
  _ManageBusesPageState createState() => _ManageBusesPageState();
}

class _ManageBusesPageState extends State<ManageBusesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateBusStatus(String busId, bool isActive) async {
    try {
      await _firestore
          .collection('buses')
          .doc(busId)
          .update({'status': isActive ? 'active' : 'inactive'});
      _showMessageDialog('Bus status updated');
    } catch (e) {
      _showMessageDialog('Failed to update status: $e');
    }
  }

  void _showMessageDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Message'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Buses'),
      ),
      body: user == null
          ? Center(child: Text('User not authenticated'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('buses')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var buses = snapshot.data?.docs ?? [];

                if (buses.isEmpty) {
                  return Center(child: Text('No buses found'));
                }

                return ListView.builder(
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    var bus = buses[index];
                    var busData = bus.data() as Map<String, dynamic>;

                    var intermediatePlaces = (busData['intermediatePlaces']
                            as List<dynamic>)
                        .map((place) => '${place['place']} (${place['time']})')
                        .join(', ');

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          title: Text(
                            busData['busName'].toString().toUpperCase(),
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              Text(
                                'Bus Number: ${busData['busNumber'].toString().toUpperCase()}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Origin: ${busData['origin'].toString().toUpperCase()} at ${busData['originTime'].toString().toUpperCase()}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Destination: ${busData['destination'].toString().toUpperCase()}',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Intermediate Places: $intermediatePlaces',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Status: ${busData['status'].toString().toUpperCase()}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          trailing: Switch(
                            value: busData['status'] == 'active',
                            onChanged: (value) {
                              _updateBusStatus(bus.id, value);
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            inactiveTrackColor:
                                Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
