import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/data/models/profile_model.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../data/models/buddy_model.dart';
import '../../data/repositories/buddy_repository.dart';

class BuddyMatchingTab extends StatefulWidget {
  const BuddyMatchingTab({super.key});

  @override
  State<BuddyMatchingTab> createState() => _BuddyMatchingTabState();
}

class _BuddyMatchingTabState extends State<BuddyMatchingTab> {
  final BuddyRepository _repository = BuddyRepository();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _busyActions = {};

  String? _loadedUserId;
  String? _selectedLevel;
  bool _isLoading = false;
  String? _errorMessage;
  List<ProfileModel> _candidates = const [];
  List<BuddyModel> _matches = const [];
  Map<String, ProfileModel> _profilesById = const {};

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'vi': 'Tiếng Việt',
    'zh': 'Tiếng Trung',
    'ja': 'Tiếng Nhật',
    'ko': 'Tiếng Hàn',
    'fr': 'Tiếng Pháp',
    'es': 'Tiếng Tây Ban Nha',
    'de': 'Tiếng Đức',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.watch<AuthProvider>().currentProfile;
    if (profile?.userId == _loadedUserId) return;

    _loadedUserId = profile?.userId;
    _candidates = const [];
    _matches = const [];
    _profilesById = const {};
    _errorMessage = null;
    if (profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _loadedUserId == profile.userId) {
          _loadData(profile);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData(ProfileModel profile) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final candidates = await _repository.fetchCandidates(profile);
      final matches = await _repository.fetchMatches(profile.userId);
      final otherUserIds = matches
          .map((match) => match.otherUserIdFor(profile.userId))
          .whereType<String>();
      final profilesById = await _repository.fetchProfiles(otherUserIds);

      if (!mounted || _loadedUserId != profile.userId) return;
      setState(() {
        _candidates = candidates;
        _matches = matches;
        _profilesById = profilesById;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || _loadedUserId != profile.userId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  List<ProfileModel> _visibleCandidates(String userId) {
    final linkedUserIds = _matches
        .where((match) => !match.isRejected)
        .map((match) => match.otherUserIdFor(userId))
        .whereType<String>()
        .toSet();
    final query = _searchController.text.trim().toLowerCase();

    return _candidates.where((candidate) {
      if (linkedUserIds.contains(candidate.userId)) return false;
      if (_selectedLevel != null &&
          candidate.proficiencyLevel.toUpperCase() != _selectedLevel) {
        return false;
      }
      return query.isEmpty ||
          candidate.displayName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _runAction(
    String actionId,
    Future<void> Function() action,
  ) async {
    final profile = context.read<AuthProvider>().currentProfile;
    if (profile == null) return;

    setState(() {
      _busyActions.add(actionId);
      _errorMessage = null;
    });
    try {
      await action();
      await _loadData(profile);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyActions.remove(actionId));
      }
    }
  }

  String _languageName(String code) =>
      _languageNames[code.toLowerCase()] ?? code.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().currentProfile;
    if (profile == null) {
      return const Center(
        child: Text('Đăng nhập và hoàn tất hồ sơ để tìm bạn đồng hành.'),
      );
    }

    final incoming = _matches
        .where((match) => match.receiverId == profile.userId && match.isPending)
        .toList();
    final outgoing = _matches
        .where(
            (match) => match.requesterId == profile.userId && match.isPending)
        .toList();
    final accepted = _matches.where((match) => match.isAccepted).toList();
    final candidates = _visibleCandidates(profile.userId);

    return RefreshIndicator(
      onRefresh: () => _loadData(profile),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildIntro(profile),
          const SizedBox(height: AppSpacing.lg),
          if (_errorMessage != null) ...[
            _buildErrorCard(),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_isLoading && _candidates.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildSectionTitle('Lời mời bạn nhận', incoming.length),
            if (incoming.isEmpty)
              _buildEmptyText('Chưa có lời mời ghép cặp nào.')
            else
              ...incoming.map(
                (match) => _buildIncomingRequest(match, profile.userId),
              ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Lời mời đã gửi', outgoing.length),
            if (outgoing.isEmpty)
              _buildEmptyText('Bạn chưa gửi lời mời nào đang chờ.')
            else
              ...outgoing.map(
                (match) => _buildPendingRequest(match, profile.userId),
              ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Bạn đồng hành', accepted.length),
            if (accepted.isEmpty)
              _buildEmptyText(
                  'Khi lời mời được chấp nhận, bạn sẽ thấy bạn đồng hành ở đây.')
            else
              ...accepted.map(
                (match) => _buildBuddyCard(match, profile.userId),
              ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Tìm bạn phù hợp', candidates.length),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Tìm theo tên',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _selectedLevel ?? 'all',
              decoration: const InputDecoration(
                labelText: 'Lọc theo trình độ ngôn ngữ',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: 'all',
                  child: Text('Mọi trình độ'),
                ),
                ...const ['A1', 'A2', 'B1', 'B2'].map(
                  (level) => DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  ),
                ),
              ],
              onChanged: (level) => setState(
                () => _selectedLevel = level == 'all' ? null : level,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (candidates.isEmpty)
              _buildEmptyText(
                _isLoading
                    ? 'Đang tải hồ sơ phù hợp...'
                    : 'Chưa tìm thấy hồ sơ phù hợp với ngôn ngữ và bộ lọc đã chọn.',
              )
            else
              ...candidates.map(_buildCandidateCard),
          ],
        ],
      ),
    );
  }

  Widget _buildIntro(ProfileModel profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tìm bạn luyện ${_languageName(profile.targetLang)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ưu tiên người có ngôn ngữ mẹ đẻ là '
              '${_languageName(profile.targetLang)} và đang học '
              '${_languageName(profile.nativeLang)}. '
              'Trình độ trong bộ lọc là trình độ của bạn ấy ở ngôn ngữ bạn nói.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(_errorMessage!),
        trailing: IconButton(
          tooltip: 'Tải lại',
          onPressed: () {
            final profile = context.read<AuthProvider>().currentProfile;
            if (profile != null) _loadData(profile);
          },
          icon: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildEmptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildCandidateCard(ProfileModel candidate) {
    final actionId = 'send:${candidate.userId}';
    final isBusy = _busyActions.contains(actionId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _avatar(candidate),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.displayName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_languageName(candidate.nativeLang)} → '
                        '${_languageName(candidate.targetLang)} · '
                        '${candidate.proficiencyLevel.toUpperCase()}'
                        '${candidate.isOnline ? ' · Đang trực tuyến' : ''}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: isBusy
                    ? null
                    : () => _runAction(actionId, () async {
                          await _repository.sendRequest(
                            requesterId: _loadedUserId!,
                            receiverId: candidate.userId,
                          );
                        }),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: const Text('Kết nối'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequest(BuddyModel match, String userId) {
    final otherUserId = match.otherUserIdFor(userId)!;
    final profile = _profilesById[otherUserId];
    final acceptActionId = 'accept:${match.id}';
    final rejectActionId = 'reject:${match.id}';
    final isBusy = _busyActions.contains(acceptActionId) ||
        _busyActions.contains(rejectActionId);
    return Card(
      child: ListTile(
        leading: profile == null
            ? const CircleAvatar(child: Icon(Icons.person))
            : _avatar(profile),
        title: Text(profile?.displayName ?? 'Người dùng'),
        subtitle: const Text('Muốn kết nối để luyện ngôn ngữ cùng bạn.'),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Từ chối',
              onPressed: isBusy
                  ? null
                  : () => _runAction(rejectActionId, () async {
                        await _repository.respondToRequest(
                          matchId: match.id,
                          receiverId: userId,
                          accept: false,
                        );
                      }),
              icon: const Icon(Icons.close),
            ),
            IconButton(
              tooltip: 'Chấp nhận',
              onPressed: isBusy
                  ? null
                  : () => _runAction(acceptActionId, () async {
                        await _repository.respondToRequest(
                          matchId: match.id,
                          receiverId: userId,
                          accept: true,
                        );
                      }),
              icon: const Icon(Icons.check_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequest(BuddyModel match, String userId) {
    final profile = _profilesById[match.otherUserIdFor(userId)];
    return Card(
      child: ListTile(
        leading: profile == null
            ? const CircleAvatar(child: Icon(Icons.person))
            : _avatar(profile),
        title: Text(profile?.displayName ?? 'Người dùng'),
        subtitle: const Text('Đang chờ người đó phản hồi lời mời.'),
        trailing: const Icon(Icons.hourglass_top),
      ),
    );
  }

  Widget _buildBuddyCard(BuddyModel match, String userId) {
    final profile = _profilesById[match.otherUserIdFor(userId)];
    return Card(
      child: ListTile(
        leading: profile == null
            ? const CircleAvatar(child: Icon(Icons.person))
            : _avatar(profile),
        title: Text(profile?.displayName ?? 'Người dùng'),
        subtitle: Text(
          profile == null
              ? 'Đã ghép cặp'
              : '${_languageName(profile.nativeLang)} → '
                  '${_languageName(profile.targetLang)} · '
                  '${profile.proficiencyLevel.toUpperCase()}'
                  '${profile.isOnline ? ' · Đang trực tuyến' : ''}',
        ),
        trailing: const Icon(Icons.verified, color: Colors.green),
      ),
    );
  }

  Widget _avatar(ProfileModel profile) {
    final avatarUrl = profile.avatarUrl;
    final hasNetworkAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final initials = profile.displayName.trim().isEmpty
        ? '?'
        : profile.displayName.trim().substring(0, 1).toUpperCase();
    return CircleAvatar(
      backgroundImage: hasNetworkAvatar ? NetworkImage(avatarUrl) : null,
      child: hasNetworkAvatar ? null : Text(initials),
    );
  }
}
