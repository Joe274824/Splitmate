import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';  // Import the LoginScreen


class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  Future<void> _register() async {
    // 创建请求体
    final Map<String, dynamic> requestBody = {
      'id': 0,  // 根据API要求，id可以设置为0，后端会自动生成
      'username': _usernameController.text,
      'password': _passwordController.text,
      'email': _emailController.text,
      'status': 'string',  // 假设status为string，具体值需根据业务需求设置
      'userType': 0,  // 假设0为普通用户
    };

    print("Sending request to server: $requestBody");

    // 发送POST请求到服务器
    final response = await http.post(
      Uri.parse('http://120.26.0.31:8080/users/create'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: jsonEncode(requestBody),
    );

    // 打印服务器响应内容以便调试
    print("Server response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 201) {
      print('User registered successfully');
      // 注册成功后跳转回登录页面
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      print('Failed to register user');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('注册失败，请重试')),
      );
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
