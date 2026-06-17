import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../features/home/home_page.dart';
import '../features/transactions/transactions_page.dart';
import '../features/profile/profile_page.dart';
import '../features/offers/offers_page.dart';
import '../features/home/bloc/expense_bloc.dart';
import '../features/categories/bloc/category_bloc.dart';
import '../features/transactions/bloc/transaction_bloc.dart';
import '../features/transactions/bloc/transaction_event.dart';
import 'dialogs/ocr_scanning_sheet.dart';
import 'dialogs/simple_voice_dialog.dart';
import '../core/services/ocr_service.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  static const int _addButtonIndex = 2;

  late int _selectedIndex;
  late PageController _pageController;
  late AnimationController _menuController;
  late Animation<double> _menuFade;
  late Animation<double> _menuScale;
  bool _showAddMenu = false;

  static const Color _navyBlue = Color(0xFF0D5DB8);
  static const Color _navyLight = Color(0xFF1478E0);

  final List<Widget> _pages = const [
    HomePage(),
    OffersPage(),
    TransactionsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
      keepPage: true,
    );
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _menuFade = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOut,
    );
    _menuScale = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutBack,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionBloc>().add(const LoadTransactions());
      }
    });
  }

  @override
  void dispose() {
    _menuController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int _navBarIndexForPage(int pageIndex) {
    return pageIndex >= _addButtonIndex ? pageIndex + 1 : pageIndex;
  }

  void _toggleAddMenu() {
    HapticFeedback.lightImpact();
    if (_showAddMenu) {
      _closeAddMenu();
    } else {
      setState(() => _showAddMenu = true);
      _menuController.forward(from: 0);
    }
  }

  void _closeAddMenu() {
    if (!_showAddMenu) return;
    _menuController.reverse().then((_) {
      if (mounted) setState(() => _showAddMenu = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _pages[index],
          ),
          extendBody: true,
          bottomNavigationBar: SizedBox(
            height: 96,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildCurvedNav(),
                ),
                Positioned(
                  bottom: 38,
                  child: GestureDetector(
                    onTap: _toggleAddMenu,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedRotation(
                      turns: _showAddMenu ? 0.125 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      child: _buildCenterPlusButton(isOpen: _showAddMenu),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showAddMenu) _buildAddMenuOverlay(),
      ],
    );
  }

  Widget _buildCenterPlusButton({required bool isOpen}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
              : [_navyLight, _navyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isOpen ? const Color(0xFFEF4444) : _navyBlue)
                .withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.add_rounded,
        color: Colors.white,
        size: isOpen ? 30 : 32,
      ),
    );
  }

  Widget _buildAddMenuOverlay() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return FadeTransition(
      opacity: _menuFade,
      child: GestureDetector(
        onTap: _closeAddMenu,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: Stack(
            children: [
              Positioned(
                bottom: bottomInset + 118,
                left: MediaQuery.of(context).size.width / 2 - 98,
                child: ScaleTransition(
                  scale: _menuScale,
                  child: _FloatingAddOption(
                    icon: Icons.document_scanner_outlined,
                    label: 'Scan',
                    color: _navyBlue,
                    onTap: () {
                      _closeAddMenu();
                      _showScanOptions();
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: bottomInset + 118,
                right: MediaQuery.of(context).size.width / 2 - 98,
                child: ScaleTransition(
                  scale: _menuScale,
                  child: _FloatingAddOption(
                    icon: Icons.mic_rounded,
                    label: 'Voice',
                    color: _navyLight,
                    onTap: () {
                      _closeAddMenu();
                      _showVoiceInput();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurvedNav() {
    return CurvedNavigationBar(
      index: _navBarIndexForPage(_selectedIndex),
      height: 65.0,
      items: <Widget>[
        _buildNavIcon(
          Icons.home_rounded,
          'Home',
          isSelected: _selectedIndex == 0,
        ),
        _buildNavIcon(
          Icons.local_offer_rounded,
          'Offers',
          isSelected: _selectedIndex == 1,
        ),
        const SizedBox(width: 56, height: 56),
        _buildNavIcon(
          Icons.receipt_long_rounded,
          'Transactions',
          isSelected: _selectedIndex == 2,
        ),
        _buildNavIcon(
          Icons.person_rounded,
          'Profile',
          isSelected: _selectedIndex == 3,
        ),
      ],
      color: Colors.white,
      buttonBackgroundColor: _navyBlue,
      backgroundColor: Colors.transparent,
      animationCurve: Curves.easeInOutCubic,
      animationDuration: const Duration(milliseconds: 400),
      onTap: (index) {
        if (index == _addButtonIndex) return;
        _closeAddMenu();
        final pageIndex = index > _addButtonIndex ? index - 1 : index;
        _onNavTapped(pageIndex);
      },
      letIndexChange: (index) => index != _addButtonIndex,
    );
  }

  void _onNavTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
    if (index == 0 || index == 2) {
      context.read<TransactionBloc>().add(const LoadTransactions());
    }
  }

  Widget _buildNavIcon(
    IconData icon,
    String label, {
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSelected ? 28 : 24,
            color: isSelected ? Colors.white : _navyBlue,
          ),
          if (!isSelected) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _navyBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showScanOptions() {
    OcrService.instance.isAvailable();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scan Receipt',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _navyBlue,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(ctx);
                    _runOcrScan(fromCamera: true);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: _navyBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _navyBlue.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: _navyBlue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Camera',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(ctx);
                    _runOcrScan(fromCamera: false);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: _navyLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _navyLight.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: _navyLight,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Gallery',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _runOcrScan({required bool fromCamera}) async {
    final result = await showOcrScanFlow(context, fromCamera: fromCamera);

    if (!mounted || result == null) return;
    if (result.isCancelled) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Failed to scan receipt',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showVoiceInput() {
    showSimpleVoiceSheet(
      context,
      expenseBloc: context.read<ExpenseBloc>(),
      categoryBloc: context.read<CategoryBloc>(),
    );
  }
}

class _FloatingAddOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FloatingAddOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
