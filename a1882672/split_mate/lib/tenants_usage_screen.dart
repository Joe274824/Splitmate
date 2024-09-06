import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TenantsUsageScreen extends StatefulWidget {
  final String token;

  TenantsUsageScreen({required this.token});

  @override
  _TenantsUsageScreenState createState() => _TenantsUsageScreenState();
}

class _TenantsUsageScreenState extends State<TenantsUsageScreen> {
  List<_UsageData> _chartData = [];
  String _selectedMonth = 'August 2024'; // Default month

  @override
  void initState() {
    super.initState();
    _generateFakeData(); // Generate fake data initially
  }

  void _generateFakeData() {
    // Fake data to simulate tenant usage
    _chartData = [
      _UsageData('Tenant 1', 30, 40, 20, 90),
      _UsageData('Tenant 2', 40, 30, 30, 100),
      _UsageData('Tenant 3', 50, 20, 40, 110),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenants Usage Statistics'),
      ),
      body: SingleChildScrollView( // Enable scrolling
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
                    _generateFakeData(); // Regenerate data for the selected month (simulation)
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
              // Pie Chart for Water Usage
              Text(
                'Water Usage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildPieChart(
                title: 'Water Usage',
                valueMapper: (data) => data.water,
              ),
              SizedBox(height: 20),
              // Pie Chart for Electricity Usage
              Text(
                'Electricity Usage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildPieChart(
                title: 'Electricity Usage',
                valueMapper: (data) => data.electricity,
              ),
              SizedBox(height: 20),
              // Pie Chart for Gas Usage
              Text(
                'Gas Usage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _buildPieChart(
                title: 'Gas Usage',
                valueMapper: (data) => data.gas,
              ),
              SizedBox(height: 20),
              // Pie Chart for Total Usage
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

class _UsageData {
  final String tenant;
  final double water;
  final double electricity;
  final double gas;
  final double total;

  _UsageData(this.tenant, this.water, this.electricity, this.gas, this.total);
}
