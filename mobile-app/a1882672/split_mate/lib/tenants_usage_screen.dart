import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TenantsUsageScreen extends StatefulWidget {
  final String token;

  TenantsUsageScreen({required this.token});

  @override
  _TenantsUsageScreenState createState() => _TenantsUsageScreenState();
}

class _TenantsUsageScreenState extends State<TenantsUsageScreen> {
  List<_UsageData> _chartData = [];
  String _selectedMonth = 'September 2024'; // Default month
  late int selectedMonthNumber;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    _parseSelectedMonth(_selectedMonth); // Parse the default month
    _fetchUsageData(); // Fetch real data on init
  }

  // Function to parse the selected month into year and month number
  void _parseSelectedMonth(String selectedMonth) {
    final DateTime parsedDate = DateFormat('MMMM yyyy').parse(selectedMonth);
    selectedMonthNumber = parsedDate.month;
    selectedYear = parsedDate.year;
  }

  // Fetch data based on selected month and year
  Future<void> _fetchUsageData() async {
    try {
      final response = await http.get(
        Uri.parse('http://13.55.123.136:8080/deviceUsages/AllUsageForMT?month=$selectedMonthNumber&year=$selectedYear'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        Map<String, _UsageData> tenantUsageMap = {};

        // Parse response and aggregate usage based on category
        for (var record in data) {
          String tenantName = record['user']['username'];
          double usageTime = record['usageTime'].toDouble();
          String category = record['device']['category'];

          if (tenantUsageMap.containsKey(tenantName)) {
            _UsageData usageData = tenantUsageMap[tenantName]!;

            if (category == 'elec') {
              usageData.electricity += usageTime;
            } else if (category == 'water') {
              usageData.water += usageTime;
            } else if (category == 'gas') {
              usageData.gas += usageTime;
            }
            usageData.total += usageTime;
          } else {
            tenantUsageMap[tenantName] = _UsageData(
              tenantName,
              category == 'water' ? usageTime : 0,
              category == 'elec' ? usageTime : 0,
              category == 'gas' ? usageTime : 0,
              usageTime, // Total usage
            );
          }
        }

        setState(() {
          _chartData = tenantUsageMap.values.toList();
        });
      } else {
        print('Failed to fetch usage data');
      }
    } catch (e) {
      print('Error fetching usage data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenants Usage Statistics'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Selection Dropdown
              DropdownButton<String>(
                value: _selectedMonth,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMonth = newValue!;
                    _parseSelectedMonth(_selectedMonth); // Update month and year
                    _fetchUsageData(); // Fetch new data
                  });
                },
                items: <String>['July 2024', 'August 2024', 'September 2024']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              // Electricity Usage Pie Chart
              Text(
                'Electricity Usage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildPieChart(
                title: 'Electricity Usage',
                valueMapper: (data) => data.electricity,
              ),
              SizedBox(height: 20),
              // Water Usage Pie Chart
              Text(
                'Water Usage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildPieChart(
                title: 'Water Usage',
                valueMapper: (data) => data.water,
              ),
              SizedBox(height: 20),
              // Gas Usage Pie Chart
              Text(
                'Gas Usage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildPieChart(
                title: 'Gas Usage',
                valueMapper: (data) => data.gas,
              ),
              SizedBox(height: 20),
              // Total Usage Pie Chart
              Text(
                'Total Usage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildPieChart(
                title: 'Total Usage',
                valueMapper: (data) => data.total,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build Pie Chart
  Widget _buildPieChart({
    required String title,
    required num Function(_UsageData) valueMapper,
  }) {
    return SfCircularChart(
      title: ChartTitle(text: title),
      legend: Legend(isVisible: true),
      series: <CircularSeries>[
        PieSeries<_UsageData, String>(
          dataSource: _chartData,
          xValueMapper: (_UsageData data, _) => data.tenant,
          yValueMapper: (data, _) => valueMapper(data),
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

// Data Model
class _UsageData {
  final String tenant;
  double water;
  double electricity;
  double gas;
  double total;

  _UsageData(this.tenant, this.water, this.electricity, this.gas, this.total);
}
