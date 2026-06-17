// Transaction State - حالات المعاملات
// States for transaction management

import 'package:equatable/equatable.dart';
import '../models/transaction_model.dart';

enum TransactionStatus {
  initial,
  loading,
  loaded,
  error,
  adding,
  updating,
  deleting,
  syncing,
}

class TransactionState extends Equatable {
  final TransactionStatus status;
  final List<TransactionModel> transactions;
  final List<TransactionModel> filteredTransactions;
  final String? errorMessage;
  final String? successMessage;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> categoryTotals;
  final bool isSearching;
  final String searchQuery;

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.filteredTransactions = const [],
    this.errorMessage,
    this.successMessage,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.balance = 0.0,
    this.categoryTotals = const {},
    this.isSearching = false,
    this.searchQuery = '',
  });

  // Copy with method
  TransactionState copyWith({
    TransactionStatus? status,
    List<TransactionModel>? transactions,
    List<TransactionModel>? filteredTransactions,
    String? errorMessage,
    String? successMessage,
    double? totalIncome,
    double? totalExpense,
    double? balance,
    Map<String, double>? categoryTotals,
    bool? isSearching,
    String? searchQuery,
  }) {
    return TransactionState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      errorMessage: errorMessage,
      successMessage: successMessage,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Helper getters
  bool get isLoading => status == TransactionStatus.loading;
  bool get isLoaded => status == TransactionStatus.loaded;
  bool get hasError => status == TransactionStatus.error;
  bool get isAdding => status == TransactionStatus.adding;
  bool get isUpdating => status == TransactionStatus.updating;
  bool get isDeleting => status == TransactionStatus.deleting;
  bool get isSyncing => status == TransactionStatus.syncing;

  List<TransactionModel> get displayTransactions => 
      isSearching ? filteredTransactions : transactions;

  List<TransactionModel> get incomeTransactions => 
      transactions.where((t) => t.isIncome).toList();

  List<TransactionModel> get expenseTransactions => 
      transactions.where((t) => t.isExpense).toList();

  List<TransactionModel> get recentTransactions => 
      transactions.take(5).toList();

  // Get transactions by category
  List<TransactionModel> getTransactionsByCategory(String category) {
    return transactions.where((t) => t.category == category).toList();
  }

  // Get transactions by date range
  List<TransactionModel> getTransactionsByDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) {
    return transactions.where((t) => 
        t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  @override
  List<Object?> get props => [
        status,
        transactions,
        filteredTransactions,
        errorMessage,
        successMessage,
        totalIncome,
        totalExpense,
        balance,
        categoryTotals,
        isSearching,
        searchQuery,
      ];
}