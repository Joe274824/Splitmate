import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'models/bill_data.dart';
import 'monthly_bills_screen.dart';
import 'download_bill_screen.dart';
import 'usage_history_screen.dart';

class TenantScreen extends StatelessWidget {
  final bool isPrincipleTenant;
  final String token;  // 新增：接受 token

  TenantScreen({required this.isPrincipleTenant, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  // 调整为竖向排列
          crossAxisAlignment: CrossAxisAlignment.stretch, // 使按钮在水平上占满可用空间
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
                  MaterialPageRoute(
                    builder: (context) => DownloadBillScreen(token: token), // 传入 token
                  ),
                );
              },
              child: Text('Download Bill Document'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UsageHistoryScreen(token: token), // 传入 token
                  ),
                );
              },
              child: Text('Usage History'),
            ),
            if (isPrincipleTenant)  // 仅当是主租户时显示上传按钮
              ElevatedButton(
                onPressed: () {
                  // 上传文档功能（API尚未完成）
                },
                child: Text('Upload PDF Document'),
              ),
          ],
        ),
      ),
    );
  }
}
