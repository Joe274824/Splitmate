import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BLEScanScreen extends StatefulWidget {
  final String token;

  BLEScanScreen({required this.token});

  @override
  _BLEScanScreenState createState() => _BLEScanScreenState();
}

class _BLEScanScreenState extends State<BLEScanScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  Map<String, BluetoothDevice> _nearbyDevices = {}; // Devices from scan results
  List<Map<String, dynamic>> _serverDevices = []; // Devices from the server

  @override
  void initState() {
    super.initState();
    _fetchServerDevices();
  }

  // Fetch devices from server
// Fetch devices from server
  Future<void> _fetchServerDevices() async {
    final response = await http.get(
      Uri.parse('http://120.26.0.31:8080/devices'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _serverDevices = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });

      // Print server devices map
      print('Server Devices: $_serverDevices'); // Add this line to print the server devices map

      _scanForDevices();
    } else {
      print('Failed to fetch devices from server');
    }
  }



// Scan for nearby BLE devices
  void _scanForDevices() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    // Listen to scan results and match with server devices
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Print details of each scanned BLE device
        // print('Scanned Device: ${r.device.name}, ID: ${r.device.id}, RSSI: ${r.rssi}');

        for (var serverDevice in _serverDevices) {
          // Match device based on BLE address
          if (serverDevice['bleaddress'] != null && r.device.id.toString() == serverDevice['bleaddress']) {
            setState(() {
              _nearbyDevices[serverDevice['bleaddress']] = r.device;
            });
          }
        }
      }
    });

    // Stop scanning after 5 seconds
    await Future.delayed(Duration(seconds: 5));
    FlutterBluePlus.stopScan();
  }


  // Send device usage to server
// Send device usage to server
  Future<void> _useDevice(String deviceId, String bleAddress) async {
    // Placeholder MAC address for the phone (you can retrieve this from a library)
    String macAddress = "HH5JM0070D5K";

    // 打印上传字段
    print('send to server: MACAddress=$macAddress, UUID=$bleAddress');

    final response = await http.post(
      Uri.parse('http://120.26.0.31:8080/bluetooth/usage?MACAddress=$macAddress&uuid=$deviceId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device usage sent to server')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send usage data')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BLE Scan and Use'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchServerDevices, // Refresh to scan again
          ),
        ],
      ),
      body: _nearbyDevices.isEmpty
          ? Center(child: Text('No matching BLE devices found'))
          : ListView(
        children: _nearbyDevices.entries.map((entry) {
          String bleAddress = entry.key;
          BluetoothDevice device = entry.value;
          Map<String, dynamic> serverDevice = _serverDevices.firstWhere((dev) => dev['bleaddress'] == bleAddress);
          return ListTile(
            title: Text(serverDevice['name']),
            subtitle: Text(device.id.toString()),
            trailing: ElevatedButton(
              onPressed: () => _useDevice(serverDevice['id'].toString(), bleAddress),
              child: Text('Use'),
            ),
          );
        }).toList(),
      ),
    );
  }
}
