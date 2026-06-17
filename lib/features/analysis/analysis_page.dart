import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../home/widgets/simple_bottom_nav.dart';
import '../profile/profile_page.dart';
import '../home/bloc/expense_bloc.dart';
import '../home/bloc/expense_state.dart';

/// Analysis Page - عرض تحليل المصروفات
/// يعرض إجمالي المصروفات والتحليل الأسبوعي والتقسيم حسب الفئات
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  int _selectedIndex = 2; // Analysis page is index 2

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chart icon with arrow (like in the image)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F), // Navy blue to match logo
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Analysis',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0814F9), Color(0xFFF509D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Color(0xFFFFC107),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selector
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectFromDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _fromDate != null
                                    ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                                    : 'Select Date',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectToDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _toDate != null
                                    ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                                    : 'Select Date',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Chart Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Spending This Week',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1D86D0), Color(0xFF0F446A)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1D86D0), Color(0xFF0F446A)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_view_week,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<ExpenseBloc, ExpenseState>(
                    builder: (context, state) {
                      // Calculate dynamic weekly data from expenses
                      Map<String, double> weeklyData = {
                        'Mon': 0,
                        'Tue': 0,
                        'Wed': 0,
                        'Thu': 0,
                        'Fri': 0,
                        'Sat': 0,
                        'Sun': 0,
                      };

                      if (state is ExpenseLoaded) {
                        final now = DateTime.now();
                        final weekStart = now.subtract(
                          Duration(days: now.weekday - 1),
                        );

                        for (var expense in state.expenses) {
                          final daysDiff = expense.date
                              .difference(weekStart)
                              .inDays;
                          if (daysDiff >= 0 && daysDiff < 7) {
                            final dayNames = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            if (daysDiff < dayNames.length) {
                              weeklyData[dayNames[daysDiff]] =
                                  (weeklyData[dayNames[daysDiff]] ?? 0) +
                                  expense.amount;
                            }
                          }
                        }
                      }

                      // Show empty chart when no real data exists
                      if (weeklyData.values.every((v) => v == 0)) {
                        return SizedBox(
                          height: 280,
                          child: Center(
                            child: Text(
                              'No spending data this week',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      // Find max value for scaling
                      final maxValue = weeklyData.values.fold<double>(
                        0,
                        (max, value) => value > max ? value : max,
                      );
                      final chartMax = maxValue > 0
                          ? (maxValue * 1.2).ceilToDouble()
                          : 1000;

                      // Calculate grid intervals
                      final interval = (chartMax / 4).ceilToDouble();
                      final gridValues = List.generate(
                        5,
                        (i) => interval * (4 - i),
                      );

                      return SizedBox(
                        height: 280,
                        child: Stack(
                          children: [
                            // Grid lines and labels
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              bottom: 30,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: gridValues.map((value) {
                                  final isLast = value == gridValues.last;
                                  return _buildGridLine(
                                    value >= 1000
                                        ? '${(value / 1000).toStringAsFixed(0)}k'
                                        : value.toInt().toString(),
                                    isLast,
                                  );
                                }).toList(),
                              ),
                            ),
                            // Bars
                            Positioned(
                              left: 40,
                              right: 0,
                              top: 0,
                              bottom: 30,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: weeklyData.entries.map((entry) {
                                  final greenHeight = chartMax > 0
                                      ? (entry.value / chartMax * 220)
                                            .toDouble()
                                      : 5.0;
                                  final blueHeight = chartMax > 0
                                      ? (entry.value * 0.7 / chartMax * 220)
                                            .toDouble()
                                      : 3.0;
                                  return _buildDualBarOnly(
                                    greenHeight,
                                    blueHeight,
                                  );
                                }).toList(),
                              ),
                            ),
                            // Day labels on X-axis
                            Positioned(
                              left: 40,
                              right: 0,
                              bottom: 0,
                              height: 25,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: weeklyData.keys.map((day) {
                                  return Text(
                                    day,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: BlocBuilder<ExpenseBloc, ExpenseState>(
                      builder: (context, state) {
                        double todayTotal = 0;
                        if (state is ExpenseLoaded) {
                          // Calculate today's total
                          final today = DateTime.now();
                          todayTotal = state.expenses
                              .where((expense) {
                                return expense.date.year == today.year &&
                                    expense.date.month == today.month &&
                                    expense.date.day == today.day;
                              })
                              .fold(
                                0.0,
                                (sum, expense) => sum + expense.amount,
                              );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Spending",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'EGP ${todayTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: BlocBuilder<ExpenseBloc, ExpenseState>(
                      builder: (context, state) {
                        String highestCategory = 'N/A';
                        if (state is ExpenseLoaded) {
                          // Calculate totals for each category
                          final categories = [
                            'Shopping',
                            'Bills',
                            'Health',
                            'Food & Drink',
                          ];
                          double maxTotal = 0;
                          for (final category in categories) {
                            final total = state.getCategoryTotal(category);
                            if (total > maxTotal) {
                              maxTotal = total;
                              highestCategory = category;
                            }
                          }
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Highest Category',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              highestCategory,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SimpleBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: _onNavItemTapped,
      ),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Go to Home
        Navigator.pop(context);
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offers - Coming soon!'),
            backgroundColor: AppColors.primary,
          ),
        );
        // Reset selection back to analysis
        setState(() {
          _selectedIndex = 2;
        });
        break;
      case 2:
        // Already on Analysis - just update selection
        setState(() {
          _selectedIndex = 2;
        });
        break;
      case 3:
        // Go to Profile
        final expenseBloc = context.read<ExpenseBloc>();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: expenseBloc,
              child: const ProfilePage(),
            ),
          ),
        );
        break;
    }
  }

  void _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  void _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  Widget _buildDualBarOnly(double greenHeight, double blueHeight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Green Bar
        Container(
          width: 14,
          height: greenHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(width: 4),
        // Blue Bar
        Container(
          width: 14,
          height: blueHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ],
    );
  }

  Widget _buildGridLine(String label, bool isDarkLine) {
    return Row(
      children: [
        SizedBox(
          width: 35,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: isDarkLine
              ? Container(height: 2, color: Colors.grey[800])
              : CustomPaint(
                  painter: DashedLinePainter(),
                  child: Container(height: 1),
                ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


