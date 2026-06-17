import 'package:flutter/material.dart';
import '../../../../core/services/auth_api_service.dart';
import 'dart:convert';

class TokenBackendPage extends StatefulWidget {
  @override
  _TokenBackendPageState createState() => _TokenBackendPageState();
}

class _TokenBackendPageState extends State<TokenBackendPage> {
  String? _token;
  String _backendResponse = "";
  final _authService = AuthApiService.instance;

  Future<void> _sendTokenToBackend() async {
    try {
      final token = await _authService.getToken();

      setState(() {
        _token = token;
      });

      if (token != null) {
        print("Auth Token: $token");
        
        setState(() {
          _backendResponse = "Token retrieved successfully!";
        });
      } else {
        setState(() {
          _backendResponse = "No token available";
        });
      }
    } catch (e) {
      setState(() {
        _backendResponse = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Auth Token + Backend")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _sendTokenToBackend,
              child: Text("Get Auth Token"),
            ),
            SizedBox(height: 20),
            SelectableText("Auth Token:\n${_token ?? "Not available"}"),
            SizedBox(height: 20),
            Text("Backend response: $_backendResponse"),
          ],
        ),
      ),
    );
  }
}


