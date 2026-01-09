import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:travel_app/pages/live_trip_page/trip_details_page.dart';
import 'package:travel_app/pages/my_trips_page/widgets/edit_trip_card.dart';
import 'package:travel_app/pages/my_trips_page/widgets/add_collaborators_screen.dart';
import 'package:travel_app/pages/my_trips_page/widgets/collaborators_bottom_sheet.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/services/trip_services.dart';
import '../../../models/trip.dart';
import '../../../widgets/user_info_dialog.dart';

class TripTile extends StatefulWidget {
  final Trip trip;
  final VoidCallback onRefresh;
  final Auth auth;
  const TripTile(
      {super.key,
      required this.trip,
      required this.onRefresh,
      required this.auth});

  @override
  State<TripTile> createState() => _TripTileState();
}

class _TripTileState extends State<TripTile> {
  void editTrip() async {
    bool? success = await showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        //constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        context: context,
        builder: (context) => EditTripCard(
            trip: widget.trip,
            tripService: TripService(
              auth: widget.auth,
            )));
    if (success != null && success == true) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Trip updated successfully')));
        widget.onRefresh();
      }
    }
  }

  void showCollaboratorsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return CollaboratorsBottomSheet(
          trip: widget.trip,
          auth: widget.auth,
          onRefresh: widget.onRefresh,
        );
      },
    );
  }

  void showOwnerInfo() {
    UserInfoDialog.show(context, user: widget.trip.user, role: 'Trip Owner');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        height: MediaQuery.sizeOf(context).width * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 7,
            ),
          ],
        ),
        child: Column(
          children: [
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14.0, 14.0, 14.0, 0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.trip.locations.length > 1
                                    ? '${widget.trip.locations[1].placeName} Trip'
                                    : widget.trip.locations.isNotEmpty
                                        ? '${widget.trip.locations[0].placeName} Trip'
                                        : 'Trip',
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    child: Text(
                                      DateFormat('dd-MM-yyyy')
                                          .format(widget.trip.startDate),
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: widget.trip.isOwner == true
                                          ? Colors.purple[300]!
                                          : Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                    ),
                                    child: Text(
                                      widget.trip.isOwner == true
                                          ? 'Owner'
                                          : 'Collaborator',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        // Show edit button if owner, or owner avatar if collaborator
                        if (widget.trip.isOwner == true)
                          IconButton(
                              onPressed: () {
                                editTrip();
                              },
                              icon: Icon(Icons.edit_outlined))
                        else
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: GestureDetector(
                              onTap: () => showOwnerInfo(),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                backgroundImage: widget.trip.user.imageUrl !=
                                            null &&
                                        widget.trip.user.imageUrl!.isNotEmpty
                                    ? NetworkImage(widget.trip.user.imageUrl!)
                                    : null,
                                child: widget.trip.user.imageUrl == null ||
                                        widget.trip.user.imageUrl!.isEmpty
                                    ? Text(
                                        widget.trip.user.name.isNotEmpty
                                            ? widget.trip.user.name[0]
                                                .toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 25.0, 0, 0),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: widget.trip.locations.length,
                          itemBuilder: (context, index) {
                            // Get the current location
                            final location = widget.trip.locations[index];

                            // Calculate cumulative day
                            int day = 1; // Start from day 1
                            for (int i = 0; i < index; i++) {
                              day += widget.trip.locations[i].day;
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Location Icon & Dotted Line (Aligned Left)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16), // Offset to the left
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Icon(Icons.location_on,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                      ),
                                      if (index <
                                          widget.trip.locations.length -
                                              1) // Add line for all except last item
                                        DottedLine(
                                          direction: Axis.vertical,
                                          lineLength: 40,
                                          dashColor: Colors.grey,
                                          lineThickness: 2,
                                          dashLength: 4,
                                          dashGapLength: 3,
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    width:
                                        5), // Space between dotted line and text
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment
                                          .center, // Align text with day number
                                      children: [
                                        Expanded(
                                          child: Text(
                                            index == 0
                                                ? '${location.placeName} - Start'
                                                : location.placeName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          'Day $day',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            // Footer Section
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // First row: Guests and View Details button
                  if (widget.trip.collaborators != null &&
                          widget.trip.collaborators!.isNotEmpty ||
                      widget.trip.isOwner == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Collaborators display (clickable)
                          Expanded(
                            child: InkWell(
                              onTap: showCollaboratorsDialog,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Show avatar stack if collaborators exist, else show group icon
                                    widget.trip.collaborators != null &&
                                            widget
                                                .trip.collaborators!.isNotEmpty
                                        ? Stack(
                                            alignment: Alignment.center,
                                            clipBehavior: Clip.none,
                                            children: [
                                              if (widget.trip.collaborators!
                                                      .length >
                                                  1)
                                                Positioned(
                                                  left: 6,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(0.7),
                                                          width: 2,
                                                        )),
                                                    child: CircleAvatar(
                                                      radius: 9,
                                                      backgroundColor: Colors
                                                          .white
                                                          .withOpacity(0.3),
                                                      child: Text(
                                                        '+${widget.trip.collaborators!.length - 1}',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Container(
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                      width: 1,
                                                    )),
                                                child: CircleAvatar(
                                                  radius: 11,
                                                  backgroundColor: Colors.white,
                                                  backgroundImage: widget
                                                                  .trip
                                                                  .collaborators![
                                                                      0]
                                                                  .imageUrl !=
                                                              null &&
                                                          widget
                                                              .trip
                                                              .collaborators![0]
                                                              .imageUrl!
                                                              .isNotEmpty
                                                      ? NetworkImage(widget
                                                          .trip
                                                          .collaborators![0]
                                                          .imageUrl!)
                                                      : null,
                                                  child: widget
                                                                  .trip
                                                                  .collaborators![
                                                                      0]
                                                                  .imageUrl ==
                                                              null ||
                                                          widget
                                                              .trip
                                                              .collaborators![0]
                                                              .imageUrl!
                                                              .isEmpty
                                                      ? Text(
                                                          widget
                                                                  .trip
                                                                  .collaborators![
                                                                      0]
                                                                  .name
                                                                  .isNotEmpty
                                                              ? widget
                                                                  .trip
                                                                  .collaborators![
                                                                      0]
                                                                  .name[0]
                                                                  .toUpperCase()
                                                              : '?',
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Icon(Icons.group_outlined,
                                            color: Colors.white, size: 18),
                                    SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        widget.trip.collaborators != null &&
                                                widget.trip.collaborators!
                                                    .isNotEmpty
                                            ? '${widget.trip.collaborators!.length} collaborator${widget.trip.collaborators!.length > 1 ? 's' : ''}'
                                            : 'No collaborators',
                                        style: TextStyle(
                                          color: widget.trip.collaborators !=
                                                      null &&
                                                  widget.trip.collaborators!
                                                      .isNotEmpty
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                          fontWeight:
                                              widget.trip.collaborators !=
                                                          null &&
                                                      widget.trip.collaborators!
                                                          .isNotEmpty
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right,
                                      color:
                                          widget.trip.collaborators != null &&
                                                  widget.trip.collaborators!
                                                      .isNotEmpty
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.8),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Add Collaborators button (only for owners)
                          if (widget.trip.isOwner == true)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddCollaboratorsScreen(
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
                              icon: Icon(Icons.person_add, size: 16),
                              label: Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  // Second row: Collaborators info and Add Collaborators button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 10),
                          Icon(
                            Icons.people_alt_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 6),
                          Text(widget.trip.guests.toString(),
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.35,
                        height: MediaQuery.sizeOf(context).width * 0.09,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        TripDetailsPage(trip: widget.trip)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                          ),
                          child: Text(
                            'View Details',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
