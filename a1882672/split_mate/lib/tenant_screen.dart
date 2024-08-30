import 'package:flutter/material.dart';
import 'monthly_bills_screen.dart';
import 'download_bill_screen.dart';
import 'usage_history_screen.dart';

class TenantScreen extends StatelessWidget {
  final bool isPrincipleTenant;
  final String token;

  TenantScreen({required this.isPrincipleTenant, required this.token});

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent,
      padding: EdgeInsets.symmetric(vertical: 20),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  // Center the buttons vertically
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons full width
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MonthlyBillsScreen()),
                );
              },
              child: Text('Monthly Bills'),
              style: buttonStyle,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DownloadBillScreen(token: token), // Pass the token
                  ),
                );
              },
              child: Text('Download Bill Document'),
              style: buttonStyle,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UsageHistoryScreen(token: token), // Pass the token
                  ),
                );
              },
              child: Text('Usage History'),
              style: buttonStyle,
            ),
            if (isPrincipleTenant)  // Show this button only for the principle tenant
              Column(
                children: [
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Logic to upload PDF (API not yet implemented)
                    },
                    child: Text('Upload PDF Document'),
                    style: buttonStyle,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
