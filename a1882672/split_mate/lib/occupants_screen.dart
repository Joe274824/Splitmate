import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OccupantsScreen extends StatefulWidget {
  final String token;
  final String propertyId;

  OccupantsScreen({required this.token, required this.propertyId});

  @override
  _OccupantsScreenState createState() => _OccupantsScreenState();
}

class _OccupantsScreenState extends State<OccupantsScreen> {
  List<dynamic> _tenants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTenants(widget.propertyId);
  }

  Future<void> _fetchTenants(String houseId) async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('http://13.55.123.136:8080/api/house/tenants/$houseId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _tenants = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Failed to fetch tenant data');
    }
  }

  Future<void> _removeTenant(int tenantId) async {
    final response = await http.delete(
      Uri.parse('http://13.55.123.136:8080/api/house/tenants/${widget.propertyId}/$tenantId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tenant removed successfully')));
      _fetchTenants(widget.propertyId); // Refresh tenant list
    } else {
      print('Failed to remove tenant');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove tenant')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Occupants'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tenants.isEmpty
          ? Center(child: Text('No occupants available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _tenants.length,
          itemBuilder: (context, index) {
            final tenant = _tenants[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  tenant['username'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'ID: ${tenant['id']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirm Removal'),
                          content: Text('Are you sure you want to remove this tenant?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _removeTenant(tenant['id']);
                              },
                              child: Text('Remove', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
