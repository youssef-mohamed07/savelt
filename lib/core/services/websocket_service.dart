import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/auth_api_service.dart';

/// WebSocket service — connects to the backend analytics WebSocket.
/// Sends userId as query param so backend sends only this user's analytics.
class WebSocketService {
  static final WebSocketService instance = WebSocketService._internal();
  WebSocketService._internal();

  WebSocket? _socket;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  final _analyticsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get analyticsStream =>
      _analyticsController.stream;

  bool get isConnected => _isConnected;

  String get _wsUrl {
    // Derive WebSocket host from ApiConfig.baseUrl (same host, port 3002)
    final httpUrl = ApiConfig.baseUrl;
    final host = httpUrl
        .replaceFirst(RegExp(r'https?://'), '')
        .split(':')[0];
    final userId = AuthApiService.instance.currentUser?.uid ?? '';
    final base = 'ws://$host:3002';
    return userId.isNotEmpty ? '$base?userId=$userId' : base;
  }

  Future<void> connect() async {
    if (_isConnected) return;
    try {
      _socket = await WebSocket.connect(_wsUrl)
          .timeout(const Duration(seconds: 5));
      _isConnected = true;
      print('🔌 [WS] Connected to $_wsUrl');

      _socket!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      print('⚠️ [WS] Connection failed: $e — will retry in 10s');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['type'] == 'analytics_update') {
        final payload = data['data'] as Map<String, dynamic>;
        print('📊 [WS] Analytics update received');
        _analyticsController.add(payload);
      }
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  void _onError(dynamic error) {
    print('⚠️ [WS] Error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    print('🔌 [WS] Disconnected');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), connect);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.close();
    _isConnected = false;
    print('🔌 [WS] Manually disconnected');
  }

  void dispose() {
    disconnect();
    _analyticsController.close();
  }
}
