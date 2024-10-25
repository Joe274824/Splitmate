import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothMatchingScreen extends StatefulWidget {
  final String token;
  final String propertyId;

  BluetoothMatchingScreen({required this.token, required this.propertyId});

  @override
  _BluetoothMatchingScreenState createState() => _BluetoothMatchingScreenState();
}

class _BluetoothMatchingScreenState extends State<BluetoothMatchingScreen> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  bool _isScanning = false;
  Map<String, BluetoothDevice> _nearbyDevices = {}; // BLE devices from scan results

  @override
  void initState() {
    super.initState();
    _fetchDevices(widget.propertyId);
  }

  @override
  void dispose() {
    if (_isScanning) {
      FlutterBluePlus.stopScan();
      _isScanning = false;
    }
    super.dispose();
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

  void _scanForDevices() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _nearbyDevices.clear();
    });

    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          for (ScanResult result in results) {
            _nearbyDevices[result.device.remoteId.toString()] = result.device;
          }
          _isScanning = false;
        });
      }
    });

    // Stop scanning after 5 seconds
    await Future.delayed(Duration(seconds: 5));
    if (mounted) {
      FlutterBluePlus.stopScan();
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _updateDeviceBleAddress(int deviceId, String bleAddress) async {
    final response = await http.put(
      Uri.parse('http://13.55.123.136:8080/devices/$deviceId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "bleaddress": bleAddress,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('BLE address updated successfully')));
      _fetchDevices(widget.propertyId); // Refresh device list
    } else {
      print('Failed to update BLE address');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update BLE address')));
    }
  }

  void _showBleSelectionDialog(int deviceId, String deviceName) {
    _scanForDevices(); // Start scanning for BLE devices when the dialog opens
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modify BLE for $deviceName', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: Container(
            width: double.minPositive,
            child: _isScanning || _nearbyDevices.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _nearbyDevices.length,
              itemBuilder: (context, index) {
                final bleDevice = _nearbyDevices.values.elementAt(index);
                return ListTile(
                  leading: Icon(Icons.bluetooth, color: Colors.blueAccent),
                  title: Text(
                    '${bleDevice.name.isNotEmpty ? bleDevice.name : 'Unknown'}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${bleDevice.remoteId.toString()}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _updateDeviceBleAddress(deviceId, bleDevice.remoteId.toString());
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _scanForDevices(); // Refresh scan
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Modify BLE for \$deviceName', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      content: Container(
                        width: double.minPositive,
                        child: _isScanning || _nearbyDevices.isEmpty
                            ? Center(child: CircularProgressIndicator())
                            : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _nearbyDevices.length,
                          itemBuilder: (context, index) {
                            final bleDevice = _nearbyDevices.values.elementAt(index);
                            return ListTile(
                              leading: Icon(Icons.bluetooth, color: Colors.blueAccent),
                              title: Text(
                                '${bleDevice.name.isNotEmpty ? bleDevice.name : 'Unknown'}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${bleDevice.remoteId.toString()}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                _updateDeviceBleAddress(deviceId, bleDevice.remoteId.toString());
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            _scanForDevices(); // Refresh scan
                          },
                          child: Text('Refresh', style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Refresh', style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
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
        title: Text('Bluetooth Matching', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _devices.isEmpty
          ? Center(child: Text('No devices available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _devices.length,
          itemBuilder: (context, index) {
            final device = _devices[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          device['name'],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (device['bleaddress'] == null || device['bleaddress'] == 'none') ElevatedButton(
                          onPressed: () {
                            _showBleSelectionDialog(device['id'], device['name']);
                          },
                          child: Text('Match BLE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        )
                        else ElevatedButton(
                          onPressed: () {
                            _showBleSelectionDialog(device['id'], device['name']);
                          },
                          child: Text('Modify BLE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Current BLE Address: ${device['bleaddress'] == "none" || device['bleaddress'] == null ? "Not matched BLE sensor" : device['bleaddress']}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
