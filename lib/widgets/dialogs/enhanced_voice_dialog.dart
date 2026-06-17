import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/voice_service.dart';
import '../../services/voice_api_service.dart';
import '../../features/home/bloc/expense_bloc.dart';
import '../../features/home/bloc/expense_event.dart';
import '../../core/models/expense.dart';
import '../../core/services/transaction_api_service.dart';
import '../../core/services/auth_api_service.dart';

/// Enhanced Voice Input Dialog with Manual Editing
/// Features: Real server integration, Manual editing, Beautiful UI/UX
class EnhancedVoiceDialog extends StatefulWidget {
  const EnhancedVoiceDialog({super.key});

  @override
  State<EnhancedVoiceDialog> createState() => _EnhancedVoiceDialogState();
}

enum VoiceState {
  idle,
  listening,
  processing,
  success,
  editing,
  error,
}

class _EnhancedVoiceDialogState extends State<EnhancedVoiceDialog>
    with TickerProviderStateMixin {
  VoiceState _currentState = VoiceState.idle;
  String _recognizedText = '';
  String _analysisResult = '';
  String _errorMessage = '';
  double _soundLevel = 0.0;
  
  // Extracted data for editing
  double _extractedAmount = 0.0;
  String _extractedCategory = '';
  String _extractedDescription = '';
  
  final VoiceService _voiceService = VoiceService();
  final VoiceApiService _voiceApiService = VoiceApiService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _fadeController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _fadeAnimation;
  
  Timer? _soundLevelTimer;

  // Categories list
  final List<String> _categories = [
    'طعام', 'مواصلات', 'تسوق', 'صحة', 'تعليم', 'ترفيه', 'فواتير', 'أخرى'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _testServerConnection();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  Future<void> _testServerConnection() async {
    final isConnected = await _voiceApiService.testConnection();
    if (!isConnected) {
      setState(() {
        _errorMessage = 'فشل الاتصال بالسيرفر. يرجى المحاولة لاحقاً.';
      });
    }
  }

  // Real-time analysis as user speaks
  Timer? _analysisTimer;
  String _lastAnalyzedText = '';

  Future<void> _startListening() async {
    if (_currentState == VoiceState.listening) {
      await _stopListening();
      return;
    }
    
    HapticFeedback.lightImpact();
    setState(() {
      _currentState = VoiceState.listening;
      _recognizedText = '';
      _analysisResult = '';
      _errorMessage = '';
    });

    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);

    try {
      await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _recognizedText = text;
          });
          
          // Send to server immediately for real-time analysis
          if (text.isNotEmpty && text.length > 2 && text != _lastAnalyzedText) {
            print('🚀 Real-time analysis: $text');
            _analyzeTextRealTime(text);
            _lastAnalyzedText = text;
          }
        },
        onError: (error) {
          _handleError('فشل التعرف على الصوت: $error');
        },
        onSoundLevel: (level) {
          setState(() {
            _soundLevel = level;
          });
        },
      );
    } catch (e) {
      _handleError('خطأ في خدمة الصوت: $e');
    }
  }

  // Real-time analysis without changing state
  Future<void> _analyzeTextRealTime(String text) async {
    // Cancel previous analysis if still running
    _analysisTimer?.cancel();
    
    // Debounce analysis to avoid too many requests
    _analysisTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        print('📤 Sending to server: $text');
        final result = await _voiceApiService.analyzeText(text);
        
        if (result.isSuccess && result.data != null) {
          final data = result.data;
          print('📊 Server response: $data');
          
          // Extract expense data from server response
          final amount = _extractAmount(data);
          final category = _extractCategory(data);
          final description = _extractDescription(data) ?? text;
          
          if (amount > 0) {
            setState(() {
              _extractedAmount = amount;
              _extractedCategory = category;
              _extractedDescription = description;
              _analysisResult = 'المبلغ: ${amount.toStringAsFixed(2)} جنيه\nالفئة: $category\nالوصف: $description';
            });
            
            // Fill the editing controllers
            _amountController.text = amount.toStringAsFixed(2);
            _categoryController.text = category;
            _descriptionController.text = description;
            
            print('✅ Real-time analysis successful');
          } else {
            setState(() {
              _analysisResult = 'جاري التحليل...';
            });
          }
        } else {
          setState(() {
            _analysisResult = 'جاري التحليل...';
          });
        }
      } catch (e) {
        print('⚠️ Real-time analysis failed: $e');
        setState(() {
          _analysisResult = 'جاري التحليل...';
        });
      }
    });
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    _stopAnimations();
    setState(() {
      _currentState = VoiceState.idle;
    });
  }

  Future<void> _analyzeText(String text) async {
    setState(() {
      _currentState = VoiceState.processing;
    });
    _stopAnimations();

    try {
      final result = await _voiceApiService.analyzeText(text);
      
      if (result.isSuccess && result.data != null) {
        final data = result.data;
        print('📊 Server response: $data');
        
        // Extract expense data from server response
        final amount = _extractAmount(data);
        final category = _extractCategory(data);
        final description = _extractDescription(data) ?? text;
        
        if (amount > 0) {
          setState(() {
            _currentState = VoiceState.success;
            _extractedAmount = amount;
            _extractedCategory = category;
            _extractedDescription = description;
            _analysisResult = 'المبلغ: ${amount.toStringAsFixed(2)} جنيه\nالفئة: $category\nالوصف: $description';
          });
          
          // Fill the editing controllers
          _amountController.text = amount.toStringAsFixed(2);
          _categoryController.text = category;
          _descriptionController.text = description;
          
          // Auto switch to editing mode after 2 seconds
          Timer(const Duration(seconds: 2), () {
            if (mounted && _currentState == VoiceState.success) {
              _switchToEditingMode();
            }
          });
        } else {
          _handleError('لم يتم العثور على معلومات المصروف من: "$text"');
        }
      } else {
        _handleError(result.message ?? 'فشل في التحليل');
      }
    } catch (e) {
      _handleError('خطأ في التحليل: $e');
    }
  }

  void _switchToEditingMode() {
    setState(() {
      _currentState = VoiceState.editing;
    });
  }

  double _extractAmount(dynamic data) {
    try {
      // Try to extract from the new API format
      if (data is Map<String, dynamic>) {
        // Check for transactions array
        final transactions = data['data']?['analysis']?['transactions'];
        if (transactions is List && transactions.isNotEmpty) {
          final firstTransaction = transactions[0];
          if (firstTransaction['amount'] is num) {
            return (firstTransaction['amount'] as num).toDouble();
          }
        }
        
        // Fallback: try different possible keys for amount
        final possibleKeys = ['amount', 'price', 'cost', 'value', 'money', 'total'];
        for (String key in possibleKeys) {
          if (data.containsKey(key)) {
            final value = data[key];
            if (value is num) return value.toDouble();
            if (value is String) {
              final match = RegExp(r'[\d.]+').firstMatch(value);
              if (match != null) {
                return double.tryParse(match.group(0)!) ?? 0.0;
              }
            }
          }
        }
        
        // Try to parse from recognized text
        final originalText = data['data']?['original_text'] ?? _recognizedText;
        if (originalText is String) {
          final match = RegExp(r'[\d.]+').firstMatch(originalText);
          if (match != null) {
            final amount = double.tryParse(match.group(0)!);
            if (amount != null && amount > 0) return amount;
          }
        }
      }
      return 0.0;
    } catch (e) {
      print('Error extracting amount: $e');
      return 0.0;
    }
  }

  String _extractCategory(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        // Check for transactions array
        final transactions = data['data']?['analysis']?['transactions'];
        if (transactions is List && transactions.isNotEmpty) {
          final category = transactions[0]['category'];
          if (category is String) return _mapCategoryToArabic(category);
        }
        
        // Fallback: analyze text content
        final text = (data['data']?['original_text'] ?? _recognizedText).toString().toLowerCase();
        return _categorizeFromText(text);
      }
      return 'أخرى';
    } catch (e) {
      print('Error extracting category: $e');
      return 'أخرى';
    }
  }

  String _mapCategoryToArabic(String category) {
    final categoryMap = {
      'food': 'طعام',
      'transport': 'مواصلات',
      'shopping': 'تسوق',
      'health': 'صحة',
      'education': 'تعليم',
      'entertainment': 'ترفيه',
      'bills': 'فواتير',
      'other': 'أخرى',
    };
    return categoryMap[category.toLowerCase()] ?? category;
  }

  String _categorizeFromText(String text) {
    if (text.contains('طعام') || text.contains('أكل') || text.contains('food') || text.contains('restaurant') || text.contains('مطعم')) return 'طعام';
    if (text.contains('مواصلات') || text.contains('تاكسي') || text.contains('transport') || text.contains('taxi') || text.contains('أوبر')) return 'مواصلات';
    if (text.contains('تسوق') || text.contains('شراء') || text.contains('shopping') || text.contains('clothes') || text.contains('ملابس')) return 'تسوق';
    if (text.contains('صحة') || text.contains('دواء') || text.contains('health') || text.contains('medicine') || text.contains('طبيب')) return 'صحة';
    if (text.contains('تعليم') || text.contains('كتب') || text.contains('education') || text.contains('books') || text.contains('دراسة')) return 'تعليم';
    if (text.contains('ترفيه') || text.contains('سينما') || text.contains('entertainment') || text.contains('movie') || text.contains('لعب')) return 'ترفيه';
    if (text.contains('فواتير') || text.contains('فاتورة') || text.contains('bills') || text.contains('كهرباء') || text.contains('مياه')) return 'فواتير';
    return 'أخرى';
  }

  String _extractDescription(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        // Check for transactions array
        final transactions = data['data']?['analysis']?['transactions'];
        if (transactions is List && transactions.isNotEmpty) {
          final item = transactions[0]['item'];
          if (item is String && item.isNotEmpty) return item;
        }
        
        // Fallback to original text
        final originalText = data['data']?['original_text'];
        if (originalText is String && originalText.isNotEmpty) {
          return originalText;
        }
      }
      return _recognizedText;
    } catch (e) {
      print('Error extracting description: $e');
      return _recognizedText;
    }
  }

  void _handleError(String error) {
    setState(() {
      _currentState = VoiceState.error;
      _errorMessage = error;
    });
    _stopAnimations();
    HapticFeedback.heavyImpact();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
  }

  Future<void> _analyzeTextInput() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    await _analyzeText(text);
  }

  void _saveExpense() {
    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final category = _categoryController.text.trim();
      final description = _descriptionController.text.trim();

      if (amount <= 0) {
        _handleError('يرجى إدخال مبلغ صحيح');
        return;
      }
      if (category.isEmpty) {
        _handleError('يرجى اختيار فئة');
        return;
      }
      if (description.isEmpty) {
        _handleError('يرجى إدخال وصف');
        return;
      }

      final expense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        category: category,
        title: description,
        date: DateTime.now(),
        isVoiceInput: true,
      );

      // 1. Send to backend directly (fire-and-forget)
      _syncToBackend(description, amount);

      // 2. Update local state via ExpenseBloc (for immediate UI update)
      try {
        context.read<ExpenseBloc>().add(AddExpense(expense));
      } catch (_) {
        // ExpenseBloc not in context — backend sync already handled it
      }

      HapticFeedback.lightImpact();
      Navigator.of(context).pop('تم إضافة المصروف بنجاح');
    } catch (e) {
      _handleError('خطأ في حفظ المصروف: $e');
    }
  }

  Future<void> _syncToBackend(String text, double amount) async {
    try {
      final isLoggedIn = await AuthApiService.instance.isAuthenticated();
      if (!isLoggedIn) return;

      final result = await TransactionApiService.instance.createWithText(
        text: text,
        price: amount,
      );
      if (result.isSuccess) {
        print('✅ Voice expense synced to backend: $text ($amount EGP)');
      } else {
        print('⚠️ Voice backend sync failed: ${result.message}');
      }
    } catch (e) {
      print('⚠️ Voice backend sync error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    _soundLevelTimer?.cancel();
    _analysisTimer?.cancel(); // Cancel analysis timer
    _textController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (_currentState != VoiceState.editing) ...[
                  _buildVoiceVisualizer(),
                  const SizedBox(height: 24),
                  _buildTextInput(),
                ] else ...[
                  _buildEditingSection(),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تسجيل المصروفات بالصوت',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1a1a1a),
                ),
              ),
              Text(
                'تحدث أو اكتب مصروفك بوضوح',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceVisualizer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.08),
            const Color(0xFF764ba2).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF667eea).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Microphone section
          Container(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated background waves
                if (_currentState == VoiceState.listening) ...[
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 140),
                        painter: WaveformPainter(
                          progress: _waveAnimation.value,
                          soundLevel: _soundLevel,
                        ),
                      );
                    },
                  ),
                ],
                
                // Central microphone button
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _currentState == VoiceState.listening ? _pulseAnimation.value : 1.0,
                      child: GestureDetector(
                        onTap: _startListening,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getButtonColors(),
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getButtonColors().first.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: _getButtonColors().first.withValues(alpha: 0.2),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getButtonIcon(),
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Status indicator
                if (_currentState != VoiceState.idle)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getStatusTitle(),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getButtonColors().first,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Real-time text display
          if (_recognizedText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.record_voice_over, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'ما تقوليه الآن:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.blue[800],
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Real-time analysis display
          if (_analysisResult.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'التحليل المباشر:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      const Spacer(),
                      if (_extractedAmount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'تم',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _analysisResult,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.green[800],
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تعديل المصروف',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1a1a1a),
          ),
        ),
        const SizedBox(height: 16),
        
        // Amount field
        _buildEditField(
          label: 'المبلغ',
          controller: _amountController,
          keyboardType: TextInputType.number,
          prefix: const Icon(Icons.attach_money),
        ),
        const SizedBox(height: 16),
        
        // Category dropdown
        _buildCategoryDropdown(),
        const SizedBox(height: 16),
        
        // Description field
        _buildEditField(
          label: 'الوصف',
          controller: _descriptionController,
          maxLines: 2,
          prefix: const Icon(Icons.description),
        ),
      ],
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: prefix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667eea)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الفئة',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _categories.contains(_categoryController.text) ? _categoryController.text : null,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667eea)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(
                category,
                style: GoogleFonts.cairo(),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _categoryController.text = value;
            }
          },
        ),
      ],
    );
  }

  List<Color> _getButtonColors() {
    switch (_currentState) {
      case VoiceState.listening:
        return [const Color(0xFFff6b6b), const Color(0xFFee5a24)];
      case VoiceState.processing:
        return [const Color(0xFFfeca57), const Color(0xFFff9ff3)];
      case VoiceState.success:
        return [const Color(0xFF26de81), const Color(0xFF20bf6b)];
      case VoiceState.error:
        return [const Color(0xFFff6b6b), const Color(0xFFee5a24)];
      default:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    }
  }

  IconData _getButtonIcon() {
    switch (_currentState) {
      case VoiceState.listening:
        return Icons.stop_rounded;
      case VoiceState.processing:
        return Icons.hourglass_empty_rounded;
      case VoiceState.success:
        return Icons.check_rounded;
      case VoiceState.error:
        return Icons.error_outline_rounded;
      default:
        return Icons.mic_rounded;
    }
  }

  Widget _buildStatusSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getButtonColors().first.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getButtonColors().first,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusTitle(),
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1a1a1a),
                      ),
                    ),
                    Text(
                      _getStatusMessage(),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.record_voice_over, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'النص المسجل:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.blue[800],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_analysisResult.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'نتيجة التحليل:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'تم',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _analysisResult,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.green[800],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _switchToEditingMode,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(
                        'تعديل البيانات',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_currentState) {
      case VoiceState.listening:
        return Icons.mic_rounded;
      case VoiceState.processing:
        return Icons.psychology_rounded;
      case VoiceState.success:
        return Icons.check_circle_rounded;
      case VoiceState.editing:
        return Icons.edit_rounded;
      case VoiceState.error:
        return Icons.error_rounded;
      default:
        return Icons.mic_none_rounded;
    }
  }

  String _getStatusTitle() {
    switch (_currentState) {
      case VoiceState.listening:
        return 'جاري الاستماع...';
      case VoiceState.processing:
        return 'جاري التحليل...';
      case VoiceState.success:
        return 'تم بنجاح!';
      case VoiceState.editing:
        return 'تعديل المصروف';
      case VoiceState.error:
        return 'خطأ';
      default:
        return 'جاهز';
    }
  }

  String _getStatusMessage() {
    switch (_currentState) {
      case VoiceState.listening:
        return 'تحدث بوضوح عن مصروفك';
      case VoiceState.processing:
        return 'جاري معالجة النص بالذكاء الاصطناعي...';
      case VoiceState.success:
        return 'تم تحليل المصروف بنجاح! يمكنك التعديل أو الحفظ';
      case VoiceState.editing:
        return 'راجع وعدل البيانات حسب الحاجة';
      case VoiceState.error:
        return _errorMessage;
      default:
        return 'اضغط على الميكروفون لبدء التسجيل';
    }
  }

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أو اكتب مصروفك:',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'مثال: "دفعت 25 جنيه على الغداء في مطعم ماكدونالدز"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667eea)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 2,
          onSubmitted: (_) => _analyzeTextInput(),
        ),
        const SizedBox(height: 12),
        // Quick examples
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickExample('دفعت 50 جنيه بنزين'),
            _buildQuickExample('غداء 30 جنيه'),
            _buildQuickExample('فاتورة كهرباء 200 جنيه'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickExample(String text) {
    return GestureDetector(
      onTap: () {
        _textController.text = text;
        _analyzeTextInput();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: const Color(0xFF667eea),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentState == VoiceState.editing) {
      return Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _currentState = VoiceState.success;
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'رجوع',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26de81),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'حفظ المصروف',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_currentState == VoiceState.listening) {
      return Column(
        children: [
          // Stop recording button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _stopListening();
                if (_recognizedText.isNotEmpty) {
                  _analyzeText(_recognizedText);
                }
              },
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: Text(
                'إيقاف التسجيل',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFff6b6b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                await _stopListening();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _textController.text.trim().isNotEmpty ? _analyzeTextInput : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'تحليل النص',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final double progress;
  final double soundLevel;

  WaveformPainter({required this.progress, required this.soundLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF667eea).withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = 30.0;
    
    for (int i = 0; i < 3; i++) {
      final radius = baseRadius + (i * 15) + (soundLevel * 20);
      final opacity = (1.0 - (i * 0.3)) * (0.5 + soundLevel);
      
      paint.color = const Color(0xFF667eea).withValues(alpha: opacity);
      
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}