// Voice Service - Optimized Speech Recognition
// Handles real-time speech recognition with emulator support

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice Recognition Service
/// Optimized for Android emulator and real devices
/// Supports both Arabic and English with smart locale detection
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _hasReceivedResult = false; // Track if we got any result

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  // Initialize speech recognition with comprehensive locale detection
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      print('🔄 Initializing voice service...');
      
      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        print('❌ Microphone permission denied');
        return false;
      }

      // Initialize speech to text
      final available = await _speechToText.initialize(
        onError: (error) {
          print('❌ Speech error: ${error.errorMsg}');
        },
        onStatus: (status) => print('📊 Speech status: $status'),
        debugLogging: true,
      );

      if (available) {
        _isInitialized = true;
        print('✅ Voice service initialized successfully');
        
        // Get and analyze available locales
        final locales = await _speechToText.locales();
        print('🌍 Total available locales: ${locales.length}');
        
        // Show ALL available locales for debugging
        print('📋 All available locales:');
        for (final locale in locales) {
          print('   - ${locale.localeId}: ${locale.name}');
        }
        
        // Check specifically for Arabic locales
        final arabicLocales = locales.where((locale) => 
          locale.localeId.startsWith('ar') || 
          locale.name.toLowerCase().contains('arabic') ||
          locale.name.toLowerCase().contains('عربي')
        ).toList();
        
        print('🇪🇬 Arabic locales found: ${arabicLocales.length}');
        for (final locale in arabicLocales) {
          print('   - Arabic: ${locale.localeId}: ${locale.name}');
        }
        
        // Check for English locales
        final englishLocales = locales.where((locale) => 
          locale.localeId.startsWith('en')
        ).toList();
        
        print('🇺🇸 English locales found: ${englishLocales.length}');
        for (final locale in englishLocales.take(3)) {
          print('   - English: ${locale.localeId}: ${locale.name}');
        }
        
        return true;
      } else {
        print('❌ Speech recognition not available');
        return false;
      }
    } catch (e) {
      print('❌ Voice service initialization error: $e');
      return false;
    }
  }

  // Start listening - Enhanced with immediate response and continuous recording
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    Function(double)? onSoundLevel,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError('Voice service not available');
        return;
      }
    }

    if (_isListening) {
      print('⚠️ Already listening');
      return;
    }

    try {
      _isListening = true;
      _hasReceivedResult = false;
      print('🎤 Starting voice recognition...');
      
      // Request microphone permission
      final hasPermission = await Permission.microphone.request();
      if (hasPermission != PermissionStatus.granted) {
        print('❌ Microphone permission DENIED');
        onError('يجب السماح بإذن الميكروفون');
        _isListening = false;
        return;
      }

      print('✅ Microphone permission GRANTED');

      // Get available locales
      final locales = await _speechToText.locales();
      String? localeId;
      
      // Find Arabic locales
      final arabicLocales = locales.where((locale) => 
        locale.localeId.startsWith('ar') || 
        locale.localeId.contains('ar_')
      ).toList();
      
      if (arabicLocales.isNotEmpty) {
        // Prefer ar_EG (Egyptian Arabic), then ar_SA (Saudi), then any Arabic
        final egyptianArabic = arabicLocales.firstWhere(
          (locale) => locale.localeId.contains('EG') || locale.localeId.contains('eg'),
          orElse: () => arabicLocales.firstWhere(
            (locale) => locale.localeId.contains('SA') || locale.localeId.contains('sa'),
            orElse: () => arabicLocales.first,
          ),
        );
        localeId = egyptianArabic.localeId;
        print('✅ Found Arabic locale: $localeId');
      } else {
        // No Arabic available, use English as fallback
        final englishLocale = locales.firstWhere(
          (locale) => locale.localeId.startsWith('en'),
          orElse: () => locales.first,
        );
        localeId = englishLocale.localeId;
        print('⚠️ No Arabic locale found! Using: $localeId');
        print('⚠️ يرجى تحميل اللغة العربية من إعدادات الجهاز');
      }
      
      print('🌍 Using locale: $localeId');
      
      // Start listening with simple settings
      await _speechToText.listen(
        onResult: (result) {
          final recognizedWords = result.recognizedWords;
          print('🎯 Voice result: "$recognizedWords"');
          
          if (recognizedWords.isNotEmpty) {
            _hasReceivedResult = true;
            onResult(recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
        cancelOnError: false,
        onSoundLevelChange: (level) {
          if (onSoundLevel != null) {
            onSoundLevel(level);
          }
        },
      );
      
      print('✅ Voice recognition STARTED');
      
    } catch (e) {
      _isListening = false;
      print('❌ Speech recognition error: $e');
      onError('خطأ في تشغيل المايك: $e');
    }
  }

  // Get current sound level (for UI visualization)
  double get currentSoundLevel => _speechToText.lastRecognizedWords.isNotEmpty ? 1.0 : 0.0;

  // Check if device supports speech recognition
  Future<bool> isDeviceSupported() async {
    try {
      return await _speechToText.initialize();
    } catch (e) {
      print('❌ Device not supported: $e');
      return false;
    }
  }

  // Get available languages for user selection
  Future<List<String>> getAvailableLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final locales = await _speechToText.locales();
      return locales.map((locale) => '${locale.name} (${locale.localeId})').toList();
    } catch (e) {
      print('❌ Error getting languages: $e');
      return [];
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      print('🛑 Stopped voice listening');
    } catch (e) {
      print('❌ Error stopping speech recognition: $e');
      _isListening = false;
    }
  }

  // Check if speech recognition is available
  Future<bool> isAvailable() async {
    return await _speechToText.initialize();
  }
}