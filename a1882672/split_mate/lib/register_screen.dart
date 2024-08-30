import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  File? _photo1;
  File? _photo2;
  File? _photo3;
  final picker = ImagePicker();

  Future<void> _pickImage(int photoNumber) async {
    final XFile? pickedFile = await showDialog<XFile>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose an option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a photo'),
                onTap: () async {
                  final XFile? file = await picker.pickImage(
                      source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
                  Navigator.of(context).pop(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () async {
                  final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.of(context).pop(file);
                },
              ),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Set the photo immediately below the upload button
      setState(() {
        switch (photoNumber) {
          case 1:
            _photo1 = imageFile;
            break;
          case 2:
            _photo2 = imageFile;
            break;
          case 3:
            _photo3 = imageFile;
            break;
        }
      });

      bool faceDetected = await _detectFaces(imageFile);

      if (!faceDetected) {
        _showErrorDialog("No face or multiple faces detected in the image. Please upload a valid photo.");
      }
    }
  }

  Future<bool> _detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faceDetector = FaceDetector(options: FaceDetectorOptions());
    final List<Face> faces = await faceDetector.processImage(inputImage);

    return faces.length == 1;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
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
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 20),
              _buildPhotoUploadSection(1, _photo1),
              SizedBox(height: 20),
              _buildPhotoUploadSection(2, _photo2),
              SizedBox(height: 20),
              _buildPhotoUploadSection(3, _photo3),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Handle the registration process
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection(int photoNumber, File? photoFile) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _pickImage(photoNumber),
          child: Text('Upload Photo $photoNumber'),
        ),
        if (photoFile != null) Image.file(photoFile),
      ],
    );
  }
}
