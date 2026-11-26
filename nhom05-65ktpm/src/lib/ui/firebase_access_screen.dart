import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/app_database.dart';
import '../services/firebase_backend.dart';
import '../services/firestore_group_repository.dart';
import '../services/notification_service.dart';

class FirebaseAccessScreen extends StatefulWidget {
  const FirebaseAccessScreen({super.key});

  @override
  State<FirebaseAccessScreen> createState() => _FirebaseAccessScreenState();
}

class _FirebaseAccessScreenState extends State<FirebaseAccessScreen> {
  late final FirebaseAccountRepository repository = FirebaseAccountRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<auth.User?>(
      stream: repository.authChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return _SignInForm(repository: repository);
        return StreamBuilder<AccountProfile?>(
          stream: repository.watchProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final profile = profileSnapshot.data;
            if (profile == null) {
              return _MissingProfile(repository: repository);
            }
            return _AccountHome(repository: repository, profile: profile);
          },
        );
      },
    );
  }
}

class _SignInForm extends StatefulWidget {
  final FirebaseAccountRepository repository;
  const _SignInForm({required this.repository});

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.repository.registerLearner(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
      } else {
        await widget.repository.signIn(
          email: _email.text,
          password: _password.text,
        );
      }
    } on auth.FirebaseAuthException catch (error) {
      setState(() => _error = error.message ?? 'Could not authenticate.');
    } on FirebaseException catch (error) {
      setState(() => _error = error.message ?? 'Could not save your profile.');
    } catch (_) {
      setState(
        () => _error = 'Could not complete the request. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Speak Up · Tài khoản')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Text(
                _register ? 'Tạo tài khoản người học' : 'Chào mừng bạn quay lại',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              if (_register)
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Tên người học'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tên.'
                      : null,
                ),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Vui lòng nhập email hợp lệ.'
                    : null,
              ),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                validator: (value) => value == null || value.length < 6
                    ? 'Mật khẩu cần có ít nhất 6 ký tự.'
                    : null,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const CircularProgressIndicator()
                    : Text(_register ? 'Đăng ký người học' : 'Đăng nhập'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _register = !_register;
                        _error = null;
                      }),
                child: Text(
                  _register
                      ? 'Tôi đã có tài khoản'
                      : 'Tạo tài khoản người học',
                ),
              ),
              if (!_register)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (_email.text.trim().isEmpty) {
                            setState(() => _error = 'Vui lòng nhập email trước.');
                            return;
                          }
                          try {
                            await widget.repository.sendPasswordReset(
                              _email.text.trim(),
                            );
                            if (mounted) {
                              setState(
                                () => _error = 'Nếu email đã đăng ký, hướng dẫn đặt lại mật khẩu sẽ được gửi.',
                              );
                            }
                          } on auth.FirebaseAuthException catch (error) {
                            if (mounted) {
                              setState(
                                () => _error =
                                    error.message ??
                                    'Không thể gửi email đặt lại mật khẩu.',
                              );
                            }
                          } catch (_) {
                            if (mounted) {
                              setState(
                                () => _error = 'Lỗi kết nối. Vui lòng thử lại.',
                              );
                            }
                          }
                        },
                  child: const Text('Quên mật khẩu?'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MissingProfile extends StatelessWidget {
  final FirebaseAccountRepository repository;
  const _MissingProfile({required this.repository});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Không tìm thấy hồ sơ tài khoản. Vui lòng liên hệ quản trị viên dự án.',
          ),
          TextButton(
            onPressed: repository.signOut,
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    ),
  );
}

class _AccountHome extends StatefulWidget {
  final FirebaseAccountRepository repository;
  final AccountProfile profile;
  const _AccountHome({required this.repository, required this.profile});

  @override
  State<_AccountHome> createState() => _AccountHomeState();
}

class _AccountHomeState extends State<_AccountHome> {
  final _groupRepository = FirestoreGroupRepository();
  bool _matching = false;
  String? _message;
  StreamSubscription<RemoteMessage>? _foregroundMessages;

