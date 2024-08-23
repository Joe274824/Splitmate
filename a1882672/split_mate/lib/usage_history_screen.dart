import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'models/usage_data.dart';  // For date formatting


class UsageHistoryScreen extends StatefulWidget {
  final String token; // 接收从 LoginScreen 传递的 token

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
  List<UsageData> _allUsageHistory = []; // 保存所有记录的副本
  String _selectedDevice = "Devices"; // 默认显示文本
  List<String> _deviceNames = []; // 存储设备名称

  @override
  void initState() {
    super.initState();
    _fetchUsageHistory(); // 调用API获取数据
    _fetchDeviceNames(); // 调用API获取设备名称
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
        return UsageData(
          DateFormat('dd/MM/yyyy').format(DateTime.parse(item['startTime'])),
          DateFormat('hh:mm a').format(DateTime.parse(item['startTime'])),
          item['device']['name'],
          '${item['usageTime']} mins',
        );
      }).toList();

      setState(() {
        _usageHistory = fetchedData;
        _allUsageHistory = fetchedData; // 保存所有数据
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
      List<String> deviceNames = data.map<String>((item) => item['name']).toList();

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
      _selectedDevice = "Devices"; // 重置设备选择
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
      _selectedDevice = deviceName; // 更新按钮显示的设备名
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
      _usageHistory = _allUsageHistory; // 重置为所有记录
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
                    _showDevicePicker(); // 显示设备选择器
                  } else {
                    _resetDeviceSearch(); // 重置搜索
                  }
                },
                child: Text(_selectedDevice), // 显示当前选择的设备或"Devices"
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isSearchByDateActive = false;
                    _isSearchByDeviceActive = false;
                    _selectedDevice = "Devices"; // 重置设备选择
                    _usageHistory = _allUsageHistory; // 重置为所有记录
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
                    'Device: ${data.device}\nDuration: ${data.duration}',
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
