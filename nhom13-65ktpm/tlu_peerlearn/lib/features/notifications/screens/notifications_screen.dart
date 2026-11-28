import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_container.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  IconData _iconForType(String type) {
    switch (type) {
      case 'invitation':
        return Icons.mail_outline;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'joined':
        return Icons.person_add_outlined;
      case 'session':
        return Icons.event_available_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationServiceProvider)
                  .markAllAsRead(userId);
              ref.invalidate(userNotificationsProvider(userId));
            },
            child: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(userNotificationsProvider(userId)),
        child: ResponsiveContainer(
          maxWidth: 780,
          padding: const EdgeInsets.all(16),
          child: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi tải thông báo: $e')),
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn chưa có thông báo nào.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                );
              }

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final AppNotification n = items[index];
                  final colorScheme = Theme.of(context).colorScheme;
                  return Card(
                    color: n.isRead
                        ? Colors.white
                        : colorScheme.primaryContainer.withValues(alpha: 0.25),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: n.isRead
                            ? Colors.grey.shade200
                            : colorScheme.primaryContainer,
                        child: Icon(
                          _iconForType(n.type),
                          color: n.isRead
                              ? Colors.grey.shade700
                              : colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight:
                              n.isRead ? FontWeight.w500 : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(n.body),
                          const SizedBox(height: 4),
                          Text(
                            '${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')} • ${n.createdAt.day}/${n.createdAt.month}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: n.isRead
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () async {
                        if (!n.isRead) {
                          await ref
                              .read(notificationServiceProvider)
                              .markAsRead(n.id);
                          ref.invalidate(userNotificationsProvider(userId));
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

