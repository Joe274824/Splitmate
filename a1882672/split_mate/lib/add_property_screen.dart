import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tenant_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  final String token;
  final bool isLandlord;

  AddPropertyScreen({required this.token, required this.isLandlord});

  @override
  _AddPropertyScreenState createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _addressController = TextEditingController();
  final _propertyNameController = TextEditingController();
  bool _acceptsApplications = true; // Toggle for houseStatus
  String _landlordName = '';
  int _landlordId = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final response = await http.get(
      Uri.parse('http://13.55.123.136:8080/users/findUser'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _landlordName = data['username'];
        _landlordId = data['id'];
      });
    } else {
      print('Failed to fetch user details');
    }
  }

  Future<void> _addProperty() async {
    final requestBody = {
      'address': _addressController.text,
      'name': _propertyNameController.text,
      'houseStatus': _acceptsApplications ? 1 : 0, // 1 for accepting, 0 for not accepting
      'landlordId': _landlordId,
      'landlordName': _landlordName,
    };

    print("Sending request to server: $requestBody");

    final response = await http.post(
      Uri.parse('http://13.55.123.136:8080/api/house'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode(requestBody),
    );

    print("Server response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property added successfully')),
      );
      // Navigate to TenantScreen with necessary arguments after successful addition
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TenantScreen(
            isLandlord: widget.isLandlord,
            token: widget.token,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add property')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Property'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Property Address'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _propertyNameController,
                decoration: InputDecoration(labelText: 'Property Name'),
              ),
              SizedBox(height: 20),
              SwitchListTile(
                title: Text('Accept Tenant Applications'),
                value: _acceptsApplications,
                onChanged: (value) {
                  setState(() {
                    _acceptsApplications = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addProperty,
                child: Text('Add Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
