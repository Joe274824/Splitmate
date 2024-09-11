import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'models/usage_data.dart';  // For date formatting

class UsageHistoryScreen extends StatefulWidget {
  final String token; // Receives the token from the LoginScreen

  UsageHistoryScreen({required this.token});

  @override
  _UsageHistoryScreenState createState() => _UsageHistoryScreenState();
}

class _UsageHistoryScreenState extends State<UsageHistoryScreen> {
  int _currentPage = 0;
  bool _isSearchByDateActive = false;
  bool _isSearchByDeviceActive = false;
  final int _recordsPerPage = 10;
  List<UsageData> _usageHistory = [];
  List<UsageData> _allUsageHistory = []; // Saves all records
  String _selectedDevice = "Devices"; // Default display text
  List<String> _deviceNames = []; // Stores device names

  @override
  void initState() {
    super.initState();
    _fetchUsageHistory(); // Call API to get data
    _fetchDeviceNames(); // Call API to get device names
  }

  List<UsageData> _getCurrentPageRecords() {
    int start = _currentPage * _recordsPerPage;
    int end = start + _recordsPerPage;
    end = end > _usageHistory.length ? _usageHistory.length : end;
    return _usageHistory.sublist(start, end);
  }

  void _fetchUsageHistory() async {
    final response = await http.get(
      Uri.parse('http://120.26.0.31:8080/deviceUsages/username'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<UsageData> fetchedData = data.map((item) {
        // Safely parsing the date and usageTime, and category
        DateTime? startTime;
        String formattedDate = 'Invalid date';
        String formattedStartTime = 'Invalid time';
        String category = item['device']['category'] ?? 'Unknown';
        String deviceName = item['device']['name'] ?? 'Unknown Device';
        int usageTime = item['usageTime'] ?? 0;

        try {
          startTime = DateTime.parse(item['startTime']);
          formattedDate = DateFormat('dd/MM/yyyy').format(startTime);
          formattedStartTime = DateFormat('hh:mm a').format(startTime);
        } catch (e) {
          print("Error parsing date: $e");
        }

        return UsageData(
          formattedDate,
          formattedStartTime,
          deviceName,
          '$usageTime mins',
          category,
        );
      }).toList();

      setState(() {
        _usageHistory = fetchedData;
        _allUsageHistory = fetchedData; // Save all data
      });
    } else {
      print('Failed to load usage history');
    }
  }

  void _fetchDeviceNames() async {
    final response = await http.get(
      Uri.parse('http://120.26.0.31:8080/devices'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<String> deviceNames = data.map<String>((item) => item['name'] ?? 'Unknown Device').toList();

      setState(() {
        _deviceNames = deviceNames;
      });
    } else {
      print('Failed to load device names');
    }
  }

  void _searchByDate(DateTime selectedDate) {
    setState(() {
      _isSearchByDateActive = true;
      _isSearchByDeviceActive = false;
      _selectedDevice = "Devices"; // Reset device selection
      _usageHistory = _allUsageHistory.where((record) {
        return record.date == DateFormat('dd/MM/yyyy').format(selectedDate);
      }).toList();
      if (_usageHistory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No usage on selected date')));
      }
      _currentPage = 0;
    });
  }

  void _searchByDevice(String deviceName) {
    setState(() {
      _isSearchByDeviceActive = true;
      _isSearchByDateActive = false;
      _selectedDevice = deviceName; // Update displayed device name
      _usageHistory = _allUsageHistory.where((record) {
        return record.device == deviceName;
      }).toList();
      if (_usageHistory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No usage found for selected device')));
      }
      _currentPage = 0;
    });
  }

  void _resetDeviceSearch() {
    setState(() {
      _isSearchByDeviceActive = false;
      _selectedDevice = "Devices";
      _usageHistory = _allUsageHistory; // Reset to all records
    });
  }

  void _showDevicePicker() async {
    String? selectedDevice = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Select Device'),
          children: _deviceNames
              .map((device) => SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, device);
            },
            child: Text(device),
          ))
              .toList(),
        );
      },
    );
    if (selectedDevice != null) {
      _searchByDevice(selectedDevice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usage History'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(_isSearchByDateActive ? Colors.blue : Colors.grey),
                ),
                onPressed: () async {
                  DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    _searchByDate(selectedDate);
                  }
                },
                child: Text('Search by Date', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_selectedDevice == "Devices") {
                    _showDevicePicker(); // Show device picker
                  } else {
                    _resetDeviceSearch(); // Reset search
                  }
                },
                child: Text(_selectedDevice), // Display current selected device or "Devices"
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isSearchByDateActive = false;
                    _isSearchByDeviceActive = false;
                    _selectedDevice = "Devices"; // Reset device selection
                    _usageHistory = _allUsageHistory; // Reset to all records
                  });
                },
                child: Text('Reset'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _getCurrentPageRecords().length,
              itemBuilder: (context, index) {
                UsageData data = _getCurrentPageRecords()[index];
                return ListTile(
                  title: Text(
                    '${data.date} - ${data.startTime}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Device: ${data.device}\nDuration: ${data.duration}\nCategory: ${data.category}', // Updated to show category
                    style: TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _currentPage > 0
                    ? () {
                  setState(() {
                    _currentPage--;
                  });
                }
                    : null,
                child: Text('Previous'),
              ),
              ElevatedButton(
                onPressed: _currentPage < (_usageHistory.length / _recordsPerPage).ceil() - 1
                    ? () {
                  setState(() {
                    _currentPage++;
                  });
                }
                    : null,
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
