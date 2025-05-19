import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'dart:convert';

class DownloadBillScreen extends StatefulWidget {
  final String token;

  DownloadBillScreen({required this.token});

  @override
  _DownloadBillScreenState createState() => _DownloadBillScreenState();
}

class _DownloadBillScreenState extends State<DownloadBillScreen> {
  List<Map<String, dynamic>> _bills = [];

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    final url = 'http://13.55.123.136:8080/bills';
    print('Sending GET request to: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        _bills = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch bills')),
      );
    }
  }

  Future<void> _downloadBill(int billId, String fileName) async {
    final url = 'http://13.55.123.136:8080/bills/download/$billId';
    print('Sending GET request to: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body length: ${response.bodyBytes.length}');

    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill downloaded successfully')),
      );

      OpenFile.open(filePath);  // Open the downloaded file

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download bill')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download Bill Document'),
      ),
      body: _bills.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _bills.length,
        itemBuilder: (context, index) {
          final bill = _bills[index];
          return ListTile(
            title: Text(bill['fileName']),
            trailing: ElevatedButton(
              onPressed: () => _downloadBill(bill['id'], bill['fileName']),
              child: Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,  // Corrected parameter
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          );
        },
      ),
    );
  }
}
