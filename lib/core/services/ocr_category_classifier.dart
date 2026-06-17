/// Maps OCR taxonomy + item keywords → app category names.
class OcrCategoryClassifier {
  OcrCategoryClassifier._();

  /// OCR invoice-level category → app display name.
  static String mapOcrCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Shopping';
    final key = raw.toLowerCase().trim();
    return _ocrKeyToApp[key] ?? _inferFromText(key) ?? 'Shopping';
  }

  /// Classify a single line item; falls back to [invoiceCategory] then Shopping.
  static String classifyItem(String itemName, {String? invoiceCategory}) {
    final fromName = _inferFromText(itemName);
    if (fromName != null) return fromName;

    if (invoiceCategory != null && invoiceCategory.isNotEmpty) {
      return mapOcrCategory(invoiceCategory);
    }

    return 'Shopping';
  }

  static const _ocrKeyToApp = {
    'restaurant': 'Food & Drinks',
    'cafe': 'Food & Drinks',
    'food': 'Food & Drinks',
    'food & drink': 'Food & Drinks',
    'food & drinks': 'Food & Drinks',
    'grocery': 'Food & Drinks',
    'pharmacy': 'Health',
    'health': 'Health',
    'fuel': 'Transport',
    'transport': 'Transport',
    'transportation': 'Transport',
    'electronics': 'Shopping',
    'clothing': 'Shopping',
    'shopping': 'Shopping',
    'household': 'Shopping',
    'home': 'Shopping',
    'bills': 'Bills',
    'bill': 'Bills',
    'utilities': 'Bills',
    'entertainment': 'Entertainment',
    'education': 'Education',
    'other': 'Shopping',
  };

  static String? _inferFromText(String text, {String? fallback}) {
    final t = text.toLowerCase();

    if (_any(t, [
      'موز', 'فاكه', 'fruit', 'banana', 'apple', 'orange', 'vegetable', 'خضار',
      'حليب', 'milk', 'bread', 'خبز', 'جبن', 'cheese', 'بيض', 'egg', 'لحم', 'meat',
      'دجاج', 'chicken', 'rice', 'أرز', 'ارز', 'شاورما', 'shawarma', 'burger',
      'pizza', 'kebab', 'كباب', 'وجبة', 'meal', 'ice cream', 'ايس كريم', 'آيس',
      'عصير', 'juice', 'سnaكس', 'snack', 'chocolate', 'حلو', 'candy',
      'مكرونة', 'pasta', 'زيت', 'oil', 'سكر', 'sugar', 'قهوة', 'coffee',
      'شاي', 'tea', 'مطعم', 'restaurant', 'كافيه', 'cafe', 'café', 'فطار',
      'غدا', 'عشا', 'طعام', 'أكل', 'اكل', 'food', 'drink', 'مشروب',
    ])) {
      return 'Food & Drinks';
    }

    if (_any(t, [
      'دواء', 'medicine', 'pharmacy', 'صيدل', 'vitamin', 'فيتام', 'tablet',
      'حبوب', 'شراب', 'syrup', 'prescription', 'dose', 'mg', 'ml',
      'مستشف', 'hospital', 'clinic', 'doctor', 'دكتور', 'mask', 'كمام',
    ])) {
      return 'Health';
    }

    if (_any(t, [
      'بنزين', 'سولار', 'ديزل', 'وقود', 'fuel', 'petrol', 'diesel', 'gasoline',
      'تاكسي', 'taxi', 'uber', 'أوبر', 'كريم', 'careem', 'أجرة', 'مواصلات',
      'transport', 'parking', 'موقف',
    ])) {
      return 'Transport';
    }

    if (_any(t, [
      'فاتورة', 'bill', 'utility', 'utilities', 'كهرب', 'electric', 'مياه', 'water',
      'internet', 'انترنت', 'wifi', 'subscription', 'اشتراك', 'rent', 'إيجار',
    ])) {
      return 'Bills';
    }

    if (_any(t, [
      'عربة', 'cart', 'trolley', 'سلك', 'wire', 'steel', 'حديد',
      'كرتون', 'carton', 'box', 'علبة', 'فوطة', 'towel', 'tissue', 'مناديل',
      'مراتب', 'mattress', 'cleaning', 'منظف', 'soap', 'صابون', 'detergent',
      'بلاستيك', 'plastic', 'bag', 'شنطة', 'كيس', 'phone', 'laptop',
      'charger', 'شاحن', 'cable', 'سماع', 'headphone', 'shirt', 'قميص',
      'pants', 'بنطلون', 'shoes', 'حذاء', 'dress', 'فستان', 'tool', 'أداة',
      'hardware', 'عدة', 'light', 'لمبة', 'battery', 'بطارية', 'paper', 'ورق',
      'pen', 'قلم', 'kitchen', 'مطبخ', 'furniture', 'أثاث', 'سوبر', 'market',
      'ماركت', 'hyper', 'shop', 'store', 'تسوق', 'buy', 'شراء',
    ])) {
      return 'Shopping';
    }

    if (_any(t, ['cinema', 'movie', 'game', 'concert', 'netflix', 'سينما', 'لعبة', 'ترفيه'])) {
      return 'Entertainment';
    }

    if (_any(t, ['book', 'course', 'school', 'university', 'كتاب', 'مدرس', 'تعليم', 'education'])) {
      return 'Education';
    }

    return fallback;
  }

  static bool _any(String text, List<String> needles) {
    for (final n in needles) {
      if (text.contains(n)) return true;
    }
    return false;
  }
}
