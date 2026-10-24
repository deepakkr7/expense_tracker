import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../analytics/analytics_screen.dart';
import '../budget/monthly_expense_entry_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/privacy_screen.dart';
import '../borrowed_money/borrowed_money_screen.dart';
import '../friends/friends_screen.dart';
import '../split_expenses/split_expenses_screen.dart';
import '../savings_goals/savings_goals_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('More'), automaticallyImplyLeading: false),
      body: ListView(
        children: [
          // Money Management Section
          _buildSectionHeader(context, 'Money Management'),
          _buildMenuItem(
            context,
            icon: Icons.savings_outlined,
            title: 'Savings Goals',
            subtitle: 'Track your savings goals',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SavingsGoalsScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Borrowed Money',
            subtitle: 'Track money you borrowed',
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BorrowedMoneyScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.dashboard_customize_outlined,
            title: 'Monthly Overview',
            subtitle: 'Check your monthly spending',
            color: Color(0xFF00B894),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MonthlyExpenseEntryScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.people,
            title: 'Friends & Groups',
            subtitle: 'Manage friends & split expenses',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FriendsScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.receipt_long,
            title: 'Split Expenses',
            subtitle: 'Track shared expenses',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SplitExpensesScreen()),
              );
            },
          ),

          Divider(height: 32),

          // Reports & Analytics
          _buildSectionHeader(context, 'Reports & Analytics'),
          _buildMenuItem(
            context,
            icon: Icons.bar_chart,
            title: 'Analytics',
            subtitle: 'View charts & insights',
            color: Color(0xFF6C63FF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AnalyticsScreen()),
              );
            },
          ),

          Divider(height: 32),

          // Settings Section
          _buildSectionHeader(context, 'Settings'),
          _buildMenuItem(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy & Account',
            subtitle: 'AI consent, discovery and account deletion',
            color: AppTheme.primaryColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PrivacyScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'Edit your profile',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.brightness_6,
            title: 'App Theme',
            subtitle: _getThemeModeString(context),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            onTap: () => _showThemeDialog(context),
          ),

          Divider(height: 32),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildMenuItem(
            context,
            icon: Icons.info,
            title: 'About SpendWise',
            subtitle: 'Version 1.0.0',
            color: Colors.blue,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SpendWise',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),

          SizedBox(height: 24),

          // Logout Button — use OutlinedButton.icon to avoid TextStyle
          // inherit mismatch that occurs when nesting Row > Icon + Text
          // inside a plain OutlinedButton.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  inherit: true,
                ),
              ),
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: AppTheme.readableColor(context, Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await authProvider.logout();
                }
              },
            ),
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeModeString(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Select Theme'),
          content: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('System Default'),
                    value: ThemeMode.system,
                    groupValue: themeProvider.themeMode,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(ctx);
                        Future.microtask(
                          () => themeProvider.setThemeMode(value),
                        );
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Light Mode'),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(ctx);
                        Future.microtask(
                          () => themeProvider.setThemeMode(value),
                        );
                      }
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Dark Mode'),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      if (value != null) {
                        Navigator.pop(ctx);
                        Future.microtask(
                          () => themeProvider.setThemeMode(value),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
