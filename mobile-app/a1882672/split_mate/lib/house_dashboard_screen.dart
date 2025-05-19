import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_property_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class HouseDashboardScreen extends StatefulWidget {
  final String token;

  HouseDashboardScreen({required this.token});

  @override
  _HouseDashboardScreenState createState() => _HouseDashboardScreenState();
}

class _HouseDashboardScreenState extends State<HouseDashboardScreen> {
  List<dynamic> _properties = [];
  List<dynamic> _tenants = [];
  List<dynamic> _applications = [];
  String? _selectedProperty;
  bool _isLoading = true;
  String? _selectedMonth;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }
  Future<void> _handleApplication(int applicationId, bool isAccepted) async {
    // Fetch the rental application details by ID
    final getResponse = await http.get(
      Uri.parse('http://13.55.123.136:8080/application/$applicationId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (getResponse.statusCode == 200) {
      final application = jsonDecode(getResponse.body);

      // Remove 'applicationDate' from response body
      application.remove('applicationDate');

      // Set the application status: 1 for accept, 2 for decline
      application['status'] = isAccepted ? 1 : 2;

      // Send updated application to the server
      final postResponse = await http.post(
        Uri.parse('http://13.55.123.136:8080/application'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(application),
      );

      if (postResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application processed successfully')));
        _fetchApplications(_selectedProperty!); // Refresh the application list after processing
      } else {
        print('Failed to update application');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update application')));
      }
    } else {
      print('Failed to fetch application details');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch application details')));
    }
  }

  Future<void> _fetchProperties() async {
    final response = await http.get(
      Uri.parse('http://13.55.123.136:8080/api/house/houses'),
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
      print('Failed to fetch property data');
    }
  }

  Future<void> _fetchTenants(String houseId) async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('http://13.55.123.136:8080/api/house/tenants/$houseId'),
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
      print('Failed to fetch tenant data');
    }

    _fetchApplications(houseId);
  }

  Future<void> _fetchApplications(String houseId) async {
    final response = await http.get(
      Uri.parse('http://13.55.123.136:8080/application/house/$houseId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _applications = data
            .where((application) => application['rentalApplication']['houseId'].toString() == houseId && application['rentalApplication']['status'] == 0)
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Failed to fetch applications');
    }
  }

  Future<void> _removeTenant(int tenantId, String houseId) async {
    final response = await http.delete(
      Uri.parse('http://13.55.123.136:8080/api/house/tenants/$houseId/$tenantId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tenant removed successfully')));
      _fetchTenants(houseId); // Refresh tenant list
    } else {
      print('Failed to remove tenant');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove tenant')));
    }
  }

  Future<void> _uploadBill() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);

    if (result != null) {
      PlatformFile file = result.files.first;

      if (_selectedMonth != null && _selectedYear != null) {
        // Check file type
        if (file.extension != null && (file.extension == 'pdf' || file.extension == 'jpg' || file.extension == 'jpeg' || file.extension == 'png')) {
          // Prepare file for upload
          File uploadFile = File(file.path!);
          String houseId = _selectedProperty ?? '';
          String userId = '1'; // Replace with actual user ID if available

          var request = http.MultipartRequest(
            'POST',
            Uri.parse('http://13.55.123.136:8080/bills/upload?houseId=$houseId&userId=$userId'),
          );
          request.headers['Authorization'] = 'Bearer ${widget.token}';
          request.headers['accept'] = '*/*';
          request.files.add(await http.MultipartFile.fromPath('file', uploadFile.path, contentType: MediaType('application', file.extension!)));

          var response = await request.send();

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File uploaded successfully for $_selectedMonth $_selectedYear')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload file')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid file type. Only photos and PDFs are allowed.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select month and year for the bill')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No file selected')));
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      hint: Text('Select Property'),
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
                    child: Text('New Property'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      hint: Text('Month'),
                      value: _selectedMonth,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMonth = newValue;
                        });
                      },
                      items: List.generate(12, (index) => DateFormat('MMMM').format(DateTime(0, index + 1))).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      hint: Text('Year'),
                      value: _selectedYear,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedYear = newValue;
                        });
                      },
                      items: List.generate(5, (index) => (DateTime.now().year - index).toString()).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _uploadBill,
                    child: Text('Upload Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _selectedProperty == null
                  ? Text('Please choose one property')
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Occupants:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _tenants.isEmpty
                      ? Text('No occupants available')
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _tenants.length,
                    itemBuilder: (context, index) {
                      final tenant = _tenants[index];
                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.person, color: Colors.blueAccent),
                          title: Text(tenant['username']),
                          subtitle: Text('ID: ${tenant['id']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeTenant(tenant['id'], _selectedProperty!);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  if (_applications.isNotEmpty) ...[
                    Text(
                      'New Tenant Applications:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        final application = _applications[index];
                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.mail, color: Colors.green),
                            title: Text(application['user']['username']),
                            subtitle: Text('Email: ${application['user']['email']}\nApplied on: ${application['rentalApplication']['applicationDate']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _handleApplication(application['rentalApplication']['id'], true),
                                  child: Text('Accept'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _handleApplication(application['rentalApplication']['id'], false),

                                  child: Text('Decline'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
