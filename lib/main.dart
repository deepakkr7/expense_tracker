import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/monthly_expense_provider.dart';
import 'providers/borrowed_money_provider.dart';
import 'providers/bill_reminder_provider.dart';
import 'providers/savings_goal_provider.dart';
import 'providers/group_provider.dart';
import 'providers/split_expense_provider.dart';
import 'providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/navigation/main_navigation_screen.dart';
import 'presentation/screens/onboarding/monthly_income_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'data/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Inter',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });

  // Initialize Firebase
  // NOTE: You need to add firebase_options.dart file with your Firebase configuration
  // Run: flutterfire configure
  try {
    // Android uses the configuration generated from google-services.json.
    await Firebase.initializeApp();
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to start SpendWise. Please try again.'),
                TextButton(onPressed: main, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Initialize notifications
  tz_data.initializeTimeZones();

  try {
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));
  } catch (_) {
    // Use the device offset if its IANA identifier cannot be resolved.
    final offset = DateTime.now().timeZoneOffset.inMilliseconds;
    tz.setLocalLocation(
      tz.Location('device', [0], [0], [
        tz.TimeZone(offset, isDst: false, abbreviation: 'local'),
      ]),
    );
  }

  try {
    await NotificationService().init();
    if (await NotificationService().dailyEnabled()) {
      await NotificationService().scheduleDailyTenPMReminder();
    }
  } catch (_) {
    // Optional reminders must not prevent manual expense tracking.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) => MultiProvider(
          key: ValueKey(auth.currentUser?.id ?? 'signed-out'),
          providers: [
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
            ChangeNotifierProvider(create: (_) => BudgetProvider()),
            ChangeNotifierProvider(create: (_) => FriendProvider()),
            ChangeNotifierProvider(create: (_) => MonthlyExpenseProvider()),
            ChangeNotifierProvider(create: (_) => BorrowedMoneyProvider()),
            ChangeNotifierProvider(create: (_) => BillReminderProvider()),
            ChangeNotifierProvider(create: (_) => SavingsGoalProvider()),
            ChangeNotifierProvider(create: (_) => GroupProvider()),
            ChangeNotifierProvider(create: (_) => SplitExpenseProvider()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'SpendWise',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                home: const SplashScreen(),
                routes: {
                  '/login': (context) => const LoginScreen(),
                  '/home': (context) => const MainNavigationScreen(),
                  '/profile': (context) => const ProfileScreen(),
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  bool _needsMonthlyIncome(UserModel user) =>
      !user.incomeSetupCompleted && user.lastIncomeSetMonth == null;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Show loading while checking auth state
    if (authProvider.status == AuthStatus.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Navigate based on auth status
    if (authProvider.isAuthenticated) {
      final user = authProvider.currentUser;

      // Check if user needs monthly income onboarding
      if (user != null && _needsMonthlyIncome(user)) {
        return const MonthlyIncomeScreen();
      }

      return const MainNavigationScreen();
    } else {
      return const LoginScreen();
    }
  }
}
