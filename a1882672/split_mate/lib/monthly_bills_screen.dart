import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'models/bill_data.dart';
class MonthlyBillsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Bills'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SfCartesianChart(
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Monthly Bills'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <ChartSeries>[
            LineSeries<BillData, String>(
              dataSource: getBillData(),
              xValueMapper: (BillData bills, _) => bills.month,
              yValueMapper: (BillData bills, _) => bills.waterBill,
              name: 'Water Bill',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
            LineSeries<BillData, String>(
              dataSource: getBillData(),
              xValueMapper: (BillData bills, _) => bills.month,
              yValueMapper: (BillData bills, _) => bills.electricityBill,
              name: 'Electricity Bill',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
            LineSeries<BillData, String>(
              dataSource: getBillData(),
              xValueMapper: (BillData bills, _) => bills.month,
              yValueMapper: (BillData bills, _) => bills.gasBill,
              name: 'Gas Bill',
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
            LineSeries<BillData, String>(
              dataSource: getBillData(),
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

  List<BillData> getBillData() {
    // Mock data for demonstration
    return [
      BillData('Jan', 30, 50, 20, 100),
      BillData('Feb', 28, 45, 22, 95),
      BillData('Mar', 32, 48, 25, 105),
    ];
  }
}
