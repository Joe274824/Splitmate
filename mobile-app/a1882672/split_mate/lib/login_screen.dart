import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_property_screen.dart';
import 'apply_property_screen.dart';
import 'tenant_screen.dart';
import 'register_screen.dart';
import 'ble_scan_screen.dart';

class LoginScreen extends StatelessWidget {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    final Map<String, dynamic> requestBody = {
      'username': _nameController.text,
      'password': _passwordController.text,
    };

    print("Sending request to server: $requestBody");

    final response = await http.post(
      Uri.parse('http://13.55.123.136:8080/api/login'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: jsonEncode(requestBody),
    );

    print("Server response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      // Correct the invalid response format before parsing
      String correctedResponse = response.body.replaceAllMapped(
        RegExp(r'(\w+)=([^,}]+)'),
            (Match m) => '"${m.group(1)}":"${m.group(2)}"',
      );

      // Ensure the entire response is wrapped in braces if not already
      if (!correctedResponse.startsWith('{')) {
        correctedResponse = '{$correctedResponse}';
      }

      print("Corrected response: $correctedResponse");

      final responseData = jsonDecode(correctedResponse);

      bool isLandlord = responseData['usertype'] == '1';
      String token = responseData['token'];
      String? houseId = responseData['houseId'];

      // Adjust check for "null" string
      if (houseId == 'null') {
        houseId = null;
      }

      if (isLandlord && houseId == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddPropertyScreen(token: token, isLandlord: isLandlord),
          ),
        );
      } else if (!isLandlord && houseId == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApplyPropertyScreen(token: token),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TenantScreen(isLandlord: isLandlord, token: token),
          ),
        );
      }
    } else {
      print('Failed to login');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed, please check your username and password.')),
      );
    }
  }

  // 忘记密码功能
  Future<void> _forgotPassword(BuildContext context) async {
    String? email;

    // 弹出一个输入邮箱的对话框
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Forgot Password'),
          content: TextField(
            decoration: InputDecoration(labelText: 'Enter your email'),
            onChanged: (value) {
              email = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (email != null && email!.isNotEmpty) {
                  Navigator.of(context).pop(); // 关闭对话框
                  _sendForgotPasswordRequest(email!,context);
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // 发送忘记密码请求到服务器
  Future<void> _sendForgotPasswordRequest(String email, BuildContext context) async {
    final response = await http.post(
      Uri.parse('http://13.55.123.136:8080/users/forgot-password?email=$email'),
      headers: {'accept': '*/*'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link has been sent to your email.')),
      );
    } else if (response.statusCode == 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send password reset email: Email address not found.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text('Register'),
            ),
            TextButton(
              onPressed: () => _forgotPassword(context),
              child: Text('Forgot Password?'),
            ),
            SizedBox(height: 20),
            // Add the underlined text for BLE Scan
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BLEScanScreen()), // Navigates to BLEScanScreen
                );
              },
              child: Text(
                'Use with no connection',
                style: TextStyle(
                  decoration: TextDecoration.underline, // Underline the text
                  color: Colors.blue, // Color it like a link
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}