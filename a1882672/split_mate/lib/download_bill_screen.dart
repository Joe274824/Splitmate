import 'package:flutter/material.dart';
class DownloadBillScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download Bill Document'),
      ),
      body: ListView.builder(
        itemCount: billDocuments.length,
        itemBuilder: (context, index) {
          final doc = billDocuments[index];
          return ListTile(
            title: Text(doc.title),
            subtitle: Text(doc.date),
            onTap: () {
              // Add download logic here
              print('Downloading ${doc.title}');
            },
          );
        },
      ),
    );
  }

  final List<BillDocument> billDocuments = [
    BillDocument('Bill January', '01/2024'),
    BillDocument('Bill February', '02/2024'),
    // Add more documents here...
  ];
}

class BillDocument {
  final String title;
  final String date;

  BillDocument(this.title, this.date);
}
