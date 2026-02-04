import 'package:expense_tracker/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/monthly_expense_provider.dart';
import 'providers/borrowed_money_provider.dart';
import 'providers/bill_reminder_provider.dart';
import 'providers/savings_goal_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/group_provider.dart';
import 'providers/split_expense_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/navigation/main_navigation_screen.dart';
import 'presentation/screens/onboarding/monthly_income_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'data/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // NOTE: You need to add firebase_options.dart file with your Firebase configuration
  // Run: flutterfire configure
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
    print('Please run: flutterfire configure');
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
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => MonthlyExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BorrowedMoneyProvider()),
        ChangeNotifierProvider(create: (_) => BillReminderProvider()),
        ChangeNotifierProvider(create: (_) => SavingsGoalProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => SplitExpenseProvider()),
      ],
      child: MaterialApp(
        title: 'SpendWise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const MainNavigationScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  bool _needsMonthlyIncome(UserModel user) {
    // Check if user needs to set monthly income
    if (user.lastIncomeSetMonth == null) {
      return true; // Never set income before
    }

    final now = DateTime.now();
    final lastSet = user.lastIncomeSetMonth!;

    // Check if it's a new month
    return now.year != lastSet.year || now.month != lastSet.month;
  }

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
