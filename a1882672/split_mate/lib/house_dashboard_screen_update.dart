import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_property_screen.dart';
import 'occupants_screen.dart';
import 'upload_bills_screen.dart';
import 'applications_screen.dart';
import 'modify_device_screen.dart';
import 'bluetooth_matching_screen.dart';
import 'upload_house_photo_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class HouseDashboardScreen extends StatefulWidget {
  final String token;

  HouseDashboardScreen({required this.token});

  @override
  _HouseDashboardScreenState createState() => _HouseDashboardScreenState();
}

class _HouseDashboardScreenState extends State<HouseDashboardScreen> {
  List<dynamic> _properties = [];
  String? _selectedProperty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    final response = await http.get(
      Uri.parse('http://13.55.123.136:8080/api/house/houses'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _properties = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Failed to fetch property data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('House Dashboard'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      hint: Text('Select Property'),
                      value: _selectedProperty,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedProperty = newValue!;
                        });
                      },
                      items: _properties.map<DropdownMenuItem<String>>((property) {
                        return DropdownMenuItem<String>(
                          value: property['houseId'].toString(),
                          child: Text(property['name']),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPropertyScreen(
                            token: widget.token,
                            isLandlord: true,
                          ),
                        ),
                      );
                    },
                    child: Text('New Property'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_selectedProperty != null)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildGridTile('Occupants', Icons.people, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OccupantsScreen(
                            token: widget.token,
                            propertyId: _selectedProperty!,
                          ),
                        ),
                      );
                    }),
                    _buildGridTile('Upload Bills', Icons.upload_file, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadBillsScreen(
                            token: widget.token,
                            propertyId: _selectedProperty!,
                          ),
                        ),
                      );
                    }),
                    _buildGridTile('Applications', Icons.mail, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApplicationsScreen(
                            token: widget.token,
                            propertyId: _selectedProperty!,
                          ),
                        ),
                      );
                    }),
                    _buildGridTile('Modify Device Info', Icons.devices, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModifyDeviceScreen(
                            token: widget.token,
                            propertyId: _selectedProperty!,
                          ),
                        ),
                      );
                    }),
                    _buildGridTile('Bluetooth Matching', Icons.bluetooth, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BluetoothMatchingScreen(
                            token: widget.token,
                            propertyId: _selectedProperty!,
                          ),
                        ),
                      );
                    }),
                    _buildGridTile('Upload House Photo', Icons.photo_camera, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadHousePhotoScreen(
                            token: widget.token,
                            propertyId: _selectedProperty!,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blueAccent),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
