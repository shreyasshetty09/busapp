import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class AddBusPage extends StatefulWidget {
  @override
  _AddBusPageState createState() => _AddBusPageState();
}

class _AddBusPageState extends State<AddBusPage> {
  final TextEditingController _busNameController = TextEditingController();
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _originTimeController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _intermediatePlaces = [];
  final TextEditingController _intermediatePlaceController =
      TextEditingController();
  final TextEditingController _intermediateTimeController =
      TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _addBus() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        User? user = _auth.currentUser;
        if (user != null) {
          String messageWithBullets = _messageController.text
              .split('\n')
              .map((line) => '• $line')
              .join('\n');

          await _firestore.collection('buses').add({
            'busName': _busNameController.text.toUpperCase(),
            'busNumber': _busNumberController.text.toUpperCase(),
            'origin': _originController.text.toUpperCase(),
            'originTime': _originTimeController.text.toUpperCase(),
            'destination': _destinationController.text.toUpperCase(),
            'intermediatePlaces': _intermediatePlaces
                .map((place) => {
                      'place': place['place']!.toUpperCase(),
                      'time': place['time']!.toUpperCase(),
                    })
                .toList(),
            'message': messageWithBullets,
            'userId': user.uid,
            'status': 'active',
          });
          _showMessageDialog('Bus added successfully');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else {
          _showMessageDialog('User is not authenticated');
        }
      } catch (e) {
        _showMessageDialog('Failed to add bus: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addIntermediatePlace() {
    if (_intermediatePlaceController.text.isNotEmpty &&
        _intermediateTimeController.text.isNotEmpty) {
      setState(() {
        _intermediatePlaces.add({
          'place': _intermediatePlaceController.text.toUpperCase(),
          'time': _intermediateTimeController.text.toUpperCase(),
        });
        _intermediatePlaceController.clear();
        _intermediateTimeController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Intermediate place and time must be filled')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Bus'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextField(
                controller: _busNameController,
                labelText: 'Bus Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a bus name';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _busNumberController,
                labelText: 'Bus Number',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a bus number';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _originController,
                labelText: 'Origin',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an origin';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _originTimeController,
                labelText: 'Origin Time',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an origin time';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _destinationController,
                labelText: 'Destination',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a destination';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                'Intermediate Places',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildTextField(
                      controller: _intermediatePlaceController,
                      labelText: 'Place',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _intermediateTimeController,
                      labelText: 'Time',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addIntermediatePlace,
                    color: Colors.blue,
                  ),
                ],
              ),
              _buildIntermediatePlacesList(),
              SizedBox(height: 20),
              _buildTextField(
                controller: _messageController,
                labelText: 'Message',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addBus,
                      child: Text('Add Bus'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildIntermediatePlacesList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _intermediatePlaces.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text(_intermediatePlaces[index]['place']!),
            subtitle: Text(_intermediatePlaces[index]['time']!),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _intermediatePlaces.removeAt(index);
                });
              },
              color: Colors.red,
            ),
          ),
        );
      },
    );
  }
}
