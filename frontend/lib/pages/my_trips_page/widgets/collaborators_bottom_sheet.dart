import 'package:flutter/material.dart';
import 'package:travel_app/models/trip.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/services/collaboration_service.dart';
import 'package:travel_app/pages/my_trips_page/widgets/add_collaborators_screen.dart';

class CollaboratorsBottomSheet extends StatefulWidget {
  final Trip trip;
  final Auth auth;
  final VoidCallback onRefresh;

  const CollaboratorsBottomSheet({
    super.key,
    required this.trip,
    required this.auth,
    required this.onRefresh,
  });

  @override
  State<CollaboratorsBottomSheet> createState() => _CollaboratorsBottomSheetState();
}

class _CollaboratorsBottomSheetState extends State<CollaboratorsBottomSheet> {
  bool _isEditMode = false;
  List<User> _editedCollaborators = [];
  Set<String> _removedCollaboratorIds = {};
  bool _isSaving = false;
  late final CollaborationService _collaborationService;

  @override
  void initState() {
    super.initState();
    _collaborationService = CollaborationService(auth: widget.auth);
    if (widget.trip.collaborators != null) {
      _editedCollaborators = List<User>.from(widget.trip.collaborators!);
    }
  }

  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
      _removedCollaboratorIds.clear();
      if (widget.trip.collaborators != null) {
        _editedCollaborators = List<User>.from(widget.trip.collaborators!);
      }
    });
  }

  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
      _removedCollaboratorIds.clear();
      if (widget.trip.collaborators != null) {
        _editedCollaborators = List<User>.from(widget.trip.collaborators!);
      }
    });
  }

  void _toggleCollaboratorRemoval(User collaborator) {
    setState(() {
      if (_removedCollaboratorIds.contains(collaborator.id)) {
        _removedCollaboratorIds.remove(collaborator.id);
      } else {
        _removedCollaboratorIds.add(collaborator.id);
      }
    });

    // Exit edit mode if no collaborators are marked for removal
    if (_removedCollaboratorIds.isEmpty) {
      _exitEditMode();
    }
  }

  bool _isCollaboratorRemoved(User collaborator) {
    return _removedCollaboratorIds.contains(collaborator.id);
  }

  Future<void> _saveCollaborators() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Filter out removed collaborators
      final currentCollaborators = _editedCollaborators.where((c) => !_removedCollaboratorIds.contains(c.id)).toList();
      final collaboratorIds = currentCollaborators.map((c) => c.id).toList();

      await _collaborationService.updateCollaborators(widget.trip.id, collaboratorIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collaborators updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRefresh();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        String errorMessage = 'Failed to update collaborators';
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
    final allCollaborators = widget.trip.collaborators ?? [];
    final hasCollaborators = allCollaborators.isNotEmpty;
    // In edit mode, show all collaborators. Otherwise show current list
    final displayCollaborators = _isEditMode ? _editedCollaborators : allCollaborators;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Collaborators',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Collaborators list
          if (displayCollaborators.isNotEmpty)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: displayCollaborators.length,
                itemBuilder: (context, index) {
                  final collaborator = displayCollaborators[index];
                  final isRemoved = _isEditMode && _isCollaboratorRemoved(collaborator);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                    child: Row(
                      children: [
                        // Circular Avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          backgroundImage: collaborator.imageUrl != null && collaborator.imageUrl!.isNotEmpty
                            ? NetworkImage(collaborator.imageUrl!)
                            : null,
                          child: collaborator.imageUrl == null || collaborator.imageUrl!.isEmpty
                            ? Text(
                                collaborator.name.isNotEmpty 
                                  ? collaborator.name[0].toUpperCase() 
                                  : '?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
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
                                collaborator.name,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  decoration: isRemoved ? TextDecoration.lineThrough : null,
                                  color: isRemoved ? Colors.grey : null,
                                ),
                              ),
                              if (collaborator.email.isNotEmpty)
                                Text(
                                  collaborator.email,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isRemoved ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Remove/Add button (only for owners in edit mode)
                        if (widget.trip.isOwner == true && _isEditMode)
                          IconButton(
                            icon: Icon(
                              isRemoved ? Icons.remove_circle : Icons.remove_circle_outline,
                              color: isRemoved ? Colors.red : Colors.grey[600],
                            ),
                            onPressed: () => _toggleCollaboratorRemoval(collaborator),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            tooltip: isRemoved ? 'Add back' : 'Remove',
                          ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'No collaborators yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          // Edit mode buttons (Save/Cancel)
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _exitEditMode,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveCollaborators,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isSaving ? 0 : 2,
                      ).copyWith(
                        backgroundColor: _isSaving 
                          ? MaterialStateProperty.all(Theme.of(context).colorScheme.primary.withOpacity(0.6))
                          : null,
                      ),
                      child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          // Add Collaborators button (only for owners, when not in edit mode)
          if (widget.trip.isOwner == true && !_isEditMode)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCollaboratorsScreen(
                          tripId: widget.trip.id,
                          auth: widget.auth,
                          onSuccess: widget.onRefresh,
                        ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        widget.onRefresh();
                      }
                    });
                  },
                  icon: Icon(Icons.person_add, size: 20),
                  label: Text('Add Collaborators'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          // Remove Collaborators button (only for owners, when not in edit mode and has collaborators)
          if (widget.trip.isOwner == true && !_isEditMode && hasCollaborators)
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _enterEditMode,
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('Remove Collaborators'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

