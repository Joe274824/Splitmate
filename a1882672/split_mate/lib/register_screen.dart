import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLandlord = false; // Option for whether the user is a landlord
  final _formKey = GlobalKey<FormState>();  // Form validation key
  bool _isEmailValid = true;  // Email validation state

  File? _photo1;
  File? _photo2;
  File? _photo3;
  bool _photo1Passed = false;
  bool _photo2Passed = false;
  bool _photo3Passed = false;

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

      setState(() {
        switch (photoNumber) {
          case 1:
            _photo1Passed = faceDetected;
            break;
          case 2:
            _photo2Passed = faceDetected;
            break;
          case 3:
            _photo3Passed = faceDetected;
            break;
        }
      });

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

  // Email validation function
  void _validateEmail(String value) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _isEmailValid = emailRegExp.hasMatch(value);
    });
  }

  Future<void> _registerUser() async {
    // Check if all photos are uploaded and passed face detection
    if (_photo1 == null || _photo2 == null || _photo3 == null) {
      _showErrorDialog("Please upload all three photos.");
      return;
    }
    if (!_photo1Passed || !_photo2Passed || !_photo3Passed) {
      _showErrorDialog("One or more photos did not pass the face detection. Please correct and try again.");
      return;
    }

    if (!_isEmailValid) {
      _showErrorDialog("Please provide a valid email address.");
      return;
    }

    // All photos passed validation, proceed with registration
    final Map<String, dynamic> requestBody = {
      'username': _usernameController.text,
      'password': _passwordController.text,
      'email': _emailController.text,
      'userType': _isLandlord ? 1 : 0,
    };

    final response = await http.post(
      Uri.parse('http://120.26.0.31:8080/users/create'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful! Uploading photos...')),
      );
      Navigator.pop(context);
    } else {
      _showErrorDialog("Registration failed. Please try again.");
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_usernameController, 'Username'),
                SizedBox(height: 20),
                _buildTextField(_passwordController, 'Password', isPassword: true),
                SizedBox(height: 20),
                _buildTextField(
                  _emailController,
                  'Email',
                  isEmail: true,
                  errorText: _isEmailValid ? null : 'Invalid email format',
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Are you a landlord?'),
                    Switch(
                      value: _isLandlord,
                      onChanged: (value) {
                        setState(() {
                          _isLandlord = value;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildPhotoUploadSection(1, _photo1),
                SizedBox(height: 20),
                _buildPhotoUploadSection(2, _photo2),
                SizedBox(height: 20),
                _buildPhotoUploadSection(3, _photo3),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _registerUser, // Only call if validation passed
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // A helper function to build standardized input fields
  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false, bool isEmail = false, String? errorText}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: OutlineInputBorder(), // Standard border style
      ),
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      onChanged: isEmail ? (value) => _validateEmail(value) : null, // Email validation
    );
  }

  // Photo upload section with scaling
  Widget _buildPhotoUploadSection(int photoNumber, File? photoFile) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _pickImage(photoNumber),
          child: Text('Upload Photo $photoNumber'),
        ),
        if (photoFile != null)
          SizedBox(
            width: 150, // Fixed width
            height: 150, // Fixed height
            child: Image.file(photoFile), // Scale photo
          ),
      ],
    );
  }
}
