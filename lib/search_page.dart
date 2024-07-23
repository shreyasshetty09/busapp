import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchBuses() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please fill the origin and destination fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String origin = _originController.text.toUpperCase();
      String destination = _destinationController.text.toUpperCase();
      String? time = _timeController.text.isNotEmpty
          ? _timeController.text.toUpperCase()
          : null;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('buses')
          .where('status', isEqualTo: 'active')
          .get();

      List<Map<String, dynamic>> buses = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      List<Map<String, dynamic>> filteredBuses = buses.where((bus) {
        bool originMatch = bus['origin'].toString().toUpperCase() == origin ||
            (bus['intermediatePlaces'] as List).any(
                (place) => place['place'].toString().toUpperCase() == origin);
        bool destinationMatch =
            bus['destination'].toString().toUpperCase() == destination ||
                (bus['intermediatePlaces'] as List).any((place) =>
                    place['place'].toString().toUpperCase() == destination);
        if (time != null) {
          bool timeMatch = bus['originTime'].toString().toUpperCase() == time ||
              (bus['intermediatePlaces'] as List).any(
                  (place) => place['time'].toString().toUpperCase() == time);
          return originMatch && destinationMatch && timeMatch;
        }
        return originMatch && destinationMatch;
      }).toList();

      setState(() {
        _searchResults = filteredBuses;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetSearch() {
    _originController.clear();
    _destinationController.clear();
    _timeController.clear();
    setState(() {
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Buses'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetSearch,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildTextField(_originController, 'Origin', Icons.location_on),
            _buildTextField(_destinationController, 'Destination', Icons.flag),
            _buildTextField(
                _timeController, 'Time (optional)', Icons.access_time),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _searchBuses,
              child: _isLoading ? CircularProgressIndicator() : Text('Search'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(child: Text('No buses found'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        var bus = _searchResults[index];

                        bool isIntermediateOrigin = false;
                        String intermediateOriginTime = '';
                        for (var place in bus['intermediatePlaces']) {
                          if (place['place'].toString().toUpperCase() ==
                              _originController.text.toUpperCase()) {
                            isIntermediateOrigin = true;
                            intermediateOriginTime = place['time'];
                            break;
                          }
                        }

                        bool isIntermediateDestination = false;
                        String intermediateDestinationTime = '';
                        for (var place in bus['intermediatePlaces']) {
                          if (place['place'].toString().toUpperCase() ==
                              _destinationController.text.toUpperCase()) {
                            isIntermediateDestination = true;
                            intermediateDestinationTime = place['time'];
                            break;
                          }
                        }

                        return Card(
                          margin: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          child: ListTile(
                            title: Text(
                              bus['busName'].toString().toUpperCase(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 5),
                                if (isIntermediateOrigin)
                                  Text(
                                    'Origin: ${_originController.text.toUpperCase()} at $intermediateOriginTime (Intermediate)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  )
                                else
                                  Text(
                                    'Origin: ${bus['origin'].toString().toUpperCase()} at ${bus['originTime'].toString().toUpperCase()}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                if (isIntermediateDestination)
                                  Text(
                                    'Destination: ${_destinationController.text.toUpperCase()} at $intermediateDestinationTime (Intermediate)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                  )
                                else
                                  Text(
                                    'Destination: ${bus['destination'].toString().toUpperCase()} (Last stop)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                  ),
                                if (bus.containsKey('message'))
                                  Text(
                                    'Message:\n${bus['message']}',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.blueGrey),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: Text(
                'Login',
                style: TextStyle(fontSize: 18, color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String labelText, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      style: TextStyle(fontSize: 16.0),
    );
  }
}
