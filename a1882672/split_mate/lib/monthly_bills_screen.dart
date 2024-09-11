import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;

class MonthlyBillsScreen extends StatefulWidget {
  final String token;

  MonthlyBillsScreen({required this.token});

  @override
  _MonthlyBillsScreenState createState() => _MonthlyBillsScreenState();
}

class _MonthlyBillsScreenState extends State<MonthlyBillsScreen> {
  List<BillData> _billData = [];

  // get http => null;

  @override
  void initState() {
    super.initState();
    _fetchUsageData();
  }

  // Fetch water, gas, and electricity usage data and update the chart
  Future<void> _fetchUsageData() async {
    final now = DateTime.now();
    final List<BillData> fetchedData = [];

    // Loop to get usage data for the last three months
    for (int i = 2; i >= 0; i--) {
      DateTime targetMonth = DateTime(now.year, now.month - i);
      final response = await http.get(
        Uri.parse('http://120.26.0.31:8080/deviceUsages/userOneMonth?month=${targetMonth.month}&year=${targetMonth.year}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        double totalElectricityUsage = 0;
        double totalWaterUsage = 0;
        double totalGasUsage = 0;

        for (var item in data) {
          String category = item['device']['category'];
          int usageTime = item['usageTime'];

          // Categorize usage based on the category field
          if (category == 'elec') {
            totalElectricityUsage += usageTime;
          } else if (category == 'water') {
            totalWaterUsage += usageTime;
          } else if (category == 'gas') {
            totalGasUsage += usageTime;
          }
        }

        double electricityBill = totalElectricityUsage * 0.1;
        double waterBill = totalWaterUsage * 0.1;
        double gasBill = totalGasUsage * 0.1;
        double totalBill = electricityBill + waterBill + gasBill;

        // Add the data for the current month
        fetchedData.add(BillData(
          DateFormat('MMM').format(targetMonth), // Month name, e.g., Jan, Feb
          electricityBill,
          waterBill,
          gasBill,
          totalBill,
        ));
      } else {
        print('Failed to fetch usage data for ${targetMonth.month}');
      }
    }

    setState(() {
      _billData = fetchedData;  // Update the UI with the new bill data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Bills'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _billData.isEmpty
            ? Center(child: CircularProgressIndicator())
            : SfCartesianChart(
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Monthly Bills'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <ChartSeries>[
            LineSeries<BillData, String>(
              dataSource: _billData,
              xValueMapper: (BillData bills, _) => bills.month,
              yValueMapper: (BillData bills, _) => bills.electricityBill,
              name: 'Electricity Bill',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
            LineSeries<BillData, String>(
              dataSource: _billData,
              xValueMapper: (BillData bills, _) => bills.month,
              yValueMapper: (BillData bills, _) => bills.waterBill,
              name: 'Water Bill',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
            LineSeries<BillData, String>(
              dataSource: _billData,
              xValueMapper: (BillData bills, _) => bills.month,
              yValueMapper: (BillData bills, _) => bills.gasBill,
              name: 'Gas Bill',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
            LineSeries<BillData, String>(
              dataSource: _billData,
              xValueMapper: (BillData bills, _) => bills.month,
              yValueMapper: (BillData bills, _) => bills.totalBill,
              name: 'Total Bill',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
          ],
        ),
      ),
    );
  }
}

// Model class for bill data
class BillData {
  final String month;
  final double electricityBill;
  final double waterBill;
  final double gasBill;
  final double totalBill;

  BillData(this.month, this.electricityBill, this.waterBill, this.gasBill, this.totalBill);
}
