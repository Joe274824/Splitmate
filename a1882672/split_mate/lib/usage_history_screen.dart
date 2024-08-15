import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/usage_data.dart';  // For date formatting
class UsageHistoryScreen extends StatefulWidget {
  @override
  _UsageHistoryScreenState createState() => _UsageHistoryScreenState();
}

class _UsageHistoryScreenState extends State<UsageHistoryScreen> {
  int _currentPage = 0;
  bool _isSearchByDateActive = false;
  final int _recordsPerPage = 10;
  List<UsageData> _usageHistory = [];

  @override
  void initState() {
    super.initState();
    _usageHistory = getUsageHistory(); // Fetch usage history
  }

  List<UsageData> _getCurrentPageRecords() {
    int start = _currentPage * _recordsPerPage;
    int end = start + _recordsPerPage;
    end = end > _usageHistory.length ? _usageHistory.length : end;
    return _usageHistory.sublist(start, end);
  }

  void _searchByDate(DateTime selectedDate) {
    setState(() {
      _isSearchByDateActive = true;
      _usageHistory = getUsageHistory().where((record) {
        return record.date == DateFormat('dd/MM/yyyy').format(selectedDate);
      }).toList();
      if (_usageHistory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No usage on selected date')));
      }
      _currentPage = 0;
    });
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
                  setState(() {
                    _isSearchByDateActive = false;
                    _usageHistory = getUsageHistory(); // Reset to all records
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
                  title: Text('${data.date} ${data.startTime} ${data.device}'),
                  subtitle: Text('Duration: ${data.duration}'),
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

  List<UsageData> getUsageHistory() {
    // Replace this with your actual data fetching logic
    return [
      UsageData('19/07/2024', '3:50PM', 'Washing Machine', '3 Hours'),
      UsageData('19/07/2024', '4:50PM', 'Fridge', '3 Hours'),
      UsageData('19/07/2024', '3:50PM', 'Microwave', '3 Hours'),
      UsageData('22/07/2024', '3:50PM', 'Washing Machine', '3 Hours'),
      UsageData('22/07/2024', '4:50PM', 'Fridge', '3 Hours'),
      UsageData('2/207/2024', '3:50PM', 'Microwave', '3 Hours'),
      // Add more records here...
    ];
  }
}
