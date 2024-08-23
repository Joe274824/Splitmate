import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_screen.dart';
import 'tenant_screen.dart';



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
      // 将不规范的JSON字符串替换成标准格式
      final correctedJson = response.body
          .replaceAllMapped(RegExp(r'(\w+)=([^,}]+)'), (match) {
        return '"${match.group(1)}":"${match.group(2)}"';
      });

      print("Corrected response: $correctedJson");

      final responseData = jsonDecode(correctedJson);

      bool isPrincipleTenant = responseData['usertype'] == '1';
      String token = responseData['token'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TenantScreen(
            isPrincipleTenant: isPrincipleTenant,
            token: token,
          ),
        ),
      );
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
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
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
