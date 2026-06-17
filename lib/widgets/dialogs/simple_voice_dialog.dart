import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import '../../services/voice_api_service.dart';
import '../../features/home/bloc/expense_bloc.dart';
import '../../features/home/bloc/expense_event.dart';
import '../../core/models/expense.dart';
import '../../features/categories/bloc/category_bloc.dart';
import '../../features/categories/category_data_store.dart';
import '../../features/transactions/bloc/transaction_bloc.dart';
import '../../features/transactions/bloc/transaction_event.dart';

class SimpleVoiceDialog extends StatefulWidget {
  final ExpenseBloc expenseBloc;
  final CategoryBloc categoryBloc;
  
  const SimpleVoiceDialog({
    super.key,
    required this.expenseBloc,
    required this.categoryBloc,
  });

  @override
  State<SimpleVoiceDialog> createState() => _SimpleVoiceDialogState();
}

class _SimpleVoiceDialogState extends State<SimpleVoiceDialog>
    with SingleTickerProviderStateMixin {
  late final RecorderController _recorderController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final VoiceApiService _voiceApiService = VoiceApiService();
  final TextEditingController _transcriptionController = TextEditingController();
  final List<TextEditingController> _categoryControllers = [];
  final List<TextEditingController> _descriptionControllers = [];

  static const _navy = Color(0xFF0D5DB8);
  static const _navyLight = Color(0xFF1478E0);
  static const _bg = Color(0xFFF0F4FA);
  static const _border = Color(0xFFE8EDF5);

  static const _processingSteps = [
    'Uploading audio',
    'Transcribing speech',
    'Detecting amounts',
    'Matching categories',
    'Preparing results',
  ];

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _showResults = false;
  String _recognizedText = '';
  String? _audioPath;
  int _processingStep = 0;
  Timer? _processingStepTimer;

  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _processingStepTimer?.cancel();
    _pulseController.dispose();
    _recorderController.dispose();
    _transcriptionController.dispose();
    for (final c in _categoryControllers) {
      c.dispose();
    }
    for (final c in _descriptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _disposeResultControllers() {
    for (final c in _categoryControllers) {
      c.dispose();
    }
    for (final c in _descriptionControllers) {
      c.dispose();
    }
    _categoryControllers.clear();
    _descriptionControllers.clear();
  }

  void _initResultControllers() {
    _disposeResultControllers();
    _transcriptionController.text = _recognizedText;
    for (final t in _transactions) {
      _categoryControllers.add(
        TextEditingController(text: t['category'] as String),
      );
      _descriptionControllers.add(
        TextEditingController(text: t['description'] as String),
      );
    }
  }

  String get _statusLabel {
    if (_isProcessing) return 'Analyzing your voice…';
    if (_isRecording) return 'Listening — tap stop when done';
    if (_recognizedText.isNotEmpty && !_showResults) return _recognizedText;
    return 'Tap and say your expense';
  }

  String get _hintLabel {
    if (_isProcessing) {
      return 'Extracting amount, category & description';
    }
    if (_isRecording) {
      return 'Example: "Paid 120 pounds for coffee"';
    }
    return 'Speak clearly in Arabic or English';
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;
    HapticFeedback.mediumImpact();
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    var status = await Permission.microphone.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (!mounted) return false;
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Microphone access required'),
          content: const Text(
            'Enable microphone access in Settings to record voice expenses.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (open == true) await openAppSettings();
      return false;
    }

    status = await Permission.microphone.request();
    if (status.isGranted) return true;

    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status.isPermanentlyDenied
              ? 'Microphone blocked — enable it in Settings'
              : 'Please allow microphone permission',
        ),
        action: status.isPermanentlyDenied
            ? SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              )
            : null,
      ),
    );
    return false;
  }

  Future<void> _startRecording() async {
    try {
      if (!await _ensureMicrophonePermission()) return;

      final directory = await getTemporaryDirectory();
      _audioPath = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Record with high quality settings for better server transcription
      await _recorderController.record(
        path: _audioPath,
        bitRate: 128000, // High quality bitrate
        sampleRate: 44100, // CD quality sample rate
      );
      
      setState(() {
        _isRecording = true;
        _recognizedText = '';
      });
      _pulseController.repeat(reverse: true);
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  void _startProcessingSteps() {
    _processingStep = 0;
    _pulseController.repeat(reverse: true);
    _processingStepTimer?.cancel();
    _processingStepTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted || !_isProcessing) return;
      if (_processingStep >= _processingSteps.length - 1) return;
      setState(() => _processingStep++);
    });
  }

  void _stopProcessingSteps() {
    _processingStepTimer?.cancel();
    _processingStepTimer = null;
    _pulseController.stop();
    _pulseController.reset();
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorderController.stop();
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _recognizedText = '';
      });
      _startProcessingSteps();
      
      if (path != null && path.isNotEmpty) {
        // Send directly to server (server handles Arabic better)
        await _analyzeAudioFile(File(path));
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      _stopProcessingSteps();
    }
  }

  Future<void> _analyzeAudioFile(File audioFile) async {
    try {
      print('📤 Sending audio file to server: ${audioFile.path}');
      print('📊 File size: ${await audioFile.length()} bytes');
      
      final result = await _voiceApiService.analyzeVoice(audioFile);
      
      _stopProcessingSteps();
      setState(() {
        _isProcessing = false;
      });
      
      if (result.isSuccess && result.data != null) {
        print('✅ Server response received');
        print('📦 Full response data: ${result.data}');
        
        // Extract transcription
        final text = result.data['data']?['transcription'] ?? '';
        
        // Extract ALL transactions from server
        final transactionsList = result.data['data']?['analysis']?['transactions'] as List?;
        
        print('📝 Transcription: "$text"');
        print('📊 Found ${transactionsList?.length ?? 0} transactions');
        
        if (transactionsList != null && transactionsList.isNotEmpty) {
          _transactions = transactionsList.map((t) {
            final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
            final rawCategory = t['category'] as String? ?? 'Other';
            final extractedText = (t['extracted_text'] as String? ?? '').trim();

            // Use the full transcription as description — it's what the user actually said
            final description = text.isNotEmpty ? text : (extractedText.isNotEmpty ? extractedText : rawCategory);

            // Infer category from the actual Arabic text
            final mappedCategory = _mapServerCategoryToApp(rawCategory);
            final category = text.isNotEmpty
                ? _inferCategoryFromText(text, fallback: mappedCategory)
                : mappedCategory;
            
            return {
              'amount': amount,
              'category': category,
              'description': description,
              'original': t,
            };
          }).toList();
          
          setState(() {
            _recognizedText = text;
            _showResults = true;
          });
          _initResultControllers();
        } else {
          setState(() {
            _recognizedText = text.isNotEmpty ? text : 'No transactions detected';
          });
        }
      } else {
        print('❌ Server returned error');
        setState(() {
          _recognizedText = 'Analysis failed: ${result.message ?? "Unknown error"}';
        });
      }
    } catch (e) {
      _stopProcessingSteps();
      setState(() {
        _isProcessing = false;
        _recognizedText = 'Error: $e';
      });
      print('❌ Error analyzing audio: $e');
    }
  }

  /// Map voice server categories to app categories
  String _mapServerCategoryToApp(String serverCategory) {
    final c = serverCategory.toLowerCase().trim();

    if (c == 'food & drinks' || c == 'food & drink' || c == 'food and drink' ||
        c == 'food' || c == 'restaurant' || c == 'cafe' ||
        c == 'طعام' || c == 'أكل') return 'Food & Drink';
    if (c == 'transportation' || c == 'transport' ||
        c == 'مواصلات') return 'Transport';
    if (c == 'shopping' || c == 'clothes & fashion' || c == 'clothing' ||
        c == 'grocery' || c == 'electronics' ||
        c == 'تسوق') return 'Shopping';
    if (c == 'health & beauty' || c == 'health' || c == 'pharmacy' ||
        c == 'صحة') return 'Health';
    if (c == 'bills & utilities' || c == 'bills' || c == 'bill' ||
        c == 'utilities' || c == 'فواتير') return 'Bills';
    if (c == 'entertainment' || c == 'ترفيه') return 'Entertainment';
    if (c == 'education' || c == 'تعليم') return 'Education';
    if (c == 'salary & income' || c == 'income') return 'Income';

    return serverCategory;
  }

  /// Infer category from Arabic text when server gives wrong category
  String _inferCategoryFromText(String text, {String fallback = 'Other'}) {
    final t = text.toLowerCase();
    if (t.contains('تاكسي') || t.contains('أوبر') || t.contains('uber') ||
        t.contains('كريم') || t.contains('careem') || t.contains('أجرة') ||
        t.contains('مواصلات') || t.contains('بنزين') || t.contains('وقود')) {
      return 'Transport';
    }
    if (t.contains('أكل') || t.contains('طعام') || t.contains('مطعم') ||
        t.contains('كافيه') || t.contains('قهوة') || t.contains('فطار') ||
        t.contains('غدا') || t.contains('عشا')) {
      return 'Food & Drink';
    }
    if (t.contains('صيدلية') || t.contains('دكتور') || t.contains('مستشفى') ||
        t.contains('دواء')) {
      return 'Health';
    }
    if (t.contains('صراف') || t.contains('فاتورة') || t.contains('كهرباء') ||
        t.contains('مياه') || t.contains('تليفون') || t.contains('انترنت')) {
      return 'Bills';
    }
    return fallback;
  }

  String _mapCategoryToArabic(String category) {
    final map = {
      'food': 'Food & Drink',
      'transport': 'Transport',
      'transportation': 'Transport',
      'shopping': 'Shopping',
      'health': 'Health',
      'education': 'Education',
      'entertainment': 'Entertainment',
      'bills': 'Bills',
      'other': 'Shopping',
    };
    return map[category.toLowerCase()] ?? _mapServerCategoryToApp(category);
  }

  IconData _getCategoryIconData(String category) {
    final c = category.toLowerCase();
    if (c.contains('food') || c.contains('drink')) return Icons.restaurant;
    if (c.contains('transport')) return Icons.directions_car;
    if (c.contains('shop')) return Icons.shopping_bag;
    if (c.contains('health')) return Icons.medical_services;
    if (c.contains('education')) return Icons.school;
    if (c.contains('entertain')) return Icons.movie;
    if (c.contains('bill')) return Icons.receipt;
    return Icons.category;
  }

  String _normalizeCategoryName(String categoryName) {
    // Remove special characters and extra spaces
    return categoryName
        .toLowerCase()
        .replaceAll(RegExp(r'[&\-_\s]+'), ' ')
        .trim();
  }

  String? _findMatchingCategory(String serverCategory) {
    // First use our smart mapper
    final mapped = _mapServerCategoryToApp(serverCategory);
    
    final dataStore = CategoryDataStore();
    final normalizedMapped = _normalizeCategoryName(mapped);
    
    // Check exact match with mapped category
    for (var cat in dataStore.allCategories) {
      if (_normalizeCategoryName(cat.name) == normalizedMapped) {
        return cat.name;
      }
    }
    
    // Check partial match
    for (var cat in dataStore.allCategories) {
      final normalizedExisting = _normalizeCategoryName(cat.name);
      if (normalizedMapped.contains(normalizedExisting) || 
          normalizedExisting.contains(normalizedMapped)) {
        return cat.name;
      }
    }
    
    // Return the mapped name directly (it's already one of our standard categories)
    return mapped;
  }

  Future<void> _ensureCategoryExists(String categoryName) async {
    final dataStore = CategoryDataStore();
    
    // Try to find matching category first
    final matchingCategory = _findMatchingCategory(categoryName);
    if (matchingCategory != null) {
      print('✅ Found matching category: $matchingCategory for $categoryName');
      return; // Use existing category
    }
    
    // Check if exact category exists
    final existingCategory = dataStore.findCategory(categoryName);
    
    if (existingCategory == null) {
      print('📝 Creating new category: $categoryName');
      
      final icon = _getCategoryIconData(categoryName);
      widget.categoryBloc.add(AddCategory(name: categoryName, icon: icon));
      
      final newCategory = CategoryData(
        name: categoryName,
        icon: icon,
        color: const Color(0xFF667eea),
        isMain: false,
      );
      dataStore.addCustomCategory(newCategory);
      
      print('✅ Category created: $categoryName');
    } else {
      print('✅ Category already exists: $categoryName');
    }
  }

  void _saveAllTransactions() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to save')),
      );
      return;
    }
    
    final dataStore = CategoryDataStore();
    
    // First, ensure all categories exist and get final category names
    final Map<int, String> finalCategoryNames = {};
    for (int i = 0; i < _transactions.length; i++) {
      final serverCategory = _transactions[i]['category'] as String;
      final matchingCategory = _findMatchingCategory(serverCategory);
      final finalCategory = matchingCategory ?? serverCategory;
      
      finalCategoryNames[i] = finalCategory;
      await _ensureCategoryExists(finalCategory);
    }
    
    // Then add all transactions and items to categories
    for (int i = 0; i < _transactions.length; i++) {
      _transactions[i]['category'] = _categoryControllers[i].text.trim();
      _transactions[i]['description'] = _descriptionControllers[i].text.trim();
      final transaction = _transactions[i];
      final finalCategory = finalCategoryNames[i]!;
      
      // Add expense
      final expense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
        amount: transaction['amount'] as double,
        category: finalCategory,
        title: transaction['description'] as String,
        date: DateTime.now(),
        isVoiceInput: true,
      );
      
      widget.expenseBloc.add(AddExpense(expense));

      // Add item to category
      final categoryItem = CategoryItem(
        name: transaction['description'] as String,
        quantity: 1,
        unitPrice: transaction['amount'] as double,
        date: DateTime.now(),
        source: 'voice',
      );
      
      dataStore.addItemToCategory(finalCategory, categoryItem);
      print('✅ Added item "${categoryItem.name}" to category "$finalCategory"');
    }
    
    // Refresh transactions after backend sync (AddExpense handles persistence)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.read<TransactionBloc>().add(const LoadTransactions());
      }
    });

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${_transactions.length} transaction${_transactions.length > 1 ? 's' : ''}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            _buildHeader(context),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _showResults
                    ? _buildResultsView()
                    : _isProcessing
                        ? _buildProcessingView(context)
                        : _buildRecordingView(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mic_rounded, color: _navy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showResults
                      ? 'Review & save'
                      : _isProcessing
                          ? 'Analyzing voice'
                          : 'Voice expense',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _showResults
                      ? '${_transactions.length} transaction${_transactions.length == 1 ? '' : 's'} detected'
                      : _isProcessing
                          ? 'This may take a few seconds'
                          : 'Add spending by speaking',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: _isProcessing ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView(BuildContext context) {
    return Padding(
      key: const ValueKey('processing'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_navy.withValues(alpha: 0.08), _navyLight.withValues(alpha: 0.12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(28, (i) {
                    final base = 10.0 + (i % 7) * 5;
                    final wave = base + _pulseAnimation.value * (12 + (i % 4) * 4);
                    return Container(
                      width: 4,
                      height: wave,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_navyLight, _navy],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              minHeight: 5,
              backgroundColor: _bg,
              color: _navy,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: List.generate(_processingSteps.length, (i) {
                final done = i < _processingStep;
                final active = i == _processingStep;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i < _processingSteps.length - 1 ? 10 : 0,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: done
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 22)
                            : active
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _navy,
                                    ),
                                  )
                                : Icon(Icons.circle_outlined,
                                    color: Colors.grey.shade400, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _processingSteps[i],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active
                                ? const Color(0xFF0F172A)
                                : done
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_navyLight, _navy],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _processingSteps[_processingStep],
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please wait while we analyze your recording',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView(BuildContext context) {
    return Padding(
      key: const ValueKey('recording'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: _isRecording
                      ? AudioWaveforms(
                          enableGesture: false,
                          size: Size(MediaQuery.sizeOf(context).width - 72, 56),
                          recorderController: _recorderController,
                          waveStyle: WaveStyle(
                            waveColor: _navy,
                            extendWaveform: true,
                            showMiddleLine: false,
                            spacing: 6,
                            waveThickness: 3,
                          ),
                        )
                      : _isProcessing
                          ? const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _navy,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(24, (i) {
                                final h = 8.0 + (i % 5) * 4;
                                return Container(
                                  width: 3,
                                  height: h,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCBD5E1),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                );
                              }),
                            ),
                ),
                const SizedBox(height: 12),
                Text(
                  _statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _hintLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ScaleTransition(
            scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1),
            child: GestureDetector(
              onTap: _isProcessing ? null : _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isRecording
                        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                        : [_navy, _navyLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : _navy)
                          .withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  _isProcessing
                      ? Icons.hourglass_top_rounded
                      : _isRecording
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isProcessing
                ? 'Please wait'
                : _isRecording
                    ? 'Tap to stop'
                    : 'Tap to start recording',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          if (_recognizedText.isNotEmpty &&
              !_isRecording &&
              !_isProcessing &&
              !_showResults) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Text(
                _recognizedText,
                style: GoogleFonts.inter(fontSize: 14, color: Color(0xFF9A3412)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Padding(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What we heard',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _transcriptionController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              filled: true,
              fillColor: _bg,
              hintText: 'Edit transcription…',
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _navy, width: 1.5),
              ),
            ),
            onChanged: (v) => _recognizedText = v,
          ),
          const SizedBox(height: 16),
          Text(
            'Transactions',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildTransactionCard(index),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showResults = false;
                      _transactions.clear();
                      _recognizedText = '';
                      _disposeResultControllers();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Record again',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveAllTransactions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Save all',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(int index) {
    final transaction = _transactions[index];
    final category = transaction['category'] as String;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _navy,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _categoryControllers[index],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Category',
                  ),
                  onChanged: (v) => _transactions[index]['category'] = v,
                ),
              ),
              Text(
                '${transaction['amount']} EGP',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionControllers[index],
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _bg,
              hintText: 'Description',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => _transactions[index]['description'] = v,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('food') || c.contains('drink')) return Icons.restaurant;
    if (c.contains('transport')) return Icons.directions_car;
    if (c.contains('shop')) return Icons.shopping_bag;
    if (c.contains('health')) return Icons.medical_services;
    if (c.contains('education')) return Icons.school;
    if (c.contains('entertain')) return Icons.movie;
    if (c.contains('bill')) return Icons.receipt;
    return Icons.category;
  }
}

/// Bottom sheet — better mobile UX than centered dialog.
Future<void> showSimpleVoiceSheet(
  BuildContext context, {
  required ExpenseBloc expenseBloc,
  required CategoryBloc categoryBloc,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => SimpleVoiceDialog(
      expenseBloc: expenseBloc,
      categoryBloc: categoryBloc,
    ),
  );
}
