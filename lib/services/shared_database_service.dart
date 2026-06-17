import '../core/services/transaction_api_service.dart';
import '../core/services/auth_api_service.dart';
import '../core/models/expense.dart';

/// خدمة الداتا بيز المشتركة
/// تحفظ البيانات في سيرفر الباك اند عشان كل الناس تشوفها
class SharedDatabaseService {
  static final SharedDatabaseService _instance = SharedDatabaseService._internal();
  factory SharedDatabaseService() => _instance;
  SharedDatabaseService._internal();

  final TransactionApiService _transactionApi = TransactionApiService.instance;
  final AuthApiService _authApi = AuthApiService.instance;

  /// إضافة مصروف للداتا بيز المشتركة
  Future<bool> addExpenseToSharedDB(Expense expense) async {
    try {
      print('💾 حفظ المصروف في الداتا بيز المشتركة...');
      
      if (!_authApi.isLoggedIn) {
        print('❌ المستخدم غير مسجل دخول');
        return false;
      }

      final result = await _transactionApi.createWithText(
        text: '${expense.title} - ${expense.amount} جنيه',
        price: expense.amount,
      );

      if (result.isSuccess) {
        print('✅ تم حفظ المصروف في الداتا بيز المشتركة');
        return true;
      } else {
        print('❌ فشل في حفظ المصروف: ${result.message}');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في حفظ المصروف: $e');
      return false;
    }
  }

  /// جلب كل المصاريف من الداتا بيز المشتركة
  Future<List<Expense>> getAllExpensesFromSharedDB() async {
    try {
      print('📥 جلب المصاريف من الداتا بيز المشتركة...');
      
      if (!_authApi.isLoggedIn) {
        print('❌ المستخدم غير مسجل دخول');
        return [];
      }

      final result = await _transactionApi.getTransactions(limit: 100);

      if (result.isSuccess) {
        final expenses = result.transactions.map((transaction) {
          return Expense(
            id: transaction.id,
            amount: transaction.price,
            category: 'other', // Default category
            title: transaction.text ?? 'Untitled',
            date: transaction.createdAt,
            isVoiceInput: false,
            quantity: 1,
          );
        }).toList();

        print('✅ تم جلب ${expenses.length} مصروف من الداتا بيز المشتركة');
        return expenses;
      } else {
        print('❌ فشل في جلب المصاريف: ${result.message}');
        return [];
      }
    } catch (e) {
      print('❌ خطأ في جلب المصاريف: $e');
      return [];
    }
  }

  /// إضافة مصروف من تحليل الفويس مباشرة للداتا بيز المشتركة
  Future<bool> addVoiceExpenseToSharedDB({
    required String text,
    required double amount,
    required String category,
    required String item,
    required int quantity,
  }) async {
    try {
      print('🎤 حفظ مصروف الفويس في الداتا بيز المشتركة...');
      
      if (!_authApi.isLoggedIn) {
        print('❌ المستخدم غير مسجل دخول');
        return false;
      }

      final result = await _transactionApi.createWithText(
        text: text,
        price: amount,
      );

      if (result.isSuccess) {
        print('✅ تم حفظ مصروف الفويس في الداتا بيز المشتركة');
        return true;
      } else {
        print('❌ فشل في حفظ مصروف الفويس: ${result.message}');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في حفظ مصروف الفويس: $e');
      return false;
    }
  }

  /// اختبار الاتصال بالداتا بيز المشتركة
  Future<bool> testSharedDBConnection() async {
    try {
      print('🔍 اختبار الاتصال بالداتا بيز المشتركة...');
      
      // Test with a simple transaction fetch
      final result = await _transactionApi.getTransactions(limit: 1);
      
      if (result.isSuccess) {
        print('✅ الداتا بيز المشتركة متاحة');
        return true;
      } else {
        print('❌ الداتا بيز المشتركة غير متاحة: ${result.message}');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في الاتصال بالداتا بيز المشتركة: $e');
      return false;
    }
  }
}