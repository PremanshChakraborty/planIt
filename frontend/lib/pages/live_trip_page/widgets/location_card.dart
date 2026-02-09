import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/pages/live_trip_page/widgets/attraction_card.dart';
import 'package:travel_app/pages/live_trip_page/widgets/hotel_card.dart';
import 'package:travel_app/widgets/user_info_dialog.dart';

class LocationCard extends StatefulWidget {
  final User owner;
  final PlaceModel place;
  final bool isStartLocation;
  final int arrivalDay;
  final int departureDay;
  final DateTime arrivalDate;
  final VoidCallback onHotelsTap;
  final VoidCallback onAttractionsTap;
  final String tripId;
  final int locationIndex;
  final VoidCallback onRefresh;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback? onTap;
  final GlobalKey? cardKey;

  const LocationCard({
    required this.owner,
    required this.place,
    required this.isStartLocation,
    required this.arrivalDay,
    required this.departureDay,
    required this.arrivalDate,
    required this.onHotelsTap,
    required this.onAttractionsTap,
    required this.tripId,
    required this.locationIndex,
    required this.onRefresh,
    this.isSelected = false,
    this.isExpanded = false,
    this.onTap,
    this.cardKey,
  });

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(LocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with external expansion state when it changes
    if (widget.isExpanded && !_isExpanded) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final datezformat = DateFormat('d MMM yyyy');
    final effectivelyExpanded = widget.isExpanded || _isExpanded;

    String dayRangeText;
    if (widget.isStartLocation) {
      dayRangeText = 'Start Date: ${datezformat.format(widget.arrivalDate)}';
    } else if (widget.arrivalDay == widget.departureDay) {
      dayRangeText =
          'Day ${widget.arrivalDay}: ${datezformat.format(widget.arrivalDate)}';
    } else {
      dayRangeText =
          'Day ${widget.arrivalDay}-${widget.departureDay}: ${datezformat.format(widget.arrivalDate)}';
    }
    return GestureDetector(
      key: widget.cardKey,
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: widget.isSelected
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSecondary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            if (widget.isSelected)
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: Column(
          children: [
            // Location Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left side: Date, location name, and added-by info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayRangeText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          widget.place.placeName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!widget.isStartLocation) ...[
                          SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              UserInfoDialog.show(
                                context,
                                userId: widget.place.addedBy != null
                                    ? widget.place.addedBy!.userId
                                    : widget.owner.id,
                                role: 'Added this location',
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: theme.colorScheme.primary,
                                  child: Text(
                                    (widget.place.addedBy != null
                                            ? widget.place.addedBy!.userName[0]
                                            : widget.owner.name[0])
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'by ${widget.place.addedBy != null ? widget.place.addedBy!.userName : widget.owner.name}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
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
                  // Right side: Action buttons
                  if (!widget.isStartLocation) ...[
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Explore Page',
                          child: GestureDetector(
                            onTap: widget.onAttractionsTap,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Icon(
                                  Icons.search,
                                  color: theme.colorScheme.onSurface,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                effectivelyExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              Text(
                                'Saved',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: (!widget.isStartLocation && effectivelyExpanded)
                  ? Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16, top: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                            height: 1,
                          ),
                          SizedBox(
                            height: 6,
                          ),
                          // Hotels Section
                          Text(
                            'Hotels',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.place.hotels == null ||
                              widget.place.hotels!.isEmpty)
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hotel_outlined,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  Text(
                                    'No hotels saved yet',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: widget.onHotelsTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search,
                                            size: 18,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Find Hotels',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              height: 185,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.place.hotels!.length,
                                itemBuilder: (context, index) {
                                  final hotel = widget.place.hotels![index];
                                  return HotelCard(
                                    hotel: hotel,
                                    owner: widget.owner,
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 16),
                          // Attractions Section
                          Text(
                            'Attractions',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.place.attractions == null ||
                              widget.place.attractions!.isEmpty)
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.attractions_outlined,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No attractions saved yet',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: widget.onAttractionsTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search,
                                            size: 18,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Find Attractions',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              height: 185,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.place.attractions!.length,
                                itemBuilder: (context, index) {
                                  final attraction =
                                      widget.place.attractions![index];
                                  return AttractionCard(
                                    attraction: attraction,
                                    owner: widget.owner,
                                    tripId: widget.tripId,
                                    locationIndex: widget.locationIndex,
                                    onRemove: widget.onRefresh,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    )
                  : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
