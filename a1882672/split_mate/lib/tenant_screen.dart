import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'monthly_bills_screen.dart';
import 'download_bill_screen.dart';
import 'tenants_usage_screen.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';
import 'usage_history_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';

import 'house_dashboard_screen_update.dart';

class TenantScreen extends StatefulWidget {
  final bool isLandlord;
  final String token;

  TenantScreen({required this.isLandlord, required this.token});

  @override
  _TenantScreenState createState() => _TenantScreenState();
}


class _TenantScreenState extends State<TenantScreen> {
  // Define the _buildInfoCard method at the beginning of the class to ensure it's accessible throughout the class
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  String username = '';
  String userRole = '';
  bool isLoading = false;
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
    onEnterTenantScreen(widget.token);
    _fetchData();
  }

  Future<void> _initializeDeviceInfoFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File deviceInfoFile = File('${appDocDir.path}/device_info.json');

    if (!(await deviceInfoFile.exists())) {
      await deviceInfoFile.create();
      await deviceInfoFile.writeAsString(jsonEncode([])); // Initialize with an empty list
    }
  }
  Future<void> _fetchAndUpdateDevices(String token) async {
    try {
      // Get all devices from the server
      final response = await http.get(
        Uri.parse('http://13.55.123.136:8080/devices'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> serverDevices = List<Map<String, dynamic>>.from(jsonDecode(response.body));

        // Read the local device info file
        Directory appDocDir = await getApplicationDocumentsDirectory();
        File deviceInfoFile = File('${appDocDir.path}/device_info.json');
        String localContent = await deviceInfoFile.readAsString();
        List<Map<String, dynamic>> localDevices = List<Map<String, dynamic>>.from(jsonDecode(localContent));

        // Compare server devices with local devices
        if (!_areDevicesEqual(serverDevices, localDevices)) {
          // Update local file if devices are different
          await deviceInfoFile.writeAsString(jsonEncode(serverDevices));
          print('Local device info updated.');
        } else {
          print('No update needed for local device info.');
        }
      } else {
        print('Failed to fetch devices from server');
      }
    } catch (e) {
      print('Error occurred while fetching or updating devices: $e');
    }
  }

  // Helper function to compare two lists of devices
  bool _areDevicesEqual(List<Map<String, dynamic>> serverDevices, List<Map<String, dynamic>> localDevices) {
    if (serverDevices.length != localDevices.length) {
      return false;
    }
    for (int i = 0; i < serverDevices.length; i++) {
      if (!const DeepCollectionEquality().equals(serverDevices[i], localDevices[i])) {
        return false;
      }
    }
    return true;
  }
  // Method to print the device info file content
  Future<void> printDeviceInfoFile() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File deviceInfoFile = File('${appDocDir.path}/device_info.json');
      if (await deviceInfoFile.exists()) {
        String content = await deviceInfoFile.readAsString();
        print('Device Info File Content:\n$content');
      } else {
        print('Device info file does not exist.');
      }
    } catch (e) {
      print('Error occurred while reading device info file: $e');
    }
  }

  // Method to be called when entering the tenant screen
  Future<void> onEnterTenantScreen(String token) async {
    await _initializeDeviceInfoFile();
    await _fetchAndUpdateDevices(token);
    await printDeviceInfoFile();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _fetchUserDetails();
      await _fetchUsagePrices();
      _calculateNextBillDate();
    } catch (e) {
      _showErrorDialog();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch user details
  Future<void> _fetchUserDetails() async {
    final response = await http.get(
      Uri.parse('http://13.55.123.136:8080/users/findUser'),
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
      });
    } else {
      throw Exception('Failed to fetch user details');
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
      Uri.parse('http://13.55.123.136:8080/deviceUsages/userOneMonth?month=${now.month}&year=${now.year}'),
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
      throw Exception('Failed to fetch usage data');
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

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Cannot connect to server'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  Future<String> getDeviceInfoContent() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File deviceInfoFile = File('${appDocDir.path}/device_info.json');
      if (await deviceInfoFile.exists()) {
        String content = await deviceInfoFile.readAsString();
        return content;
      } else {
        print('Device info file does not exist.');
        return 'Device info file does not exist.';
      }
    } catch (e) {
      print('Error occurred while reading device info file: $e');
      return 'Error occurred while reading device info file: $e';
    }
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
        child: ListView(
          children: [
            Text(
              'Next Bill Date: ${DateFormat('yyyy-MM-dd').format(nextBillDate)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Current Price:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildInfoCard(
              'Current Water Price',
              '\$${waterUsage.toStringAsFixed(2)}',
              Icons.water,
              Colors.blue,
            ),
            _buildInfoCard(
              'Current Electricity Price',
              '\$${electricityUsage.toStringAsFixed(2)}',
              Icons.electric_bolt,
              Colors.yellow,
            ),
            _buildInfoCard(
              'Current Gas Price',
              '\$${gasUsage.toStringAsFixed(2)}',
              Icons.fireplace,
              Colors.orange,
            ),
            Divider(),
            Text(
              'Estimated Bill for this Cycle:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildInfoCard(
              'Water (Estimated)',
              '\$${estimatedWater.toStringAsFixed(2)}',
              Icons.water_drop_outlined,
              Colors.lightBlue,
            ),
            _buildInfoCard(
              'Electricity (Estimated)',
              '\$${estimatedElectricity.toStringAsFixed(2)}',
              Icons.bolt,
              Colors.amber,
            ),
            _buildInfoCard(
              'Gas (Estimated)',
              '\$${estimatedGas.toStringAsFixed(2)}',
              Icons.local_fire_department,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}