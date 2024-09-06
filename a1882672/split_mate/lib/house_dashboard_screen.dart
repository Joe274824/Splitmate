import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HouseDashboardScreen extends StatefulWidget {
  final String token;

  HouseDashboardScreen({required this.token});

  @override
  _HouseDashboardScreenState createState() => _HouseDashboardScreenState();
}

class _HouseDashboardScreenState extends State<HouseDashboardScreen> {
  List<dynamic> properties = [];
  int? selectedHouseId;
  List<dynamic> tenants = [];
  bool isLoadingProperties = true;
  bool isLoadingTenants = false;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    final response = await http.get(
      Uri.parse('http://120.26.0.31:8080/api/house/houses'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        properties = json.decode(response.body);
        isLoadingProperties = false;
      });
    } else {
      setState(() {
        isLoadingProperties = false;
      });
      print('Failed to fetch properties');
    }
  }

  Future<void> _fetchTenants(int houseId) async {
    setState(() {
      isLoadingTenants = true;
    });

    final response = await http.get(
      Uri.parse('http://120.26.0.31:8080/api/house/tenants/$houseId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        tenants = json.decode(response.body);
        isLoadingTenants = false;
      });
    } else {
      setState(() {
        isLoadingTenants = false;
      });
      print('Failed to fetch tenants');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('House Dashboard'),
      ),
      body: isLoadingProperties
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<int>(
              hint: Text('Select Property'),
              value: selectedHouseId,
              items: properties.map<DropdownMenuItem<int>>((property) {
                return DropdownMenuItem<int>(
                  value: property['houseId'],
                  child: Text(property['name']),
                );
              }).toList(),
              onChanged: (int? value) {
                setState(() {
                  selectedHouseId = value;
                  if (selectedHouseId != null) {
                    _fetchTenants(selectedHouseId!);
                  }
                });
              },
            ),
            SizedBox(height: 20),
            if (isLoadingTenants)
              Center(child: CircularProgressIndicator())
            else if (selectedHouseId != null && tenants.isEmpty)
              Center(child: Text('No tenants available for this property'))
            else if (selectedHouseId != null)
                Expanded(
                  child: ListView.builder(
                    itemCount: tenants.length,
                    itemBuilder: (context, index) {
                      final tenant = tenants[index];
                      return ListTile(
                        title: Text(tenant['username']),
                        subtitle: Text(tenant['email']),
                        trailing: ElevatedButton(
                          onPressed: () => _removeTenant(tenant['id']),
                          child: Text('Remove'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeTenant(int tenantId) async {
    // Logic to remove tenant from the house (API logic not implemented)
    print('Removing tenant with ID: $tenantId');
    // Refresh the tenant list
    if (selectedHouseId != null) {
      _fetchTenants(selectedHouseId!);
    }
  }
}
