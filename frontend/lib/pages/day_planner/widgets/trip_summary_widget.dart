import 'package:flutter/material.dart';
import 'package:travel_app/pages/day_planner/models/day_plan.dart';
import 'package:travel_app/pages/day_planner/models/routes_response.dart';
import 'package:travel_app/pages/day_planner/provider/day_plan_map_provider.dart';
import 'package:travel_app/widgets/user_info_dialog.dart';

class TripSummaryWidget extends StatelessWidget {
  final RoutesResponse? route;
  final DayPlan plan;
  final TravelMode travelMode;
  final ValueChanged<TravelMode> onTravelModeChanged;
  final VoidCallback onOptimize;
  final VoidCallback onRevert;
  final VoidCallback onEdit;
  final bool isOptimized;
  final bool showingOptimized;
  final RoutesResponse? oldRoute;
  final bool isAllowedToEdit;
  final Function(bool asCopy, String newTitle) onSave;

  const TripSummaryWidget({
    super.key,
    required this.route,
    required this.plan,
    required this.travelMode,
    required this.onTravelModeChanged,
    required this.onOptimize,
    required this.onEdit,
    required this.isOptimized,
    required this.showingOptimized,
    required this.onRevert,
    required this.oldRoute,
    required this.isAllowedToEdit,
    required this.onSave,
  });

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SaveOptimizationDialog(
        initialTitle: plan.planTitle,
        isAllowedToEdit: isAllowedToEdit,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final String distance = route?.localizedValues?.distance?.text ?? '-';
    final String duration = route?.localizedValues?.duration?.text ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Metrics & Edit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildMetric(
                      context,
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: duration,
                      oldValue: oldRoute?.localizedValues?.duration?.text,
                    ),
                    const Spacer(),
                    _buildTravelModeToggle(context),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Row 2: Controls
          Row(
            children: [
              _buildMetric(
                context,
                icon: Icons.straighten,
                label: 'Distance',
                value: distance,
                oldValue: oldRoute?.localizedValues?.distance?.text,
              ),
              const Spacer(),
              SizedBox(
                height: 35,
                child: isOptimized
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            'Optimized',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      )
                    : showingOptimized
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: onRevert,
                                child: Container(
                                  height: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                    size: 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Save optimization',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () => _showSaveDialog(context),
                              ),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: onOptimize,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: const Icon(Icons.auto_awesome_outlined,
                                size: 16),
                            label: const Text('Optimize Sequence'),
                          ),
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Divider(
                height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
          ),

          // Row 3: User Info
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserLabel(context, 'Created by',
                        plan.createdBy.userName, plan.createdBy.userId),
                    if (plan.updatedBy != null)
                      _buildUserLabel(context, 'Updated by',
                          plan.updatedBy!.userName, plan.updatedBy!.userId),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  backgroundColor:
                      colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  foregroundColor: colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit Route',
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      String? oldValue}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.tertiary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: showingOptimized
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              showingOptimized ? oldValue ?? "" : label,
              style: theme.textTheme.labelSmall?.copyWith(
                decoration:
                    showingOptimized ? TextDecoration.lineThrough : null,
                color: showingOptimized
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTravelModeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            context,
            icon: Icons.directions_car_filled_outlined,
            isSelected: travelMode == TravelMode.DRIVE,
            onTap: () => onTravelModeChanged(TravelMode.DRIVE),
          ),
          _buildToggleButton(
            context,
            icon: Icons.two_wheeler_outlined,
            isSelected: travelMode == TravelMode.TWO_WHEELER,
            onTap: () => onTravelModeChanged(TravelMode.TWO_WHEELER),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context,
      {required IconData icon,
      required bool isSelected,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 21,
          color:
              isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildUserLabel(
      BuildContext context, String label, String userName, String userId) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        UserInfoDialog.show(context, userId: userId);
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
            children: [
              TextSpan(text: '$label '),
              TextSpan(
                text: userName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveOptimizationDialog extends StatefulWidget {
  final String initialTitle;
  final bool isAllowedToEdit;
  final Function(bool asCopy, String newTitle) onSave;

  const _SaveOptimizationDialog({
    required this.initialTitle,
    required this.isAllowedToEdit,
    required this.onSave,
  });

  @override
  State<_SaveOptimizationDialog> createState() =>
      _SaveOptimizationDialogState();
}

class _SaveOptimizationDialogState extends State<_SaveOptimizationDialog> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.save_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Save Optimization",
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Plan Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.isAllowedToEdit) ...[
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        foregroundColor: theme.colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        widget.onSave(false, _titleController.text);
                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    widget.onSave(true, _titleController.text);
                    Navigator.pop(context);
                  },
                  child: const Text("Save as Copy"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
