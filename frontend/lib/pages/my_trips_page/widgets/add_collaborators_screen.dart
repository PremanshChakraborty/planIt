import 'package:flutter/material.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/services/collaboration_service.dart';

class AddCollaboratorsScreen extends StatefulWidget {
  final String tripId;
  final Auth auth;
  final VoidCallback? onSuccess;

  const AddCollaboratorsScreen({
    super.key,
    required this.tripId,
    required this.auth,
    this.onSuccess,
  });

  @override
  State<AddCollaboratorsScreen> createState() => _AddCollaboratorsScreenState();
}

class _AddCollaboratorsScreenState extends State<AddCollaboratorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final CollaborationService _collaborationService;
  List<User> _searchResults = [];
  List<User> _selectedUsers = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _collaborationService = CollaborationService(auth: widget.auth);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    if (query.length < 1) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final users = await _collaborationService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = users;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.toString();
          _isSearching = false;
          _searchResults = [];
        });
      }
    }
  }

  void _toggleUserSelection(User user) {
    if (_selectedUsers.length >= 5 && !_selectedUsers.contains(user)) {
      return; // Max 5 users selected
    }

    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  bool _isUserSelected(User user) {
    return _selectedUsers.any((selected) => selected.id == user.id);
  }

  void _removeSelectedUser(User user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  Future<void> _addCollaborators() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one user to add'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final userIds = _selectedUsers.map((user) => user.id).toList();
      final result = await _collaborationService.addCollaborators(widget.tripId, userIds);

      if (mounted) {
        setState(() {
          _isSearching = false;
        });

        if (result['success'] == true) {
          final count = result['count'] ?? 0;
          final message = result['message'] ?? 'Collaborators added successfully';

          if (count > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Call onSuccess callback if provided
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            }

            // Pop the screen
            Navigator.of(context).pop(true);
          } else {
            // No new collaborators were added (all were already collaborators)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });

        String errorMessage = 'Failed to add collaborators';
        if (e.toString().contains('No internet connection')) {
          errorMessage = 'No internet connection. Please check your network.';
        } else if (e.toString().contains('Exception:')) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxSelected = _selectedUsers.length >= 5;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Collaborators',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 10.0),
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: _searchController,
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Search users by name...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            color: Colors.grey[500],
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ),
          ),

          // Selected Users Chips
          if (_selectedUsers.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              height: 50,
              padding: EdgeInsets.fromLTRB( 16, 0,16,8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      avatar: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        backgroundImage: user.imageUrl != null && user.imageUrl!.isNotEmpty
                            ? NetworkImage(user.imageUrl!)
                            : null,
                        child: user.imageUrl == null || user.imageUrl!.isEmpty
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      label: Text(
                        user.name,
                        style: TextStyle(fontSize: 13),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[500],
                      ),
                      onDeleted: () => _removeSelectedUser(user),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          width: 1,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),

          // Search Results or Empty State
          Expanded(
            child: _searchController.text.trim().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Start typing to search for users',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : _isSearching
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : _searchError != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Error: $_searchError',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.red[300],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : _searchResults.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_search,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No users found',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  final isSelected = _isUserSelected(user);
                                  final isDisabled = maxSelected && !isSelected;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: InkWell(
                                      onTap: isDisabled ? null : () => _toggleUserSelection(user),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                              : isDisabled
                                                  ? Colors.grey[200]
                                                  : Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.grey[300]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: isDisabled
                                                  ? Colors.grey[300]
                                                  : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                              backgroundImage: user.imageUrl != null &&
                                                      user.imageUrl!.isNotEmpty &&
                                                      !isDisabled
                                                  ? NetworkImage(user.imageUrl!)
                                                  : null,
                                              child: user.imageUrl == null ||
                                                      user.imageUrl!.isEmpty ||
                                                      isDisabled
                                                  ? Text(
                                                      user.name.isNotEmpty
                                                          ? user.name[0].toUpperCase()
                                                          : '?',
                                                      style: TextStyle(
                                                        color: isDisabled
                                                            ? Colors.grey[600]
                                                            : Theme.of(context).colorScheme.primary,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            SizedBox(width: 12),
                                            // Name
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.name,
                                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                      color: isDisabled ? Colors.grey[600] : null,
                                                    ),
                                                  ),
                                                  if (user.email.isNotEmpty)
                                                    Text(
                                                      user.email,
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: isDisabled
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            // Selection Indicator
                                            Icon(
                                              isSelected
                                                  ? Icons.check_circle
                                                  : Icons.add_circle_outline,
                                              color: isDisabled
                                                  ? Colors.grey[400]
                                                  : isSelected
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Colors.grey[400],
                                              size: 28,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
          ),

          // Add Button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedUsers.isEmpty || _isSearching
                      ? null
                      : _addCollaborators,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSearching
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _selectedUsers.isEmpty
                              ? 'Add Collaborators'
                              : 'Add ${_selectedUsers.length} Collaborator${_selectedUsers.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

