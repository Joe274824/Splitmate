import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

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

    // 打印人脸检测的结果
    print('Detected ${faces.length} face(s)');
    for (var face in faces) {
      print('Face bounding box: ${face.boundingBox}');
      print('Head Euler Angle Y: ${face.headEulerAngleY}');
      print('Head Euler Angle Z: ${face.headEulerAngleZ}');
    }

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
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
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

    print('Request body: ' + jsonEncode(requestBody));
    final response = await http.post(
      Uri.parse('http://120.26.0.31:8080/users/create'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: jsonEncode(requestBody),
    );
    print('Response status: ' + response.statusCode.toString());
    print('Response body: ' + response.body);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful! Uploading photos...')),
      );
      await _uploadPhotos();
      Navigator.pop(context);
    } else {
      _showErrorDialog("Registration failed. Please try again.");
    }
  }

  Future<void> _uploadPhotos() async {
    if (_photo1 == null || _photo2 == null || _photo3 == null) {
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://120.26.0.31:8080/users/uploadPhotos'),
    );
    request.headers['accept'] = '*/*';
    request.headers['Content-Type'] = 'multipart/form-data';
    request.files.add(await http.MultipartFile.fromPath('photo1', _photo1!.path, contentType: MediaType('image', 'jpeg')));
    request.files.add(await http.MultipartFile.fromPath('photo2', _photo2!.path, contentType: MediaType('image', 'jpeg')));
    request.files.add(await http.MultipartFile.fromPath('photo3', _photo3!.path, contentType: MediaType('image', 'jpeg')));
    request.fields['username'] = _usernameController.text;

    // 打印上传请求的请求体
    print('Uploading photos for username: ${_usernameController.text}');
    print('Photo 1 path: ${_photo1!.path}');
    print('Photo 2 path: ${_photo2!.path}');
    print('Photo 3 path: ${_photo3!.path}');

    var response = await request.send();

    // 打印服务器返回的响应体
    var responseBody = await response.stream.bytesToString();
    print('Response status: ${response.statusCode}');
    print('Response body: $responseBody');

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photos uploaded successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload photos')));
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
