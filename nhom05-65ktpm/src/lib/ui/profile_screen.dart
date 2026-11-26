import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/app_database.dart';

/// Lets learners share one device while keeping their profile and history separate.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _colors = <int>[
    0xFF6750A4,
    0xFF006A60,
    0xFF9C4146,
    0xFF405F91,
    0xFF795900,
  ];

  late Future<List<User>> _users = context.read<AppState>().db.users();

  void _reload() =>
      setState(() => _users = context.read<AppState>().db.users());

  Future<(String, int)?> _editDialog({User? user}) async {
    final name = TextEditingController(text: user?.name ?? '');
    var color = user?.avatarColor ?? _colors.first;
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'New learner' : 'Edit profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in _colors)
                    ChoiceChip(
                      label: CircleAvatar(
                        backgroundColor: Color(option),
                        radius: 10,
                      ),
                      selected: option == color,
                      onSelected: (_) => setDialogState(() => color = option),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, (name.text, color)),
              child: Text(user == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    return result;
  }

  Future<void> _create() async {
    final value = await _editDialog();
    if (value == null || value.$1.trim().isEmpty || !mounted) return;
    final state = context.read<AppState>();
    try {
      final user = await state.db.createUser(
        value.$1.trim(),
        avatarColor: value.$2,
      );
      await state.selectUser(user);
      _reload();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not create profile. Check for a duplicate name.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _edit(User user) async {
    final value = await _editDialog(user: user);
    if (value == null || value.$1.trim().isEmpty || !mounted) return;
    final state = context.read<AppState>();
    try {
      final updated = await state.db.updateProfile(
        user,
        name: value.$1,
        avatarColor: value.$2,
      );
      if (state.user?.id == user.id) await state.selectUser(updated);
      _reload();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update profile. Check for a duplicate name.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _delete(User user) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${user.name}?'),
        content: const Text(
          'This also removes this learner’s practice history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final state = context.read<AppState>();
    await state.db.deleteUser(user.id);
    if (state.user?.id == user.id) await state.selectUser(null);
    _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose learner')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.person_add),
      label: const Text('Add learner'),
    ),
    body: FutureBuilder<List<User>>(
      future: _users,
      builder: (context, snapshot) {
        final users = snapshot.data;
        if (users == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (users.isEmpty) {
          return const Center(
            child: Text('No learners yet. Add a profile to begin.'),
          );
        }
        return ListView(
          children: [
            for (final user in users)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(user.avatarColor),
                  child: Text(user.name[0].toUpperCase()),
                ),
                title: Text(user.name),
                subtitle: Text('Daily goal ${user.dailyGoalMinutes} minutes'),
                onTap: () => context.read<AppState>().selectUser(user),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Edit profile',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(user),
                    ),
                    IconButton(
                      tooltip: 'Delete profile',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(user),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}
