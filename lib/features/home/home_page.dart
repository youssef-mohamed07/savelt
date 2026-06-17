import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/api_config.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/performance_service.dart';
import '../../widgets/amazon_product_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/skeleton_loader.dart';
import '../categories/bloc/category_bloc.dart';
import '../categories/categories_page.dart';
import '../notifications/notifications_page.dart';
import '../reminders/bloc/reminder_bloc.dart';
import '../reminders/reminders_page.dart';
import '../../core/services/notification_api_service.dart';
import 'bloc/analytics_bloc.dart';
import 'bloc/expense_bloc.dart';
import 'bloc/expense_state.dart';
import '../transactions/bloc/transaction_bloc.dart';
import '../transactions/bloc/transaction_event.dart';
import 'widgets/home_dashboard_header.dart';
import 'widgets/home_offers_carousel.dart';
import 'widgets/home_recent_activity.dart';
import 'widgets/home_spending_overview.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ExpenseBloc()),
        BlocProvider.value(value: context.read<AnalyticsBloc>()),
      ],
      child: BlocListener<ExpenseBloc, ExpenseState>(
        listenWhen: (prev, curr) {
          if (curr is! ExpenseLoaded) return false;
          if (prev is! ExpenseLoaded) return true;
          return curr.expenses.length != prev.expenses.length;
        },
        listener: (context, _) {
          context.read<TransactionBloc>().add(const LoadTransactions());
        },
        child: const _HomePageContent(),
      ),
    );
  }
}

class _HomePageContent extends StatefulWidget {
  const _HomePageContent();

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent>
    with PerformanceMonitorMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _offers = [];
  bool _offersLoading = true;
  String? _offersError;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    startPerformanceTracking('home_page_init');
    _loadInitialData();
    _loadOffers();
    _loadUnreadNotifications();
    endPerformanceTracking('home_page_init');
  }

  Future<void> _loadInitialData() async {
    await trackAsyncOperation('load_home_data', () async {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _loadOffers() async {
    setState(() {
      _offersLoading = true;
      _offersError = null;
    });
    try {
      final userId = AuthApiService.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            _offers = [];
            _offersLoading = false;
            _offersError = 'Sign in to see personalized deals';
          });
        }
        return;
      }
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ));
      final token = await AuthApiService.instance.getToken();
      if (token != null) dio.options.headers['token'] = token;

      final response = await dio.get('/api/offers',
          queryParameters: {'userId': userId});

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final byCategory = data['byCategory'] as List<dynamic>?;
        final raw = byCategory != null && byCategory.isNotEmpty
            ? byCategory
                .expand((c) => List<Map<String, dynamic>>.from(c['products'] ?? []))
                .toList()
            : List<Map<String, dynamic>>.from(data['products'] ?? []);

        final seen = <String>{};
        final products = raw
            .map((p) => _mapOfferProduct(Map<String, dynamic>.from(p)))
            .where((p) {
              final key = (p['name'] ?? '').toString().trim().toLowerCase();
              if (key.isEmpty || seen.contains(key)) return false;
              seen.add(key);
              return true;
            })
            .take(8)
            .toList();

        if (mounted) {
          setState(() {
            _offers = products;
            _offersLoading = false;
            _offersError = products.isEmpty ? null : null;
          });
        }
        return;
      }

      final msg = data is Map
          ? (data['message'] ?? data['detail'])?.toString()
          : null;
      if (mounted) {
        setState(() {
          _offers = [];
          _offersLoading = false;
          _offersError = msg ?? 'Could not load deals — is the backend running?';
        });
      }
    } on DioException catch (e) {
      debugPrint('❌ [Home] Offers error: ${e.message}');
      if (mounted) {
        setState(() {
          _offers = [];
          _offersLoading = false;
          _offersError =
              'Backend unavailable — run ./start.sh --no-app then tap Retry';
        });
      }
    } catch (e) {
      debugPrint('❌ [Home] Offers error: $e');
      if (mounted) {
        setState(() {
          _offers = [];
          _offersLoading = false;
          _offersError = 'Failed to load deals';
        });
      }
    }
  }

  Map<String, dynamic> _mapOfferProduct(Map<String, dynamic> p) {
    String formatPrice(dynamic val) {
      if (val == null) return '';
      final s = val.toString().trim();
      if (s.isEmpty || s == 'null') return '';
      final num = double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (num != null && num > 0) return 'EGP ${num.toStringAsFixed(2)}';
      if (s.toUpperCase().contains('EGP')) return s;
      return s.replaceAll(RegExp(r'^\$'), 'EGP ').replaceAll('USD', 'EGP');
    }

    String fixUrl(dynamic val) {
      if (val == null || val.toString().isEmpty) return 'https://www.amazon.eg';
      return val.toString().replaceAll('amazon.com', 'amazon.eg');
    }

    final title =
        (p['displayTitle'] ?? p['title'] ?? p['name'] ?? 'Product').toString();
    final price = formatPrice(p['price']);
    final oldPrice = formatPrice(p['original_price'] ?? p['oldPrice']);

    final imageRaw = p['image'] ??
        p['product_photo'] ??
        p['product_main_image_url'] ??
        p['product_image'] ??
        p['thumbnail'];

    return {
      'name': title,
      'price': price,
      'oldPrice': oldPrice != price ? oldPrice : '',
      'discount': p['discount']?.toString() ?? '',
      'rating': p['rating']?.toString() ?? '4.0',
      'reviews': p['reviews']?.toString() ?? p['num_ratings']?.toString() ?? '0',
      'imageUrl': normalizeAmazonImageUrl(imageRaw),
      'url': fixUrl(p['url']),
    };
  }

  Future<void> _loadUnreadNotifications() async {
    final count = await NotificationApiService.instance.fetchUnreadCount();
    if (mounted) setState(() => _unreadNotifications = count);
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return EmptyStates.error(
        message: _errorMessage,
        onRetry: () {
          setState(() {
            _errorMessage = null;
            _isLoading = true;
          });
          _loadInitialData();
        },
      );
    }

    if (_isLoading) {
      return SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  const SkeletonLoader(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLoader(width: 100, height: 16),
                        SizedBox(height: 4),
                        SkeletonLoader(width: 150, height: 20),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (_, __) => const SkeletonLoader(
                  width: double.infinity,
                  height: 180,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        color: const Color(0xFFF0F4FA),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              HomeDashboardHeader(
                unreadCount: _unreadNotifications,
                onNotificationsTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  ).then((_) {
                    if (mounted) _loadUnreadNotifications();
                  });
                },
                onReminders: () {
                  final reminderBloc = context.read<ReminderBloc>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RemindersPage(reminderBloc: reminderBloc),
                    ),
                  );
                },
                onCategories: () {
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(
                              value: context.read<ExpenseBloc>()),
                          BlocProvider.value(
                              value: context.read<CategoryBloc>()),
                        ],
                        child: const CategoriesPage(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              HomeOffersCarousel(
                offers: _offers,
                isLoading: _offersLoading,
                errorMessage: _offersError,
                onRetry: _loadOffers,
                onShowMore: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainLayout(initialIndex: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const HomeSpendingOverview(),
              const SizedBox(height: 24),
              HomeRecentActivity(
                onViewAll: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainLayout(initialIndex: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
