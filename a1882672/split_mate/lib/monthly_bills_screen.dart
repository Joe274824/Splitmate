import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'models/bill_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MonthlyBillsScreen extends StatefulWidget {
  final String token;

  MonthlyBillsScreen({required this.token});

  @override
  _MonthlyBillsScreenState createState() => _MonthlyBillsScreenState();
}

class _MonthlyBillsScreenState extends State<MonthlyBillsScreen> {
  List<BillData> _billData = [];

  @override
  void initState() {
    super.initState();
    _fetchElectricityUsage();
  }

  // 获取电费使用数据并更新图表
  Future<void> _fetchElectricityUsage() async {
    final now = DateTime.now();
    final List<BillData> fetchedData = [];

    // 循环获取过去三个月的电费数据
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
        double totalUsage = 0;

        for (var item in data) {
          totalUsage += item['usageTime'];  // 累加usageTime作为电费
        }

        // 将每月的数据加入fetchedData列表中
        fetchedData.add(BillData(
          DateFormat('MMM').format(targetMonth), // 月份名称，例如Jan, Feb
          totalUsage, // 当前电费
          50, // 假设的水费，您可以根据API或其他数据源更新
          20, // 假设的燃气费
          totalUsage + 50 + 20, // 总费用
        ));
      } else {
        print('Failed to fetch usage data for ${targetMonth.month}');
      }
    }

    setState(() {
      _billData = fetchedData;  // 更新界面上的账单数据
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

class BillData {
  final String month;
  final double electricityBill;
  final double waterBill;
  final double gasBill;
  final double totalBill;

  BillData(this.month, this.electricityBill, this.waterBill, this.gasBill, this.totalBill);
}
