import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class UploadBillsScreen extends StatefulWidget {
  final String token;
  final String propertyId;

  UploadBillsScreen({required this.token, required this.propertyId});

  @override
  _UploadBillsScreenState createState() => _UploadBillsScreenState();
}

class _UploadBillsScreenState extends State<UploadBillsScreen> {
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedCategory;
  File? _selectedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Bills', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Month'),
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
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Year'),
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
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Category'),
              value: _selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              items: ['water', 'gas', 'elec'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Select Bill File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            _selectedFile == null
                ? Text('No file selected', style: TextStyle(fontSize: 16, color: Colors.grey))
                : Text('Selected File: ${_selectedFile!.path.split('/').last}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _selectedFile != null && _selectedMonth != null && _selectedYear != null && _selectedCategory != null
                    ? _uploadBill
                    : null,
                child: Text('Upload Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadBill() async {
    // Upload API implementation goes here
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bill uploaded successfully (mock)')));
  }
}