  @override
  void initState() {
    super.initState();
    widget.repository.registerPushToken(widget.profile.uid).catchError((_) {});
    _foregroundMessages = FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Speak Up';
      final body =
          message.notification?.body ?? 'A new group update is available.';
      NotificationService.showMessage(title, body);
    });
  }

  @override
  void dispose() {
    _foregroundMessages?.cancel();
    super.dispose();
  }

  Future<void> _matchGroups() async {
    setState(() {
      _matching = true;
      _message = null;
    });
    try {
      final result = await _groupRepository.suggestAndAssignGroups(
        widget.profile.uid,
      );
      setState(
        () => _message =
            '${result.groups.length} groups assigned; '
            '${result.waitingForGroup.length} learner(s) remain in the waiting list.',
      );
    } on FirebaseException catch (error) {
      setState(() => _message = error.message ?? 'Could not assign groups.');
    } finally {
      if (mounted) setState(() => _matching = false);
    }
  }

  Future<void> _continueToPractice() async {
    final state = context.read<AppState>();
    final localUsers = await state.db.users();
    User? localUser;
    for (final candidate in localUsers) {
      if (candidate.name.toLowerCase() ==
          widget.profile.displayName.toLowerCase()) {
        localUser = candidate;
        break;
      }
    }
    localUser ??= await state.db.createUser(widget.profile.displayName);
    await state.selectUser(localUser);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.profile.role == AccountRole.mentor
            ? 'Mentor space'
            : 'Learner space',
      ),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: widget.repository.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Hello, ${widget.profile.displayName}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          widget.profile.role == AccountRole.mentor
              ? 'Groups are built from learners with a stable rate. New accounts become learners; an administrator grants mentor access.'
              : 'Your role: Learner. Your group and mentor appear here when assigned.',
        ),
        if (widget.profile.role == AccountRole.mentor) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _matching ? null : _matchGroups,
            icon: const Icon(Icons.groups),
            label: Text(
              _matching ? 'Matching…' : 'Match unassigned learners by rate',
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_message!),
            ),
          const SizedBox(height: 16),
          Text('Your groups', style: Theme.of(context).textTheme.titleLarge),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _groupRepository.watchMentorGroups(widget.profile.uid),
            builder: (context, snapshot) => Column(
              children: [
                for (final document in snapshot.data?.docs ?? const [])
                  _GroupCard(
                    repository: _groupRepository,
                    groupId: document.id,
                  ),
                if (snapshot.hasData && snapshot.data!.docs.isEmpty)
                  const ListTile(title: Text('No groups assigned yet.')),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _continueToPractice,
            icon: const Icon(Icons.record_voice_over),
            label: const Text('Continue to pronunciation practice'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Practice scores from this device update your rate band for group matching.',
          ),
        ],
        if (widget.profile.groupId != null) ...[
          const SizedBox(height: 24),
          Text(
            'Your study group',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          _GroupCard(
            repository: _groupRepository,
            groupId: widget.profile.groupId!,
          ),
        ] else if (widget.profile.role == AccountRole.learner) ...[
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.hourglass_empty),
              title: Text('Waiting for a group'),
              subtitle: Text(
                'A group is assigned after at least four learners have a stable rate in the same band.',
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _GroupCard extends StatelessWidget {
  final FirestoreGroupRepository repository;
  final String groupId;
  const _GroupCard({required this.repository, required this.groupId});

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: repository.watchGroup(groupId),
    builder: (context, snapshot) {
      final group = snapshot.data?.data();
      if (group == null) {
        return const Card(child: ListTile(title: Text('Loading group…')));
      }
      final members = group['memberUids'];
      final uids = members is List ? members.cast<String>() : const <String>[];
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text('${group['level'] ?? 'Study'} group'),
              subtitle: Text(
                'Mentor: ${group['mentorUid'] ?? '—'} · ${uids.length} learners',
              ),
            ),
            FutureBuilder<List<AccountProfile>>(
              future: repository.loadMembers(uids),
              builder: (context, memberSnapshot) => Column(
                children: [
                  for (final member
                      in memberSnapshot.data ?? const <AccountProfile>[])
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(member.displayName),
                      subtitle: Text(member.email),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
