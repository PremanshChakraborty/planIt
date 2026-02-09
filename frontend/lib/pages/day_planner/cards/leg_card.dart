import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/pages/day_planner/provider/day_plan_map_provider.dart';
import 'package:travel_app/pages/day_planner/widgets/place_details_dialog.dart';
import 'package:travel_app/providers/google_services_provider.dart';

class LegCard extends StatelessWidget {
  const LegCard(
      {super.key,
      required this.theme,
      required this.index,
      required this.provider});

  final ThemeData theme;
  final DayPlanMapProvider provider;
  final int index;

  @override
  Widget build(BuildContext context) {
    final leg = provider.route!.legs[index];
    final startNode = provider.plan.sequence[index];
    final endNode = provider.plan.sequence[index + 1];
    return GestureDetector(
      key: provider.locationKeys['day plan map $index'],
      onTap: () {
        provider.setSelectedLegIndex(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: provider.selectedLegIndex == index
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: provider.selectedLegIndex == index ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 10),
                    Icon(
                      Icons.circle_outlined,
                      size: 13,
                      color: theme.colorScheme.primary,
                    ),
                    Container(
                      height: 14,
                      width: 1,
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                PlaceDetailsDialog.show(
                                  context,
                                  fetchPlaceDetails:
                                      Provider.of<GoogleServicesProvider>(
                                              context,
                                              listen: false)
                                          .fetchPlaceDetails,
                                  placeId: startNode.placeId,
                                  addedBy: startNode.addedBy,
                                );
                              },
                              child: Text(
                                startNode.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              (index + 1).toString(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          PlaceDetailsDialog.show(
                            context,
                            fetchPlaceDetails:
                                Provider.of<GoogleServicesProvider>(context,
                                        listen: false)
                                    .fetchPlaceDetails,
                            placeId: endNode.placeId,
                            addedBy: endNode.addedBy,
                          );
                        },
                        child: Text(
                          endNode.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
                height: 1, color: theme.colorScheme.outline.withOpacity(0.1)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_car_outlined,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      leg.localizedValues?.distance?.text ?? "--",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 16,
                  width: 1,
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      leg.localizedValues?.duration?.text ?? "--",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
