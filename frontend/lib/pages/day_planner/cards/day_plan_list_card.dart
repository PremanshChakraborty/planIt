import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/pages/day_planner/models/processed_day_plan.dart';
import 'package:travel_app/pages/day_planner/provider/curr_plan_provider.dart';
import 'package:travel_app/pages/day_planner/screens/create_day_plan.dart';
import 'package:travel_app/pages/day_planner/services/day_plan_service.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/utils/confirmation_dialog.dart';
import 'package:travel_app/widgets/user_info_dialog.dart';

class DayPlanListCard extends StatelessWidget {
  const DayPlanListCard({
    super.key,
    required this.processedPlan,
    required this.ownerId,
    required this.dayPlanService,
    required this.location,
    required this.onDeleted,
    required this.onStarred,
    required this.onMapButtonPressed,
  });
  final ProcessedDayPlan processedPlan;
  final String ownerId;
  final DayPlanService dayPlanService;
  final PlaceModel location;
  final Function() onDeleted;
  final Function(bool isStarred) onStarred;
  final Function() onMapButtonPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final plan = processedPlan.dayPlan;
    final absDate = processedPlan.absoluteDate;
    final imageUrl = processedPlan.creatorImageUrl;
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    final String currUser = Provider.of<Auth>(context, listen: false).user!.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Navigate to details or edit
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Creator Avatar
                GestureDetector(
                  onTap: () {
                    UserInfoDialog.show(context,
                        userId: plan.createdBy.userId,
                        role: "Created Day Plan ${plan.planTitle}");
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: imageUrl == null || imageUrl.isEmpty
                        ? Text(
                            plan.createdBy.userName.isNotEmpty
                                ? plan.createdBy.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.planTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (plan.isStarred) ...[
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                          ],
                          Text(
                            'Day ${plan.day}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateFormat.format(absDate),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Row(
                  children: [
                    Tooltip(
                      message: 'Show on Map',
                      child: InkWell(
                        onTap: () {
                          onMapButtonPressed();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.map_outlined,
                            size: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (currUser == ownerId ||
                        currUser == plan.createdBy.userId)
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangeNotifierProvider(
                                  create: (context) => CurrPlanProvider(
                                      tripId: plan.tripId,
                                      location: location,
                                      dayPlanService: dayPlanService,
                                      savedPlan: plan),
                                  child: CreateDayPlan(),
                                ),
                              ),
                            );
                          }
                          if (value == 'delete') {
                            showConfirmationDialog(
                              context: context,
                              icon: Icons.delete,
                              title: 'Delete Day Plan',
                              message:
                                  'Are you sure you want to delete this day plan?',
                              color: Colors.red,
                            ).then((value) async {
                              if (value == true) {
                                try {
                                  await dayPlanService.deleteDayPlan(plan.id);
                                  onDeleted();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: theme.colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'Dismiss',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                        },
                                      ),
                                    ),
                                  );
                                }
                              }
                            });
                          }
                          if (value == 'star') {
                            try {
                              final bool newIsStarred =
                                  await dayPlanService.toggleStar(
                                plan.id,
                              );
                              onStarred(newIsStarred);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: theme.colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'Dismiss',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit,
                                    color: theme.colorScheme.onSurface),
                                SizedBox(width: 8),
                                Text('Edit',
                                    style: TextStyle(
                                        color: theme.colorScheme.onSurface)),
                              ],
                            ),
                          ),
                          if (currUser == ownerId)
                            PopupMenuItem<String>(
                              value: 'star',
                              child: Row(
                                children: [
                                  Icon(Icons.star_rounded, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text(plan.isStarred ? 'Unstar' : 'Star',
                                      style: TextStyle(color: Colors.amber)),
                                ],
                              ),
                            ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert,
                          size: 24,
                          color: theme.colorScheme.onSurface,
                        ),
                        offset: Offset(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
