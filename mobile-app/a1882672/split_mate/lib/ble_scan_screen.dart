import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Import for Device Info

class BLEScanScreen extends StatefulWidget {
  BLEScanScreen();

  @override
  _BLEScanScreenState createState() => _BLEScanScreenState();
}

class _BLEScanScreenState extends State<BLEScanScreen> {
  Map<String, BluetoothDevice> _nearbyDevices = {}; // Devices from scan results
  List<Map<String, dynamic>> _serverDevices = []; // Devices from the server
  late File _logFile;
  Map<String, String> _deviceUUIDs = {}; // Store UUIDs for each device
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  String? _localDeviceUUID; // Store the local device UUID

  @override
  void initState() {
    super.initState();
    _initializeLogFile();
    _fetchServerDevices();
    _setDeviceUUID();
  }

  // Initialize log file for writing logs
  Future<void> _initializeLogFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Directory logDir = Directory('${appDocDir.path}/BLE_log');

    if (!(await logDir.exists())) {
      await logDir.create();
    }

    List<FileSystemEntity> files = logDir.listSync();
    File? unsentLogFile;

    // Check if there's an unsent file (filename not containing 'sent')
    for (var file in files) {
      if (file is File && !file.path.contains('sent')) {
        unsentLogFile = file;
        break;
      }
    }

    // Use unsent file if available, else create a new log file
    if (unsentLogFile != null) {
      _logFile = unsentLogFile;
    } else {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.txt';
      _logFile = File('${logDir.path}/$fileName');
      await _logFile.create();
    }
  }

  // Set the local device UUID using device_info_plus
  Future<void> _setDeviceUUID() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        _localDeviceUUID = androidInfo.id; // Use 'id' as UUID for Android
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        _localDeviceUUID = iosInfo.identifierForVendor; // Use identifierForVendor as UUID for iOS
      }
    } catch (e) {
      print('Failed to get device UUID: $e');
      _localDeviceUUID = 'UnknownDeviceUUID';
    }
  }

  // Fetch devices from local file
  Future<void> _fetchServerDevices() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File deviceInfoFile = File('${appDocDir.path}/device_info.json');
      if (await deviceInfoFile.exists()) {
        String localContent = await deviceInfoFile.readAsString();
        setState(() {
          _serverDevices = List<Map<String, dynamic>>.from(jsonDecode(localContent));
        });
        _scanForDevices();
      } else {
        print('Device info file does not exist.');
      }
    } catch (e) {
      print('Error occurred while reading device info file: $e');
    }
  }

  // Scan for nearby BLE devices
  void _scanForDevices() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    // Listen to scan results and match with server devices
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        for (var serverDevice in _serverDevices) {
          // Match device based on BLE address
          if (serverDevice['bleaddress'] != null && r.device.id.toString() == serverDevice['bleaddress']) {
            setState(() {
              _nearbyDevices[serverDevice['bleaddress']] = r.device;
              // Assign a UUID to the device if not already assigned
              if (!_deviceUUIDs.containsKey(serverDevice['bleaddress'])) {
                _deviceUUIDs[serverDevice['bleaddress']] = _localDeviceUUID ?? 'UnknownDeviceUUID';
              }
            });
          }
        }
      }
    });

    // Stop scanning after 5 seconds
    await Future.delayed(Duration(seconds: 5));
    FlutterBluePlus.stopScan();
  }

  // Use the BLE device and write to log file
  Future<void> _useDevice(String deviceId, String bleAddress) async {
    // Use the device UUID from the device_info_plus
    String deviceUUID = _localDeviceUUID ?? 'UnknownDeviceUUID';
    String currentTime = DateTime.now().toIso8601String();
    Map<String, String> logEntry = {
      'deviceUUID': deviceUUID,
      'bleUUID': bleAddress,
      'timestamp': currentTime,
    };

    try {
      // Append log entry to the file using utf8 encoding
      await _logFile.writeAsString(jsonEncode(logEntry) + ',', mode: FileMode.append, encoding: utf8);
      print('Log Entry Written: ${jsonEncode(logEntry)}');
      String completeLog = await _logFile.readAsString(encoding: utf8);
      print('Complete Log File Content:\n$completeLog');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usage logged successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to write log: $e')),
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
              onPressed: () async {
                await _useDevice(serverDevice['id'].toString(), bleAddress);
                // Disable button after use to prevent multiple clicks
                setState(() {
                  _nearbyDevices.remove(bleAddress);
                });
              },
              child: Text('Use'),
            ),
          );
        }).toList(),
      ),
    );
  }
}
