import 'package:dio/dio.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';



import '../../core/services/auth_api_service.dart';

import '../../core/services/offers_api_service.dart';

import '../../core/services/performance_service.dart';

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

    if (mounted) setState(() => _isLoading = false);

  }



  Future<void> _loadOffers({bool force = false}) async {

    setState(() {

      _offersLoading = true;

      _offersError = null;

    });



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



    final cached = OffersApiService.instance.cachedPreview;

    if (cached != null && cached.isNotEmpty && mounted) {

      setState(() {

        _offers = cached;

        _offersLoading = false;

      });

    }



    try {

      final products = await OffersApiService.instance.fetchPreview(force: force);

      if (!mounted) return;

      setState(() {

        _offers = products;

        _offersLoading = false;

        _offersError = products.isEmpty ? 'No deals yet — pull to refresh' : null;

      });

    } on DioException catch (e) {

      debugPrint('❌ [Home] Offers error: ${e.message}');

      if (!mounted) return;

      if (_offers.isEmpty) {

        setState(() {

          _offersLoading = false;

          _offersError =

              'Deals loading slowly — tap Retry or open Offers tab';

        });

      } else {

        setState(() => _offersLoading = false);

      }

    } catch (e) {

      debugPrint('❌ [Home] Offers error: $e');

      if (mounted && _offers.isEmpty) {

        setState(() {

          _offersLoading = false;

          _offersError = 'Failed to load deals';

        });

      }

    }

  }



  Future<void> _loadUnreadNotifications() async {

    final count = await NotificationApiService.instance.fetchUnreadCount();

    if (mounted) setState(() => _unreadNotifications = count);

  }



  void _openReminders() {

    final reminderBloc = context.read<ReminderBloc>();

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => RemindersPage(reminderBloc: reminderBloc),

      ),

    );

  }



  void _openCategories() {

    if (!context.mounted) return;

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => MultiBlocProvider(

          providers: [

            BlocProvider.value(value: context.read<ExpenseBloc>()),

            BlocProvider.value(value: context.read<CategoryBloc>()),

          ],

          child: const CategoriesPage(),

        ),

      ),

    );

  }

  void _openTransactions() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainLayout(initialIndex: 2),
      ),
    );
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

              const SizedBox(height: 16),

              const SkeletonLoader(width: 180, height: 28),

              const SizedBox(height: 8),

              const SkeletonLoader(width: 120, height: 16),

              const SizedBox(height: 20),

              SkeletonLoader(

                width: double.infinity,

                height: 150,

                borderRadius: BorderRadius.all(Radius.circular(22)),

              ),

              const SizedBox(height: 16),

              Row(

                children: const [

                  Expanded(child: SkeletonLoader(height: 90)),

                  SizedBox(width: 10),

                  Expanded(child: SkeletonLoader(height: 90)),

                  SizedBox(width: 10),

                  Expanded(child: SkeletonLoader(height: 90)),

                ],

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

        child: RefreshIndicator(

          color: const Color(0xFF0D5DB8),

          onRefresh: () async {

            context.read<AnalyticsBloc>().refresh();

            await _loadOffers(force: true);

            context.read<TransactionBloc>().add(const LoadTransactions());

          },

          child: SingleChildScrollView(

            physics: const AlwaysScrollableScrollPhysics(

              parent: BouncingScrollPhysics(),

            ),

            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const SizedBox(height: 8),

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

                  onReminders: _openReminders,

                  onCategories: _openCategories,

                ),

                const SizedBox(height: 16),

                const HomeSpendingOverview(),

                const SizedBox(height: 20),

                HomeOffersCarousel(

                  offers: _offers,

                  isLoading: _offersLoading,

                  errorMessage: _offersError,

                  onRetry: () => _loadOffers(force: true),

                  maxVisible: 6,

                  horizontal: true,

                  onShowMore: () {

                    Navigator.pushReplacement(

                      context,

                      MaterialPageRoute(

                        builder: (_) => const MainLayout(initialIndex: 1),

                      ),

                    );

                  },

                ),

                const SizedBox(height: 20),

                HomeRecentActivity(onViewAll: _openTransactions),

                const SizedBox(height: 100),

              ],

            ),

          ),

        ),

      ),

    );

  }

}


