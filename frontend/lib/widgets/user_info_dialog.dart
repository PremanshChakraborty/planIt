import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/services/user_service.dart';

class UserInfoDialog extends StatefulWidget {
  final User? user;
  final String? userId;
  final String? role;

  const UserInfoDialog({
    super.key,
    this.user,
    this.userId,
    this.role,
  }) : assert(user != null || userId != null,
            'Either user or userId must be provided');

  @override
  State<UserInfoDialog> createState() => _UserInfoDialogState();

  static void show(BuildContext context,
      {User? user, String? userId, String? role}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UserInfoDialog(user: user, userId: userId, role: role);
      },
    );
  }
}

class _UserInfoDialogState extends State<UserInfoDialog> {
  User? _user;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _user = widget.user;
    } else if (widget.userId != null) {
      _fetchUser();
    }
  }

  Future<void> _fetchUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<Auth>(context, listen: false);
      final userService = UserService(auth: auth);
      final user = await userService.getUserById(widget.userId!);

      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: SizedBox(
        width: double.infinity,
        child: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _user != null
                    ? _buildUserInfo()
                    : SizedBox(),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 24),
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading user info...'),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 24),
        Icon(Icons.error_outline, size: 60, color: Colors.red),
        SizedBox(height: 16),
        Text(
          'Failed to load user',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 8),
        Text(
          _error!.replaceAll('Exception: ', ''),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 24),
        CircleAvatar(
          radius: 60,
          backgroundColor: Theme.of(context).colorScheme.primary,
          backgroundImage:
              _user!.imageUrl != null && _user!.imageUrl!.isNotEmpty
                  ? NetworkImage(_user!.imageUrl!)
                  : null,
          child: _user!.imageUrl == null || _user!.imageUrl!.isEmpty
              ? Text(
                  _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                )
              : null,
        ),
        SizedBox(height: 16),
        Text(
          _user!.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          _user!.email,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        if (widget.role != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.role!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 16),
      ],
    );
  }
}
