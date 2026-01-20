// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      // ignore: use_build_context_synchronously
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications()
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = provider.notifications[index];
                    final bool isInvitation = notif.type == 'task_invitation';
                    final bool isUnread = !notif.isRead;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isUnread 
                            ? AppTheme.primaryColor.withValues(alpha: 0.3) 
                            : theme.dividerColor.withValues(alpha: 0.05),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          onTap: () async {
                             if (isUnread) await provider.markAsRead(notif.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Circular Icon Background
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isInvitation 
                                          ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                                          : theme.colorScheme.secondary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isInvitation ? Icons.person_add_rounded : Icons.notifications_rounded,
                                        color: isInvitation ? AppTheme.primaryColor : theme.colorScheme.secondary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: textTheme.titleMedium?.copyWith(
                                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (isUnread)
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.body,
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: theme.hintColor,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            timeago.format(notif.createdAt),
                                            style: textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (isInvitation && isUnread) ...[
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            try {
                                              await provider.declineInvitation(notif.data['taskId'], notif.id);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                              }
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.colorScheme.error,
                                            side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: const Text('Decline'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await provider.acceptInvitation(notif.data['taskId'], notif.id);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 2,
                                          ),
                                          child: const Text('Accept'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 64, color: theme.disabledColor),
          ),
          const SizedBox(height: 20),
          Text(
            'All quiet for now',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.disabledColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something happens.',
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
