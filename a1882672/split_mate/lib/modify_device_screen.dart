import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

class ModifyDeviceScreen extends StatefulWidget {
  final String token;
  final String propertyId;

  ModifyDeviceScreen({required this.token, required this.propertyId});

  @override
  _ModifyDeviceScreenState createState() => _ModifyDeviceScreenState();
}

class _ModifyDeviceScreenState extends State<ModifyDeviceScreen> {
  List<dynamic> _devices = [];
  Map<int, File?> _devicePhotos = {};
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchDevices(widget.propertyId);
  }

  Future<void> _fetchDevices(String houseId) async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('http://13.55.123.136:8080/devices/house/$houseId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      if (mounted) {
        setState(() {
          _devices = data;
          print('Devices fetched: $_devices');
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Failed to fetch devices');
    }
  }


  Future<void> _fetchDevicePhotos() async {
    for (var device in _devices) {
      final response = await http.get(
        Uri.parse('http://13.55.123.136:8080/devices/${device['id']}/photo'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/${device['id']}_photo.png';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _devicePhotos[device['id']] = file;
        });
      } else {
        _devicePhotos[device['id']] = null;
      }
    }
  }

  Future<void> _uploadDevicePhoto(int deviceId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png']);

    if (result != null) {
      setState(() {
        _isProcessing = true;
      });

      File file = File(result.files.single.path!);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://13.55.123.136:8080/devices/uploadDevicePhoto'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.headers['accept'] = '*/*';
      request.files.add(await http.MultipartFile.fromPath('photo', file.path, contentType: MediaType('image', 'jpeg')));
      request.fields['deviceId'] = deviceId.toString();

      var response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo uploaded successfully')));
        await _fetchDevices(widget.propertyId); // Refresh device list
        await _fetchDevicePhotos(); // Refresh device photos
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload photo')));
      }

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _modifyDevice(int deviceId, String name, String category, int power) async {
    setState(() {
      _isProcessing = true;
    });

    final response = await http.put(
      Uri.parse('http://13.55.123.136:8080/devices/$deviceId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "name": name,
        "category": category,
        "power": power,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device modified successfully')));
      await _fetchDevices(widget.propertyId); // Refresh device list
      await _fetchDevicePhotos(); // Refresh device photos
    } else {
      print('Failed to modify device');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to modify device')));
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _deleteDevice(int deviceId) async {
    setState(() {
      _isProcessing = true;
    });

    final response = await http.delete(
      Uri.parse('http://13.55.123.136:8080/devices/$deviceId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device deleted successfully')));
      await _fetchDevices(widget.propertyId); // Refresh device list
      await _fetchDevicePhotos(); // Refresh device photos
    } else {
      print('Failed to delete device');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete device')));
    }

    setState(() {
      _isProcessing = false;
    });
  }
  Future<void> _createDevice(String name, String category, int power) async {
    setState(() {
      _isProcessing = true;
    });

    final response = await http.post(
      Uri.parse('http://13.55.123.136:8080/devices'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "category": category,
        "houseId": int.parse(widget.propertyId),
        "id": 0, // id will be automatically generated by the server
        "name": name,
        "power": power,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device created successfully')));
      await _fetchDevices(widget.propertyId); // Refresh device list
    } else {
      print('Failed to create device');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create device')));
    }

    setState(() {
      _isProcessing = false;
    });
  }
  void _showCreateDeviceDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController powerController = TextEditingController();
    String category = 'elec';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New Device', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Device Name'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(labelText: 'Category'),
                items: ['gas', 'water', 'elec'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    category = newValue!;
                  });
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: powerController,
                decoration: InputDecoration(labelText: 'Power (W)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () {
                _createDevice(nameController.text, category, int.parse(powerController.text));
                Navigator.of(context).pop();
              },
              child: Text('Create', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modify Devices'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateDeviceDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _devices.isEmpty
              ? Center(child: Text('No devices available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)))
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                TextEditingController nameController = TextEditingController(text: device['name']);
                TextEditingController powerController = TextEditingController(text: device['power'].toString());
                String category = device['category'];
                File? devicePhoto = _devicePhotos[device['id']];

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        devicePhoto != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(
                            devicePhoto,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Column(
                          children: [
                            Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: Center(
                                child: Text('No photo available', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _uploadDevicePhoto(device['id']);
                              },
                              child: Text('Upload Photo'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(labelText: 'Device Name'),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: category,
                          decoration: InputDecoration(labelText: 'Category'),
                          items: ['gas', 'water', 'elec'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              category = newValue!;
                            });
                          },
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: powerController,
                          decoration: InputDecoration(labelText: 'Power (W)'),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _modifyDevice(
                                  device['id'],
                                  nameController.text,
                                  category,
                                  int.parse(powerController.text),
                                );
                              },
                              child: Text('Modify'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _deleteDevice(device['id']);
                              },
                              child: Text('Delete'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
