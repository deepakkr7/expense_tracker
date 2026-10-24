import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../budget/budget_planner_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _savingsController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _incomeController.text = user.monthlyIncome > 0
          ? user.monthlyIncome.toStringAsFixed(0)
          : '';
      _savingsController.text = user.savingsGoal > 0
          ? user.savingsGoal.toStringAsFixed(0)
          : '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;

      if (user != null) {
        final newLimit = double.tryParse(_savingsController.text) ?? 0.0;
        final limitChanged = newLimit != user.savingsGoal;

        final updatedUser = user.copyWith(
          name: _nameController.text.trim(),
          monthlyIncome: double.tryParse(_incomeController.text) ?? 0.0,
          savingsGoal: newLimit,
          lastIncomeSetMonth: DateTime.now(),
        );

        await authProvider.updateUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          setState(() => _isEditing = false);

          if (limitChanged) {
            final shouldUpdateBudget = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Limit Changed'),
                content: Text(
                  'You changed your monthly limit. Would you like to update your budget plan to match?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Not Now'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    child: Text('Update Budget Plan'),
                  ),
                ],
              ),
            );

            if (shouldUpdateBudget == true && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BudgetPlannerScreen()),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEdit() {
    _loadUserData();
    setState(() => _isEditing = false);
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.link, color: AppTheme.primaryColor),
              title: Text('Enter Photo URL'),
              onTap: () {
                Navigator.pop(ctx);
                _showUrlInput(context);
              },
            ),
            if (context.read<AuthProvider>().currentUser?.photoUrl != null &&
                context.read<AuthProvider>().currentUser!.photoUrl!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete, color: AppTheme.errorColor),
                title: Text('Remove Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showUrlInput(BuildContext context) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter Photo URL'),
        content: TextField(
          controller: urlController,
          decoration: InputDecoration(
            hintText: 'https://example.com/photo.jpg',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadPhoto(urlController.text.trim());
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto(String photoUrl) async {
    if (photoUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a valid URL')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;

      if (user != null) {
        final updatedUser = user.copyWith(photoUrl: photoUrl);
        await authProvider.updateUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;

      if (user != null) {
        final updatedUser = user.copyWith(photoUrl: '');
        await authProvider.updateUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo removed'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text('No user data')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(onPressed: _cancelEdit, child: Text('Cancel')),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF374151)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Avatar with upload option
                  GestureDetector(
                    onTap: () => _showPhotoOptions(context),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [AppTheme.cardShadow],
                            image:
                                user.photoUrl != null &&
                                    user.photoUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(user.photoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: user.photoUrl == null || user.photoUrl!.isEmpty
                              ? Center(
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.readableColor(
                                        context,
                                        AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFF111827),
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Profile Form
            Padding(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Section
                    _buildSectionTitle('Personal Information'),
                    SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.person,
                      label: 'Name',
                      child: _isEditing
                          ? TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                              ),
                              validator: (value) =>
                                  Validators.validateRequired(value, 'Name'),
                            )
                          : Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    SizedBox(height: 24),

                    // Financial Information
                    _buildSectionTitle('Financial Information'),
                    SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.account_balance_wallet,
                      label: 'Monthly Income',
                      child: _isEditing
                          ? TextFormField(
                              controller: _incomeController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter monthly income',
                                prefixText: '₹ ',
                              ),
                              validator: Validators.validateAmount,
                            )
                          : Text(
                              user.monthlyIncome > 0
                                  ? '₹${user.monthlyIncome.toStringAsFixed(0)}'
                                  : 'Not set',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: user.monthlyIncome > 0
                                    ? AppTheme.successColor
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.request_page,
                      label: 'Monthly Limit',
                      child: _isEditing
                          ? TextFormField(
                              controller: _savingsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter monthly limit',
                                prefixText: '₹ ',
                              ),
                            )
                          : Text(
                              user.savingsGoal > 0
                                  ? '₹${user.savingsGoal.toStringAsFixed(0)}'
                                  : 'Not set',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: user.savingsGoal > 0
                                    ? AppTheme.accentColor
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    SizedBox(height: 16),
                    if (user.lastIncomeSetMonth != null)
                      _buildInfoCard(
                        icon: Icons.calendar_today,
                        label: 'Last Updated',
                        child: Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(user.lastIncomeSetMonth!),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    SizedBox(height: 32),

                    // Save Button
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                    SizedBox(height: 16),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                'Logout',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              content: Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Logout'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && mounted) {
                            await context.read<AuthProvider>().logout();

                            // Navigate to login screen and clear all routes
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.logout, color: AppTheme.errorColor),
                        label: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.readableColor(
                              context,
                              AppTheme.errorColor,
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.secondaryColor),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
