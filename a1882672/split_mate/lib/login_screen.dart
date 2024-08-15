import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_screen.dart'; // Import RegisterScreen
import 'tenant_screen.dart'; // Import the existing TenantScreen class

class LoginScreen extends StatelessWidget {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();  // 添加密码输入

  Future<void> _login(BuildContext context) async {
    // 拼接请求的URL
    final url =
        'http://120.26.0.31:8080/api/login?username=${_nameController.text}&password=${_passwordController.text}';

    // 发送POST请求到服务器
    final response = await http.post(Uri.parse(url));

    // 打印服务器响应内容以便调试
    print("Received response: ${response.body}");

    // 根据响应处理结果
    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TenantScreen(isPrincipleTenant: false), // 假设登录用户不是主租户
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
