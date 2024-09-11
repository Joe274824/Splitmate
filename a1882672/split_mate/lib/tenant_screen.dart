import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'monthly_bills_screen.dart';
import 'download_bill_screen.dart';
import 'usage_history_screen.dart';
import 'house_dashboard_screen.dart';
import 'tenants_usage_screen.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class TenantScreen extends StatefulWidget {
  final bool isLandlord;
  final String token;

  TenantScreen({required this.isLandlord, required this.token});

  @override
  _TenantScreenState createState() => _TenantScreenState();
}

class _TenantScreenState extends State<TenantScreen> {
  String username = '';
  String userRole = '';
  bool isLoading = true;
  double electricityUsage = 0;
  double waterUsage = 0;
  double gasUsage = 0;
  DateTime nextBillDate = DateTime.now();
  double estimatedElectricity = 0;
  double estimatedWater = 0;
  double estimatedGas = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchUsagePrices();
    _calculateNextBillDate();
  }

  // Fetch user details
  Future<void> _fetchUserDetails() async {
    final response = await http.get(
      Uri.parse('http://120.26.0.31:8080/users/findUser'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        username = data['username'];
        userRole = widget.isLandlord ? 'Landlord' : 'Tenant';
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('Failed to fetch user details');
    }
  }

  // Calculate next bill date as the last day of the current month
  void _calculateNextBillDate() {
    final now = DateTime.now();
    nextBillDate = DateTime(now.year, now.month + 1, 0); // Last day of the current month
  }

  // Fetch usage data for water, gas, and electricity
  Future<void> _fetchUsagePrices() async {
    final now = DateTime.now();
    final response = await http.get(
      Uri.parse('http://120.26.0.31:8080/deviceUsages/userOneMonth?month=${now.month}&year=${now.year}'),
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

        // Debugging print statement to verify each category and usage time
        print('Category: $category, Usage Time: $usageTime');

        if (category == 'elec') {
          totalElectricityUsage += usageTime;
        } else if (category == 'water') {
          totalWaterUsage += usageTime;
        } else if (category == 'gas') {
          totalGasUsage += usageTime;
        }
      }

      // Log the total usage for debugging
      print('Total Electricity Usage: $totalElectricityUsage');
      print('Total Water Usage: $totalWaterUsage');
      print('Total Gas Usage: $totalGasUsage');

      setState(() {
        electricityUsage = totalElectricityUsage * 0.1;
        waterUsage = totalWaterUsage * 0.1;
        gasUsage = totalGasUsage * 0.1;

        _calculateEstimatedPrices(now);
      });
    } else {
      print('Failed to fetch usage data');
    }
  }

  // Calculate estimated prices for electricity, water, and gas
  void _calculateEstimatedPrices(DateTime now) {
    int pastDays = now.day; // Days passed in the current month
    int totalDays = nextBillDate.day; // Total days in the current month

    estimatedElectricity = (electricityUsage / pastDays) * totalDays;
    estimatedWater = (waterUsage / pastDays) * totalDays;
    estimatedGas = (gasUsage / pastDays) * totalDays;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Upcoming Bills'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    userRole,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Upcoming Bills'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TenantScreen(
                      isLandlord: widget.isLandlord,
                      token: widget.token,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.assessment),
              title: Text('Monthly Bills'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MonthlyBillsScreen(token: widget.token)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Download Bill'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DownloadBillScreen(token: widget.token)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Usage History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UsageHistoryScreen(token: widget.token)),
                );
              },
            ),
            if (widget.isLandlord) ...[
              ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('House Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HouseDashboardScreen(token: widget.token),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.pie_chart),
                title: Text('Tenants Usage'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TenantsUsageScreen(token: widget.token),
                    ),
                  );
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.login),
              title: Text('Sign out'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Bill Date: ${DateFormat('yyyy-MM-dd').format(nextBillDate)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Current Water Price: \$${waterUsage.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Current Electricity Price: \$${electricityUsage.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Current Gas Price: \$${gasUsage.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Estimated Bill for this Cycle:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Water: \$${estimatedWater.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Electricity: \$${estimatedElectricity.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Gas: \$${estimatedGas.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}