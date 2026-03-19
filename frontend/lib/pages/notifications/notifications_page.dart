import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/notification.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late NotificationService _notificationService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<Auth>(context, listen: false);
    _notificationService = NotificationService(auth: auth);
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications = await _notificationService.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 8) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if ((difference.inDays / 7).floor() >= 1) {
      return '1 week ago';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return '1 day ago';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return '1 hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return '1 minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: colorScheme.surface,
      ),
      body: SafeArea(
        child: _buildContent(colorScheme, textTheme),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load notifications',
              style: textTheme.titleMedium?.copyWith(color: colorScheme.error),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchNotifications();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final isUnread = !notification.read;

        return InkWell(
          onTap: () {
            // TODO: Mark as read and navigate
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUnread
                  ? colorScheme.primary.withOpacity(0.05)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.onSurface.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Actor Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  backgroundImage: notification.actorImageUrl != null &&
                          notification.actorImageUrl!.isNotEmpty
                      ? NetworkImage(notification.actorImageUrl!)
                      : null,
                  child: (notification.actorImageUrl == null ||
                          notification.actorImageUrl!.isEmpty)
                      ? Icon(
                          Icons.notifications_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.normal,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (notification.tripName != null &&
                              notification.tripName!.isNotEmpty) ...[
                            Icon(
                              Icons.flight_takeoff,
                              size: 12,
                              color: colorScheme.primary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                notification.tripName!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '•',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _getTimeAgo(notification.createdAt),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread Indicator Dot
                if (isUnread)
                  Container(
                    margin: const EdgeInsets.only(top: 8, left: 8),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
