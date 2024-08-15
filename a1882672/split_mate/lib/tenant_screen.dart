import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'models/bill_data.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'monthly_bills_screen.dart';
import 'download_bill_screen.dart';
import 'usage_history_screen.dart';
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MonthlyBillsScreen()),
                );
              },
              child: Text('Monthly Bills'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DownloadBillScreen()),
                );
              },
              child: Text('Download Bill Document'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UsageHistoryScreen()),
                );
              },
              child: Text('Usage History'),
            ),
          ],
        ),
      ),
    );
  }
}
