import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  File? _photo1;
  File? _photo2;
  File? _photo3;
  final picker = ImagePicker();

  Future<void> _pickImage(int photoNumber) async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        switch (photoNumber) {
          case 1:
            _photo1 = File(pickedFile.path);
            break;
          case 2:
            _photo2 = File(pickedFile.path);
            break;
          case 3:
            _photo3 = File(pickedFile.path);
            break;
        }
      }
    });
  }

  Future<void> _register() async {
    if (_photo1 == null || _photo2 == null || _photo3 == null) {
      return;
    }

    final request = http.MultipartRequest('POST', Uri.parse('http://localhost:3000/register'))
      ..fields['name'] = _nameController.text
      ..files.add(await http.MultipartFile.fromPath('photo1', _photo1!.path))
      ..files.add(await http.MultipartFile.fromPath('photo2', _photo2!.path))
      ..files.add(await http.MultipartFile.fromPath('photo3', _photo3!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      print('User registered successfully');
    } else {
      print('Failed to register user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _pickImage(1),
                child: Text('Upload Photo 1'),
              ),
              if (_photo1 != null) Image.file(_photo1!),
              ElevatedButton(
                onPressed: () => _pickImage(2),
                child: Text('Upload Photo 2'),
              ),
              if (_photo2 != null) Image.file(_photo2!),
              ElevatedButton(
                onPressed: () => _pickImage(3),
                child: Text('Upload Photo 3'),
              ),
              if (_photo3 != null) Image.file(_photo3!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
