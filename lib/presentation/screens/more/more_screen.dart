import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../analytics/analytics_screen.dart';
import '../budget/monthly_expense_entry_screen.dart';
import '../profile/profile_screen.dart';
import '../borrowed_money/borrowed_money_screen.dart';
import '../friends/friends_screen.dart';
import '../split_expenses/split_expenses_screen.dart';
import '../savings_goals/savings_goals_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // Money Management Section
          _buildSectionHeader('Money Management'),
          _buildMenuItem(
            icon: Icons.savings_outlined,
            title: 'Savings Goals',
            subtitle: 'Track your savings goals',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.account_balance_wallet,
            title: 'Borrowed Money',
            subtitle: 'Track money you borrowed',
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BorrowedMoneyScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.dashboard_customize_outlined,
            title: 'Monthly Overview',
            subtitle: 'Check your monthly spending',
            color: Color(0xFF00B894),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MonthlyExpenseEntryScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.people,
            title: 'Friends & Groups',
            subtitle: 'Manage friends & split expenses',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendsScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.receipt_long,
            title: 'Split Expenses',
            subtitle: 'Track shared expenses',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SplitExpensesScreen()),
              );
            },
          ),

          const Divider(height: 32),

          // Reports & Analytics
          _buildSectionHeader('Reports & Analytics'),
          _buildMenuItem(
            icon: Icons.bar_chart,
            title: 'Analytics',
            subtitle: 'View charts & insights',
            color: Color(0xFF6C63FF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),

          const Divider(height: 32),

          // Settings Section
          _buildSectionHeader('Settings'),
          _buildMenuItem(
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'Edit your profile',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Toggle theme',
            color: Colors.grey[800]!,
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                // Theme toggle will be implemented later
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme toggle coming soon!')),
                );
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),

          const Divider(height: 32),

          // About Section
          _buildSectionHeader('About'),
          _buildMenuItem(
            icon: Icons.info,
            title: 'About SpendWise',
            subtitle: 'Version 1.0.0',
            color: Colors.blue,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SpendWise',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
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

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
