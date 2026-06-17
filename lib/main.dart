import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_colors.dart';
import 'core/services/auth_api_service.dart';
import 'core/network/dio_client.dart';
import 'core/services/sync_service.dart';
import 'core/services/websocket_service.dart';
import 'services/notification_service.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'widgets/main_layout.dart';
import 'features/home/bloc/expense_bloc.dart';
import 'features/home/bloc/analytics_bloc.dart';
import 'features/reminders/bloc/reminder_bloc.dart';
import 'features/profile/bloc/user_bloc.dart';
import 'features/categories/bloc/category_bloc.dart';
import 'features/transactions/bloc/transaction_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always initialize app (loads saved token, DB, etc.) before running
  await _initializeApp();

  // Initialize Sentry only in release mode
  if (kReleaseMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = 'https://your-sentry-dsn@sentry.io/project-id'; // Replace with actual DSN
        options.tracesSampleRate = 0.1;
        options.profilesSampleRate = 0.1;
        options.attachStacktrace = true;
        options.enableAutoSessionTracking = true;
        options.enableAutoNativeBreadcrumbs = true;
        options.beforeSend = (event, hint) {
          // Filter out debug events
          return event;
        };
      },
      appRunner: () => runApp(const MyApp()),
    );
  } else {
    runApp(const MyApp());
  }
}

Future<void> _initializeApp() async {
  try {
    // 1. Initialize Auth first — loads token into memory
    await AuthApiService.instance.initialize();
    print('✅ Auth initialized');

    // 2. Initialize network client
    await DioClient().initialize();
    print('✅ Network initialized');

    // 3. Sync service — runs after auth is ready
    await SyncService().initialize();
    print('✅ Sync service initialized');

    // 5. Notifications
    await NotificationService().initialize();
    print('✅ Notifications initialized');

    // 6. WebSocket — real-time analytics
    WebSocketService.instance.connect();
    print('✅ WebSocket connecting...');

  } catch (error, stackTrace) {
    if (kReleaseMode) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('initialization', 'failed');
          scope.level = SentryLevel.fatal;
        },
      );
    }
    debugPrint('❌ App initialization failed: $error');
    // Don't rethrow — let the app start even if initialization partially fails
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ExpenseBloc()),
        BlocProvider(create: (context) => AnalyticsBloc()),
        BlocProvider(create: (context) => ReminderBloc()),
        BlocProvider(create: (context) => UserBloc()),
        BlocProvider(create: (context) => CategoryBloc()),
        BlocProvider(create: (context) => TransactionBloc()),
      ],
      child: MaterialApp(
        title: 'Smart Finance Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          // تخفيف الخطوط في كل التطبيق
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontWeight: FontWeight.w400),
            displayMedium: TextStyle(fontWeight: FontWeight.w400),
            displaySmall: TextStyle(fontWeight: FontWeight.w400),
            headlineLarge: TextStyle(fontWeight: FontWeight.w500),
            headlineMedium: TextStyle(fontWeight: FontWeight.w500),
            headlineSmall: TextStyle(fontWeight: FontWeight.w500),
            titleLarge: TextStyle(fontWeight: FontWeight.w500),
            titleMedium: TextStyle(fontWeight: FontWeight.w400),
            titleSmall: TextStyle(fontWeight: FontWeight.w400),
            bodyLarge: TextStyle(fontWeight: FontWeight.w400),
            bodyMedium: TextStyle(fontWeight: FontWeight.w400),
            bodySmall: TextStyle(fontWeight: FontWeight.w400),
            labelLarge: TextStyle(fontWeight: FontWeight.w400),
            labelMedium: TextStyle(fontWeight: FontWeight.w400),
            labelSmall: TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashPage(),
          AppRoutes.onboarding: (context) => const OnboardingPage(),
          AppRoutes.auth: (context) => const AuthPage(),
          AppRoutes.home: (context) => const MainLayout(),
        },
      ),
    );
  }
}



