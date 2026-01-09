import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/config/constants.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/services/trip_services.dart';
import 'package:travel_app/widgets/user_info_dialog.dart';


class AttractionCard extends StatefulWidget {
  final AttractionModel attraction;
  final User owner;
  final String tripId;
  final int locationIndex;
  final VoidCallback onRemove;

  const AttractionCard({
    required this.attraction,
    required this.owner,
    required this.tripId,
    required this.locationIndex,
    required this.onRemove,
  });

  @override
  State<AttractionCard> createState() => _AttractionCardState();
}

class _AttractionCardState extends State<AttractionCard> {
  bool _isDeleteMode = false;
  String? _photoUrl;
  bool _isLoadingPhoto = true;
  late GooglePlace _googlePlace;

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(Constants.googlePlacesApiKey);
    _fetchFreshPhoto();
  }

  Future<void> _fetchFreshPhoto() async {
    try {
      final details = await _googlePlace.details.get(widget.attraction.placeId);
      if (details?.result?.photos?.isNotEmpty == true) {
        if (mounted) {
          setState(() {
            _photoUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${details!.result!.photos!.first.photoReference}&key=${Constants.googlePlacesApiKey}';
            _isLoadingPhoto = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingPhoto = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPhoto = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade100,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              const SizedBox(width: 10),
              Text(
                'Remove Attraction',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove "${widget.attraction.name}" from this location?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    // If confirmed, remove the attraction
    if (confirmed == true) {
      try {
        final tripService = TripService(
          auth: Provider.of<Auth>(context, listen: false),
        );
        await tripService.addRemoveAttractionToTrip(
          widget.tripId,
          widget.attraction,
          widget.locationIndex,
        );
        widget.onRemove();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove attraction: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = Provider.of<Auth>(context, listen: false).user;
    final isOwner = currentUser?.id == widget.owner.id;

    return GestureDetector(
      onLongPress: isOwner
          ? () {
              setState(() {
                _isDeleteMode = true;
              });
            }
          : null,
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attraction Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: _isLoadingPhoto
                          ? Container(
                              height: 100,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : _photoUrl != null
                              ? Image.network(
                                  _photoUrl!,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Container(
                                      height: 100,
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                          child: Icon(Icons.image, size: 40)),
                                    );
                                  },
                                )
                              : Container(
                                  height: 100,
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                      child: Icon(Icons.attractions, size: 40)),
                                ),
                    ),
                    if (isOwner)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _showDeleteConfirmation,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.bookmark,
                              color: theme.colorScheme.primary,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Attraction Details
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.attraction.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.attraction.type.replaceAll('_', ' '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondary,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            ' ${widget.attraction.rating}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondary,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      if (widget.attraction.addedBy != null) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            UserInfoDialog.show(
                              context,
                              userId: widget.attraction.addedBy!.userId,
                              role: 'Added this attraction',
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  widget.attraction.addedBy!.userName.isNotEmpty
                                      ? widget.attraction.addedBy!.userName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'by ${widget.attraction.addedBy!.userName}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Delete Overlay
            if (_isDeleteMode)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: _showDeleteConfirmation,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDeleteMode = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
