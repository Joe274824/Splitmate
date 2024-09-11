import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_property_screen.dart';

class HouseDashboardScreen extends StatefulWidget {
  final String token;

  HouseDashboardScreen({required this.token});

  @override
  _HouseDashboardScreenState createState() => _HouseDashboardScreenState();
}

class _HouseDashboardScreenState extends State<HouseDashboardScreen> {
  List<dynamic> _properties = [];
  List<dynamic> _tenants = [];
  String? _selectedProperty;
  bool _isLoading = true;

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
        _properties = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print('获取房产数据失败');
    }
  }

  Future<void> _fetchTenants(String houseId) async {
    final response = await http.get(
      Uri.parse('http://120.26.0.31:8080/api/house/tenants/$houseId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _tenants = jsonDecode(response.body);
      });
    } else {
      print('获取租户数据失败');
    }
  }

  Future<void> _removeTenant(int tenantId, String houseId) async {
    final response = await http.delete(
      Uri.parse('http://120.26.0.31:8080/api/house/tenants/$houseId/$tenantId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('租户删除成功')));
      _fetchTenants(houseId); // 刷新租户列表
    } else {
      print('删除租户失败');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除租户失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('House Dashboard'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text('property'),
                    value: _selectedProperty,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedProperty = newValue!;
                        _fetchTenants(_selectedProperty!);
                      });
                    },
                    items: _properties.map<DropdownMenuItem<String>>((property) {
                      return DropdownMenuItem<String>(
                        value: property['houseId'].toString(),
                        child: Text(property['name']),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPropertyScreen(
                          token: widget.token,
                          isLandlord: true,
                        ),
                      ),
                    );
                  },
                  child: Text('New property'),
                ),
              ],
            ),
            SizedBox(height: 20),
            _selectedProperty == null
                ? Text('Please choose one property')
                : Expanded(
              child: ListView.builder(
                itemCount: _tenants.length,
                itemBuilder: (context, index) {
                  final tenant = _tenants[index];
                  return ListTile(
                    title: Text(tenant['username']),
                    subtitle: Text('ID: ${tenant['id']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _removeTenant(tenant['id'], _selectedProperty!);
                      },
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
}
