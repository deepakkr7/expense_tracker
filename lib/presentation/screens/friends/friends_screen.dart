import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/friend_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../data/models/friend_model.dart';
import '../../../core/theme/app_theme.dart';
import 'create_group_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final friendProvider = context.read<FriendProvider>();
    final groupProvider = context.read<GroupProvider>();

    if (authProvider.currentUser != null) {
      friendProvider.loadFriends(authProvider.currentUser!.id);
      groupProvider.loadGroups(authProvider.currentUser!.id);
    }
  }

  Future<void> _importContacts() async {
    setState(() => _isImporting = true);

    try {
      final friendProvider = context.read<FriendProvider>();
      final authProvider = context.read<AuthProvider>();

      print('🔍 Starting contacts import...');
      final contacts = await friendProvider.importContacts();
      print('✅ Got ${contacts.length} contacts');

      if (!mounted) return;

      // Show contact selection dialog
      final selectedContacts = await showDialog<List<Contact>>(
        context: context,
        builder: (context) => _ContactSelectionDialog(contacts: contacts),
      );

      if (selectedContacts != null && selectedContacts.isNotEmpty) {
        for (final contact in selectedContacts) {
          await friendProvider.addFriendFromContact(
            authProvider.currentUser!.id,
            contact,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${selectedContacts.length} friends added!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('denied')
                  ? 'Permission denied. Enable contacts in settings.'
                  : 'Error: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends & Groups'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFriendsTab(), _buildGroupsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 0 ? _importContacts : _createGroup,
        icon: Icon(_tabController.index == 0 ? Icons.contacts : Icons.add),
        label: Text(
          _tabController.index == 0 ? 'Import Contacts' : 'New Group',
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildFriendsTab() {
    final friendProvider = context.watch<FriendProvider>();

    if (_isImporting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendProvider.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Friends Yet',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Import contacts to add friends',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friendProvider.friends.length,
      itemBuilder: (context, index) {
        final friend = friendProvider.friends[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                friend.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(friend.name),
            subtitle: friend.email.isNotEmpty ? Text(friend.email) : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteFriend(friend),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    final groupProvider = context.watch<GroupProvider>();

    if (groupProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupProvider.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Groups Yet',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group to organize friends',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupProvider.groups.length,
      itemBuilder: (context, index) {
        final group = groupProvider.groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Text(
              group.emoji ?? '👥',
              style: const TextStyle(fontSize: 32),
            ),
            title: Text(group.name),
            subtitle: Text('${group.memberIds.length} members'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteGroup(group.id),
            ),
          ),
        );
      },
    );
  }

  void _createGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
  }

  Future<void> _deleteFriend(FriendModel friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Friend?'),
        content: Text('Remove ${friend.name} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = context.read<AuthProvider>();
      final friendProvider = context.read<FriendProvider>();

      await friendProvider.removeFriend(
        authProvider.currentUser!.id,
        friend.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend removed')));
      }
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: const Text('This action cannot be undone'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = context.read<AuthProvider>();
      final groupProvider = context.read<GroupProvider>();

      await groupProvider.deleteGroup(authProvider.currentUser!.id, groupId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group deleted')));
      }
    }
  }
}

// Contact selection dialog
class _ContactSelectionDialog extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactSelectionDialog({required this.contacts});

  @override
  State<_ContactSelectionDialog> createState() =>
      _ContactSelectionDialogState();
}

class _ContactSelectionDialogState extends State<_ContactSelectionDialog> {
  final Set<Contact> _selectedContacts = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Contacts'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.contacts.length,
          itemBuilder: (context, index) {
            final contact = widget.contacts[index];
            final isSelected = _selectedContacts.contains(contact);

            return CheckboxListTile(
              title: Text(contact.displayName),
              subtitle: contact.emails.isNotEmpty
                  ? Text(contact.emails.first.address)
                  : null,
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedContacts.add(contact);
                  } else {
                    _selectedContacts.remove(contact);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedContacts.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedContacts.toList()),
          child: Text('Import (${_selectedContacts.length})'),
        ),
      ],
    );
  }
}
