import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApplicationsScreen extends StatefulWidget {
  final String token;
  final String propertyId;

  ApplicationsScreen({required this.token, required this.propertyId});

  @override
  _ApplicationsScreenState createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchApplications(widget.propertyId);
  }

  Future<void> _fetchApplications(String houseId) async {
    setState(() {
      _isLoading = true;
    });

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
    } else if (response.statusCode == 404) {
      setState(() {
        _applications = [];
        _isLoading = false;
      });
      print("There's no pending applications for the house");
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Failed to fetch applications');
    }
  }

  Future<void> _handleApplication(int applicationId, bool isAccepted) async {
    setState(() {
      _isProcessing = true;
    });

    final getResponse = await http.get(
      Uri.parse('http://13.55.123.136:8080/application/$applicationId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'accept': '*/*',
      },
    );

    if (getResponse.statusCode == 200) {
      final application = jsonDecode(getResponse.body);

      application.remove('applicationDate');
      application['status'] = isAccepted ? 1 : 2;

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
        await _fetchApplications(widget.propertyId);
      } else {
        print('Failed to update application');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update application')));
      }
    } else {
      print('Failed to fetch application details');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch application details')));
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Applications'),
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _applications.isEmpty
              ? Center(child: Text('No applications available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)))
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: _applications.length,
              itemBuilder: (context, index) {
                final application = _applications[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.mail, color: Colors.green),
                    title: Text(
                      application['user']['username'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${application['user']['email']}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        SizedBox(height: 4),
                        Text('Applied on: ${application['rentalApplication']['applicationDate']}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.blue),
                        onPressed: () => _handleApplication(application['rentalApplication']['id'], true),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _handleApplication(application['rentalApplication']['id'], false),
                      ),
                    ],
                  ),
                ),
                );
              },
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
