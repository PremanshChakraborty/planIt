import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:travel_app/config/constants.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/widgets/user_info_dialog.dart';

class HotelCard extends StatefulWidget {
  final HotelModel hotel;
  final User owner;

  const HotelCard({
    required this.hotel,
    required this.owner,
  });

  @override
  State<HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<HotelCard> {
  String? _photoUrl;
  bool _isLoading = true;
  late GooglePlace _googlePlace;

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(Constants.googlePlacesApiKey);
    _fetchFreshPhoto();
  }

  Future<void> _fetchFreshPhoto() async {
    try {
      final details = await _googlePlace.details.get(widget.hotel.placeId);
      if (details?.result?.photos?.isNotEmpty == true) {
        if (mounted) {
          setState(() {
            _photoUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${details!.result!.photos!.first.photoReference}&key=${Constants.googlePlacesApiKey}';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: _isLoading
                ? Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                        child: const Center(child: Icon(Icons.hotel, size: 40)),
                      ),
          ),
          // Hotel Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 180,
                      child: Text(
                        widget.hotel.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Spacer(),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(
                      ' ${widget.hotel.rating}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (widget.hotel.addedBy != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      UserInfoDialog.show(
                        context,
                        userId: widget.hotel.addedBy!.userId,
                        role: 'Added this hotel',
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            widget.hotel.addedBy!.userName.isNotEmpty
                                ? widget.hotel.addedBy!.userName[0]
                                    .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'by ${widget.hotel.addedBy!.userName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
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
    );
  }
}
