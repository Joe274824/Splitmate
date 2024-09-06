import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_property_screen.dart';
import 'apply_property_screen.dart';
import 'tenant_screen.dart';
import 'register_screen.dart';

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
      Uri.parse('http://120.26.0.31:8080/api/login'),
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
        SnackBar(content: Text('登录失败，请检查用户名和密码')),
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
                  MaterialPageRoute(builder: (context) => RegisterScreen()),  // 添加注册按钮
                );
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
