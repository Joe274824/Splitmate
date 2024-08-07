import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'models/bill_data.dart';

class TenantScreen extends StatelessWidget {
  final bool isPrincipleTenant;
  TenantScreen({required this.isPrincipleTenant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
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
            ElevatedButton(
              onPressed: () {
                // Add download bill logic here
              },
              child: Text('Download Bill PDF'),
            ),
            if (isPrincipleTenant) ...[
              ElevatedButton(
                onPressed: () {
                  // Add upload bill logic here
                },
                child: Text('Upload Bill PDF'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Water Price per Unit'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Electricity Price per Unit'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Gas Price per Unit'),
                keyboardType: TextInputType.number,
              ),
            ]
          ],
        ),
      ),
    );
  }

  List<BillData> getBillData() {
    return [
      BillData('Jan', 30, 50, 20, 100),
      BillData('Feb', 28, 45, 22, 95),
      BillData('Mar', 32, 48, 25, 105),
    ];
  }
}
