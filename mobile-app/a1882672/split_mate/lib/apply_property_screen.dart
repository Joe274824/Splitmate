import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ApplyPropertyScreen extends StatefulWidget {
  final String token;

  ApplyPropertyScreen({required this.token});

  @override
  _ApplyPropertyScreenState createState() => _ApplyPropertyScreenState();
}

class _ApplyPropertyScreenState extends State<ApplyPropertyScreen> {
  List<Map<String, dynamic>> _properties = [];
  String _username = '';
  int _userId = 0;
  String _searchQuery = ''; // Used for filtering properties

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchProperties();
    _createHousePhotosDirectory();
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
        _username = data['username'];
        _userId = data['id'];
      });
    } else {
      print('Failed to fetch user details');
    }
  }

  Future<void> _fetchProperties() async {
    final response = await http.get(
      Uri.parse('http://13.55.123.136:8080/api/house'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _properties = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
      await _downloadHousePhotos();
    } else {
      print('Failed to fetch properties');
    }
  }

  Future<void> _createHousePhotosDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final housePhotosDir = Directory('${directory.path}/housePhotos');
    if (!await housePhotosDir.exists()) {
      await housePhotosDir.create();
    }
  }

  Future<void> _downloadHousePhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final housePhotosDir = Directory('${directory.path}/housePhotos');

    for (var property in _properties) {
      if (property['houseImagePath'] != null) {
        final housePhotoFile = File('${housePhotosDir.path}/housePhoto${property['houseId']}.jpg');
        if (!await housePhotoFile.exists()) {
          final response = await http.get(
            Uri.parse('http://13.55.123.136:8080/api/house/${property['houseId']}/photo'),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
              'accept': '*/*',
            },
          );

          if (response.statusCode == 200) {
            await housePhotoFile.writeAsBytes(response.bodyBytes);
          } else {
            print('Failed to download photo for house ${property['houseId']}');
          }
        }
      }
    }
  }

  void _applyForProperty(int houseId) async {
    final response = await http.post(
      Uri.parse('http://13.55.123.136:8080/application/submit?houseId=$houseId&userId=$_userId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    print("Server response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application submitted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit application')),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredProperties() {
    if (_searchQuery.isEmpty) {
      return _properties.where((property) => property['houseStatus'] == 1).toList();
    } else {
      return _properties.where((property) {
        return property['houseStatus'] == 1 &&
            (property['landlordName'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                property['address'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                property['name'].toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredProperties = _getFilteredProperties();

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply for Property'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search properties by landlord, address, or name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: filteredProperties.isEmpty
                  ? Center(child: Text('No properties available'))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: filteredProperties.length,
                itemBuilder: (context, index) {
                  final property = filteredProperties[index];
                  final housePhotoPath = '${(getApplicationDocumentsDirectory().then((dir) => dir.path))}/housePhotos/housePhoto${property['houseId']}.jpg';
                  final housePhotoFile = File(housePhotoPath);
                  return GestureDetector(
                    onTap: () => _applyForProperty(property['houseId']),
                    child: Card(
                      elevation: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: housePhotoFile.existsSync()
                                ? Image.file(
                              housePhotoFile,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                                : Container(
                              color: Colors.grey,
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  'No photo available',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${property['name']} - ${property['address']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text('Landlord: ${property['landlordName']}'),
                                SizedBox(height: 5),
                                ElevatedButton(
                                  onPressed: () => _applyForProperty(property['houseId']),
                                  child: Text('Apply'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
