import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_screen.dart'; // Import RegisterScreen
import 'tenant_screen.dart';

class LoginScreen extends StatelessWidget {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();  // 添加密码输入

  Future<void> _login(BuildContext context) async {
    // 创建请求体
    final Map<String, dynamic> requestBody = {
      'username': _nameController.text,
      'password': _passwordController.text,
    };

    // 打印请求体以便调试
    print("Sending request body: ${jsonEncode(requestBody)}");

    // 发送POST请求到服务器
    final response = await http.post(
      Uri.parse('http://120.26.0.31:8080/api/login'),  // 替换为实际的服务器URL
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    // 打印服务器响应内容以便调试
    print("Received response: ${response.body}");

    // 根据响应处理结果
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      bool isPrincipleTenant = responseData['isPrincipleTenant'] ?? false; // 假设返回数据中有这个字段
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TenantScreen(isPrincipleTenant: isPrincipleTenant),
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
              obscureText: true,  // 隐藏密码输入
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text('Login'),
            ),
            SizedBox(height: 20), // Space between buttons
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()), // Navigate to RegisterScreen
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
