// Voice API Service - New Render API Integration
// Service for Voice & Text Finance Analyzer API
// API: http://10.0.2.2:8000

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

/// Voice API Service for financial text analysis
/// Integrates with the new Render-based API for fast and accurate analysis
class VoiceApiService {
  static final VoiceApiService _instance = VoiceApiService._internal();
  factory VoiceApiService() => _instance;
  VoiceApiService._internal();

  // Analyze text using the Voice API (optimized for Arabic and English)
  Future<VoiceApiResult> analyzeText(String text) async {
    try {
      print('🔍 Analyzing text: $text');
      
      // Prepare the request with proper encoding for Arabic
      final requestBody = {
        'text': text.trim(),
        'language': _detectLanguage(text), // Auto-detect language
        'format': 'json'
      };
      
      print('📤 Sending request: $requestBody');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.voiceApiBaseUrl}/analyze'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Accept-Charset': 'utf-8',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 60)); // Increased timeout for server processing

      print('📊 Response Status: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VoiceApiResult.success(data);
      } else if (response.statusCode == 422) {
        // Handle validation errors
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['detail']?[0]?['msg'] ?? 'Validation error';
          return VoiceApiResult.error('خطأ في البيانات: $errorMessage');
        } catch (e) {
          return VoiceApiResult.error('خطأ في تنسيق البيانات المرسلة');
        }
      } else if (response.statusCode == 500) {
        return VoiceApiResult.error('خطأ في السيرفر. يرجى المحاولة مرة أخرى.');
      } else {
        return VoiceApiResult.error('فشل تحليل النص: ${response.statusCode}');
      }
    } on TimeoutException {
      return VoiceApiResult.error('انتهت مهلة الاتصال. السيرفر قد يكون بطيء، يرجى المحاولة مرة أخرى.');
    } on FormatException catch (e) {
      print('❌ JSON parsing error: $e');
      return VoiceApiResult.error('خطأ في تحليل استجابة السيرفر');
    } catch (e) {
      print('❌ Text analysis error: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('NetworkException')) {
        return VoiceApiResult.error('خطأ في الاتصال بالإنترنت. تحقق من الاتصال.');
      }
      return VoiceApiResult.error('خطأ في الشبكة: ${e.toString()}');
    }
  }

  // Auto-detect language for better server processing
  String _detectLanguage(String text) {
    // Check for Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    if (arabicRegex.hasMatch(text)) {
      return 'ar';
    }
    
    // Check for common Arabic words in Latin script
    final arabicWords = ['dafat', 'genih', 'pound', 'riyal', 'dirham'];
    final lowerText = text.toLowerCase();
    for (final word in arabicWords) {
      if (lowerText.contains(word)) {
        return 'ar';
      }
    }
    
    return 'en'; // Default to English
  }

  // Analyze voice file using the Voice API (updated for correct server)
  Future<VoiceApiResult> analyzeVoice(File audioFile) async {
    try {
      print('🎤 Analyzing voice file: ${audioFile.path}');
      print('📊 File exists: ${await audioFile.exists()}');
      print('📊 File size: ${await audioFile.length()} bytes');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.voiceApiBaseUrl}/voice'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add the audio file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
      );
      
      print('📤 Sending file: ${multipartFile.filename}');
      print('📤 Content type: ${multipartFile.contentType}');
      print('📤 File length: ${multipartFile.length} bytes');
      
      request.files.add(multipartFile);

      print('🌐 Sending request to server...');
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Voice Response Status: ${response.statusCode}');
      print('📝 Voice Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Successfully parsed response');
        return VoiceApiResult.success(data);
      } else {
        print('❌ Server returned error status: ${response.statusCode}');
        return VoiceApiResult.error('Failed to analyze voice: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      print('❌ Request timeout');
      return VoiceApiResult.error('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.');
    } catch (e) {
      print('❌ Voice analysis error: $e');
      return VoiceApiResult.error('Network error: $e');
    }
  }

  // Test the Voice API connection (updated endpoints)
  Future<bool> testConnection() async {
    try {
      print('🔍 Testing Voice API connection...');
      
      // Try the main endpoint
      final response = await http.get(
        Uri.parse('${ApiConfig.voiceApiBaseUrl}/'),
        headers: {
          'Accept': 'text/html,application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📊 Testing main endpoint: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Voice API available at: http://10.0.2.2:8000/');
        return true;
      }
      
      print('❌ Voice API endpoint failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Connection test error: $e');
      return false;
    }
  }
}

// Voice API Result wrapper
class VoiceApiResult {
  final bool isSuccess;
  final dynamic data;
  final String? message;

  VoiceApiResult._({
    required this.isSuccess,
    this.data,
    this.message,
  });

  factory VoiceApiResult.success(dynamic data) {
    return VoiceApiResult._(
      isSuccess: true,
      data: data,
    );
  }

  factory VoiceApiResult.error(String message) {
    return VoiceApiResult._(
      isSuccess: false,
      message: message,
    );
  }

  // Helper methods to extract data from new API format
  String? get extractedText => data?['data']?['original_text'];
  double? get amount {
    final transactions = data?['data']?['analysis']?['transactions'];
    if (transactions != null && transactions.isNotEmpty) {
      return (transactions[0]['amount'] as num?)?.toDouble();
    }
    return null;
  }
  String? get category {
    final transactions = data?['data']?['analysis']?['transactions'];
    if (transactions != null && transactions.isNotEmpty) {
      return transactions[0]['category'] as String?;
    }
    return null;
  }
  String? get item {
    final transactions = data?['data']?['analysis']?['transactions'];
    if (transactions != null && transactions.isNotEmpty) {
      return transactions[0]['item'] as String?;
    }
    return null;
  }
  String? get description => item;
}
