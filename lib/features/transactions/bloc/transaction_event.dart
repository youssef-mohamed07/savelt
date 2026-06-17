// Transaction Events - أحداث المعاملات
// Events for transaction management

import 'package:equatable/equatable.dart';
import '../models/transaction_model.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

// Load all transactions
class LoadTransactions extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? type; // 'income', 'expense', or null for all

  const LoadTransactions({
    this.startDate,
    this.endDate,
    this.category,
    this.type,
  });

  @override
  List<Object?> get props => [startDate, endDate, category, type];
}

// Add new transaction
class AddTransaction extends TransactionEvent {
  final String title;
  final String description;
  final double amount;
  final String category;
  final String type;
  final DateTime date;
  final String? notes;
  final String? receiptUrl;
  final String? location;

  const AddTransaction({
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.notes,
    this.receiptUrl,
    this.location,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        amount,
        category,
        type,
        date,
        notes,
        receiptUrl,
        location,
      ];
}

// Update existing transaction
class UpdateTransaction extends TransactionEvent {
  final TransactionModel transaction;

  const UpdateTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

// Delete transaction
class DeleteTransaction extends TransactionEvent {
  final String transactionId;

  const DeleteTransaction(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

// Add transaction from voice input
class AddTransactionFromVoice extends TransactionEvent {
  final String voiceText;

  const AddTransactionFromVoice(this.voiceText);

  @override
  List<Object?> get props => [voiceText];
}

// Add transaction from OCR/Receipt
class AddTransactionFromReceipt extends TransactionEvent {
  final String receiptImagePath;

  const AddTransactionFromReceipt(this.receiptImagePath);

  @override
  List<Object?> get props => [receiptImagePath];
}

// Sync transactions with server
class SyncTransactions extends TransactionEvent {
  const SyncTransactions();
}

// Search transactions
class SearchTransactions extends TransactionEvent {
  final String query;

  const SearchTransactions(this.query);

  @override
  List<Object?> get props => [query];
}