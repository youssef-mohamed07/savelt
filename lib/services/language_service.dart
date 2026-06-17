// Language Detection and Conversion Service
// Handles Arabic/English detection and Franco-Arabic conversion

/// Language Service for detecting and converting between Arabic and English
/// Handles Franco-Arabic (Arabic written in English letters) conversion
class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  // Franco-Arabic to Arabic conversion map
  static const Map<String, String> _francoToArabicMap = {
    // Common words
    'ana': 'أنا',
    'enta': 'إنت',
    'enti': 'إنتي',
    'ehna': 'إحنا',
    'howa': 'هو',
    'heya': 'هي',
    'da': 'ده',
    'di': 'دي',
    'dol': 'دول',
    
    // Numbers
    'wahed': 'واحد',
    'etneen': 'اتنين',
    'talata': 'تلاتة',
    'arbaa': 'أربعة',
    'khamsa': 'خمسة',
    'setta': 'ستة',
    'sabaa': 'سبعة',
    'tamanya': 'تمانية',
    'tesaa': 'تسعة',
    'ashara': 'عشرة',
    'khamstashar': 'خمستاشر',
    'eshrein': 'عشرين',
    'talatin': 'تلاتين',
    'arbein': 'أربعين',
    'khamsin': 'خمسين',
    'settin': 'ستين',
    'sabein': 'سبعين',
    'tamanin': 'تمانين',
    'tesein': 'تسعين',
    'meyya': 'مية',
    'alf': 'ألف',
    
    // Money and shopping
    'geneih': 'جنيه',
    'geneh': 'جنيه',
    'genih': 'جنيه',
    'pound': 'جنيه',
    'ersh': 'قرش',
    'qersh': 'قرش',
    'felos': 'فلوس',
    'masari': 'مصاري',
    'eshterit': 'اشتريت',
    'sharit': 'شريت',
    'dafat': 'دفعت',
    'khalast': 'خلصت',
    'sarraft': 'صرفت',
    
    // Food and drinks
    'akl': 'أكل',
    'sharab': 'شراب',
    'qahwa': 'قهوة',
    'shai': 'شاي',
    'laban': 'لبن',
    'khobz': 'خبز',
    'roz': 'رز',
    'farkha': 'فرخة',
    'lahma': 'لحمة',
    'samak': 'سمك',
    'khodar': 'خضار',
    'fakha': 'فاكهة',
    'mouz': 'موز',
    'toffah': 'تفاح',
    'bortoqan': 'برتقان',
    'manga': 'مانجا',
    
    // Transportation
    'otobees': 'أتوبيس',
    'metro': 'مترو',
    'taxi': 'تاكسي',
    'uber': 'أوبر',
    'careem': 'كريم',
    'benzin': 'بنزين',
    'solar': 'سولار',
    
    // Shopping categories
    'malabis': 'ملابس',
    'gazma': 'جزمة',
    'shanta': 'شنطة',
    'mobile': 'موبايل',
    'laptop': 'لابتوب',
    'computer': 'كمبيوتر',
    'television': 'تليفزيون',
    'tv': 'تليفزيون',
    
    // Places
    'supermarket': 'سوبر ماركت',
    'mall': 'مول',
    'pharmacy': 'صيدلية',
    'hospital': 'مستشفى',
    'bank': 'بنك',
    'restaurant': 'مطعم',
    'cafe': 'كافيه',
    'cinema': 'سينما',
    
    // Common phrases
    'mesh': 'مش',
    'mish': 'مش',
    'keda': 'كده',
    'kaman': 'كمان',
    'bardu': 'برضو',
    'bas': 'بس',
    'khalas': 'خلاص',
    'tayeb': 'طيب',
    'ahsan': 'أحسن',
    'kwayes': 'كويس',
    'helw': 'حلو',
    'wehesh': 'وحش',
    'ghali': 'غالي',
    'rakhees': 'رخيص',
    
    // Prepositions and connectors
    'fi': 'في',
    'men': 'من',
    'ela': 'إلى',
    'ala': 'على',
    'maaa': 'مع',
    'bel': 'بال',
    'lel': 'لل',
    'wel': 'وال',
    'fel': 'فال',
    
    // Time
    'ennaharda': 'النهاردة',
    'embare7': 'إمبارح',
    'bokra': 'بكرة',
    'delwa2ti': 'دلوقتي',
    'ba3dein': 'بعدين',
    'qabel': 'قبل',
    'saa': 'ساعة',
    'deqeeqa': 'دقيقة',
    'yom': 'يوم',
    'osboa': 'أسبوع',
    'shahr': 'شهر',
    'sana': 'سنة',
  };

  /// Detect if text is Arabic, English, or Franco-Arabic
  LanguageType detectLanguage(String text) {
    if (text.isEmpty) return LanguageType.unknown;
    
    // Check for Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(text)) {
      return LanguageType.arabic;
    }
    
    // Check for Franco-Arabic patterns
    final lowerText = text.toLowerCase();
    int francoMatches = 0;
    
    for (final francoWord in _francoToArabicMap.keys) {
      if (lowerText.contains(francoWord)) {
        francoMatches++;
      }
    }
    
    // If we found Franco-Arabic words, it's likely Franco-Arabic
    if (francoMatches > 0) {
      return LanguageType.francoArabic;
    }
    
    // Check for English patterns
    final englishRegex = RegExp(r'^[a-zA-Z0-9\s\.,!?-]+$');
    if (englishRegex.hasMatch(text)) {
      return LanguageType.english;
    }
    
    return LanguageType.mixed;
  }

  /// Convert Franco-Arabic text to proper Arabic
  String convertFrancoToArabic(String text) {
    if (text.isEmpty) return text;
    
    String convertedText = text.toLowerCase();
    
    // Sort by length (longest first) to avoid partial replacements
    final sortedEntries = _francoToArabicMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    
    for (final entry in sortedEntries) {
      final franco = entry.key;
      final arabic = entry.value;
      
      // Replace whole words only (with word boundaries)
      convertedText = convertedText.replaceAllMapped(
        RegExp('\\b$franco\\b', caseSensitive: false),
        (match) => arabic,
      );
    }
    
    // Handle numbers in Franco-Arabic
    convertedText = _convertFrancoNumbers(convertedText);
    
    return convertedText;
  }

  /// Convert Franco-Arabic numbers to Arabic
  String _convertFrancoNumbers(String text) {
    // Convert common number patterns
    text = text.replaceAllMapped(
      RegExp(r'\b(\d+)\s*(geneih|geneh|genih|pound)\b', caseSensitive: false),
      (match) => '${match.group(1)} جنيه',
    );
    
    text = text.replaceAllMapped(
      RegExp(r'\b(\d+)\s*(ersh|qersh)\b', caseSensitive: false),
      (match) => '${match.group(1)} قرش',
    );
    
    return text;
  }

  /// Smart text processing: detect language and convert if needed
  ProcessedText processText(String originalText) {
    final detectedLanguage = detectLanguage(originalText);
    String processedText = originalText;
    
    switch (detectedLanguage) {
      case LanguageType.francoArabic:
        processedText = convertFrancoToArabic(originalText);
        break;
      case LanguageType.mixed:
        // Try to convert Franco parts while keeping English parts
        processedText = convertFrancoToArabic(originalText);
        break;
      default:
        // Keep as is for Arabic and English
        break;
    }
    
    return ProcessedText(
      originalText: originalText,
      processedText: processedText,
      detectedLanguage: detectedLanguage,
      wasConverted: processedText != originalText,
    );
  }

  /// Get language-specific hints and placeholders
  Map<String, String> getLanguageHints(LanguageType language) {
    switch (language) {
      case LanguageType.arabic:
        return {
          'placeholder': 'مثال: "اشتريت قهوة بـ 50 جنيه"',
          'hint': 'تحدث بالعربية أو الإنجليزية',
          'status': 'جاهز للتسجيل أو الكتابة',
          'listening': 'جاري التسجيل... اضغط للتوقف',
          'processing': 'جاري معالجة النص...',
          'success': 'تم! راجع النص أدناه إذا لزم الأمر',
          'error': 'حاول مرة أخرى أو اكتب يدوياً',
        };
      case LanguageType.english:
        return {
          'placeholder': 'e.g., "I bought coffee for 50 EGP"',
          'hint': 'Speak in Arabic or English',
          'status': 'Ready to record or type',
          'listening': 'Recording... Tap to stop',
          'processing': 'Processing your input...',
          'success': 'Success! Review text below if needed',
          'error': 'Try again or type manually',
        };
      default:
        return {
          'placeholder': 'e.g., "اشتريت قهوة بـ 50 جنيه" or "I bought coffee for 50 EGP"',
          'hint': 'Speak in Arabic or English',
          'status': 'Ready to record or type',
          'listening': 'Recording... Tap to stop',
          'processing': 'Processing your input...',
          'success': 'Success! Review text below if needed',
          'error': 'Try again or type manually',
        };
    }
  }
}

/// Language detection types
enum LanguageType {
  arabic,
  english,
  francoArabic,
  mixed,
  unknown,
}

/// Processed text result
class ProcessedText {
  final String originalText;
  final String processedText;
  final LanguageType detectedLanguage;
  final bool wasConverted;

  ProcessedText({
    required this.originalText,
    required this.processedText,
    required this.detectedLanguage,
    required this.wasConverted,
  });

  @override
  String toString() {
    return 'ProcessedText(original: "$originalText", processed: "$processedText", language: $detectedLanguage, converted: $wasConverted)';
  }
}