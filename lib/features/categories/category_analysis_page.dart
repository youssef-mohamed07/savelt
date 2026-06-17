import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../home/bloc/expense_bloc.dart';
import '../home/bloc/expense_state.dart';
import '../home/bloc/expense_event.dart';
import '../../core/models/expense.dart';

class CategoryAnalysisPage extends StatelessWidget {
  final String categoryName;
  final List<Color> categoryGradient;

  const CategoryAnalysisPage({
    super.key,
    required this.categoryName,
    required this.categoryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$categoryName Analysis',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is! ExpenseLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter expenses for this category
          final categoryExpenses = state.expenses
              .where((expense) => expense.category == categoryName)
              .toList();

          if (categoryExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses in $categoryName yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Calculate total
          final total = categoryExpenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );

          // Group expenses by title for pie chart
          final Map<String, double> itemTotals = {};
          final Map<String, int> itemCounts = {};

          for (var expense in categoryExpenses) {
            final desc = expense.title.isEmpty ? categoryName : expense.title;
            itemTotals[desc] = (itemTotals[desc] ?? 0) + expense.amount;
            itemCounts[desc] = (itemCounts[desc] ?? 0) + 1;
          }

          // Sort items by amount (descending)
          final sortedItems = itemTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        '$categoryName Analysis',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Budget Spent . Last 30 days',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 32),

                      // Pie Chart and Legend
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pie Chart
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: CustomPaint(
                              painter: PieChartPainter(
                                data: sortedItems.take(4).toList(),
                                total: total,
                                baseColors: categoryGradient,
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),

                          // Legend
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sortedItems.take(4).map((item) {
                                final index = sortedItems.indexOf(item);
                                final percentage = (item.value / total * 100)
                                    .round();
                                final color = _getShadeColor(
                                  categoryGradient,
                                  index,
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.key,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$percentage%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Breakdown Section
                      const Text(
                        'Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items List
                      ...sortedItems.map((item) {
                        final percentage = (item.value / total * 100).round();
                        final count = itemCounts[item.key] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.key,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$percentage% of $categoryName Category',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.value.toInt()} EGP',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$count ${count == 1 ? "transaction" : "transactions"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _showDeleteDialog(
                                  context,
                                  item.key,
                                  categoryExpenses,
                                ),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red[400],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getShadeColor(List<Color> baseColors, int index) {
    final baseColor = baseColors[0];
    final shades = [
      baseColor,
      Color.lerp(baseColor, Colors.white, 0.3)!,
      Color.lerp(baseColor, Colors.white, 0.5)!,
      Color.lerp(baseColor, Colors.black, 0.2)!,
    ];
    return shades[index % shades.length];
  }

  void _showDeleteDialog(
    BuildContext context,
    String itemDescription,
    List<Expense> categoryExpenses,
  ) {
    final expensesToDelete = categoryExpenses
        .where(
          (e) => (e.title.isEmpty ? categoryName : e.title) == itemDescription,
        )
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expenses'),
        content: Text(
          'Delete all ${expensesToDelete.length} expense(s) for "$itemDescription"?\n\nThis will remove them from all analysis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete all matching expenses
              for (var expense in expensesToDelete) {
                context.read<ExpenseBloc>().add(DeleteExpense(expense.id));
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Deleted ${expensesToDelete.length} expense(s)',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double total;
  final List<Color> baseColors;

  PieChartPainter({
    required this.data,
    required this.total,
    required this.baseColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2; // Start from top

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / total) * 2 * math.pi;

      final color = _getShadeColor(i);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  Color _getShadeColor(int index) {
    final baseColor = baseColors[0];
    final shades = [
      baseColor,
      Color.lerp(baseColor, Colors.white, 0.3)!,
      Color.lerp(baseColor, Colors.white, 0.5)!,
      Color.lerp(baseColor, Colors.black, 0.2)!,
    ];
    return shades[index % shades.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



