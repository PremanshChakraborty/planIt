import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/pages/day_planner/models/plan_block.dart';
import 'package:travel_app/pages/day_planner/provider/curr_plan_provider.dart';
import 'package:travel_app/pages/day_planner/provider/day_plan_map_provider.dart';
import 'package:travel_app/pages/day_planner/screens/day_plan_map_page.dart';
import 'package:travel_app/providers/google_services_provider.dart';
import 'package:travel_app/pages/day_planner/cards/available_block_card.dart';
import 'package:travel_app/pages/day_planner/widgets/outline_button.dart';
import 'package:travel_app/pages/day_planner/cards/sequence_block_card.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:travel_app/pages/day_planner/widgets/place_details_dialog.dart';
import 'package:travel_app/widgets/user_info_dialog.dart';

class CreateDayPlan extends StatefulWidget {
  const CreateDayPlan({
    super.key,
  });

  @override
  State<CreateDayPlan> createState() => _CreateDayPlanState();
}

class _CreateDayPlanState extends State<CreateDayPlan> {
  bool _showOnlyUnselected = false;
  @override
  Widget build(BuildContext context) {
    return Consumer<CurrPlanProvider>(
      builder: (context, provider, child) {
        if (provider.error.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.error),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
              provider.clearError();
            }
          });
        }

        final theme = Theme.of(context);
        final List<PlanBlock> availableBlocks = _showOnlyUnselected
            ? provider.currPlan.blocks
                .where((block) => !provider.editingSeq!.contains(block))
                .toList()
            : provider.currPlan.blocks;
        final List<PlanBlock> displaySequence = provider.isEditing
            ? provider.editingSeq!
            : provider.savedPlan!.sequence;

        // Wrapper method to show place details dialog
        void showPlaceDetails(PlanBlock block) {
          PlaceDetailsDialog.show(
            context,
            fetchPlaceDetails:
                Provider.of<GoogleServicesProvider>(context, listen: false)
                    .fetchPlaceDetails,
            placeId: block.placeId,
            addedBy: block.addedBy,
          );
        }

        Widget proxyDecorator(
            Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue =
                  Curves.easeInOut.transform(animation.value);
              final double elevation = lerpDouble(0, 2, animValue)!;
              final double scale = lerpDouble(1, 1.05, animValue)!;
              return Transform.scale(
                scale: scale,
                child: Material(
                  elevation: elevation,
                  borderRadius: BorderRadius.circular(12),
                  child: AvailableBlockCard(
                    block: displaySequence[index],
                    index: index,
                    onInfoTap: () => showPlaceDetails(displaySequence[index]),
                  ),
                ),
              );
            },
            child: child,
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
              toolbarHeight: 60,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Day Plan",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    provider.location.placeName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
              actions: [
                if (!provider.isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.map_outlined,
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                      onTap: () {
                        final dayPlanService = provider.dayPlanService;
                        final location = provider.location;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              final theme = Theme.of(context);
                              return ChangeNotifierProvider(
                                create: (context) => DayPlanMapProvider(
                                  locationName: location.placeName,
                                  plan: provider.savedPlan!,
                                  dayPlanService: dayPlanService,
                                  theme: theme,
                                ),
                                child: DayPlanMapPage(
                                    theme: theme, location: location, isOwner: true,),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, 0, 16, provider.isEditing ? 0 : 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.title,
                        color: theme.colorScheme.onSurface,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: provider.isEditing
                            ? TextField(
                                controller: provider.planTitleController,
                                onChanged: (value) {
                                  provider.onPlanTitleChanged(value);
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Plan Title',
                                  hintStyle:
                                      theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              )
                            : Text(
                                provider.savedPlan?.planTitle ??
                                    'Untitled Plan',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.normal),
                              ),
                      ),
                      provider.isEditing
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                              child: SizedBox(
                                width: 90,
                                child: DropdownButtonFormField<int>(
                                  value: provider.selectedDay,
                                  onChanged: (value) {
                                    provider.selectedDay = value!;
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    isDense: true,
                                  ),
                                  items: List.generate(
                                    provider.location.day,
                                    (index) => DropdownMenuItem(
                                      value: index + 1,
                                      child: Text(
                                        'Day ${index + 1}',
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Align(
                              alignment: Alignment.center,
                              child: Text(
                                'DAY ${provider.selectedDay}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              )),
          body: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Title at the top
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Visit Sequence',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (displaySequence.isNotEmpty && provider.isEditing)
                            MyOutlineButton(
                              title: 'Clear Sequence',
                              onPressed: provider.clearEditingSeq,
                              icon: Icon(Icons.clear_all),
                              color: theme.colorScheme.error,
                            ),
                        ],
                      ),
                    ),
                    // Main content
                    Expanded(
                      child: displaySequence.isEmpty
                          ? Center(
                              child: DragTarget<PlanBlock>(
                                onAcceptWithDetails: (details) =>
                                    provider.addBlockAtIndex(details.data, 0),
                                builder:
                                    (context, candidateData, rejectedData) =>
                                        Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: DottedBorder(
                                    options: RoundedRectDottedBorderOptions(
                                      radius: Radius.circular(12),
                                      color: theme.colorScheme.onSurface,
                                      dashPattern: const [6, 4],
                                      strokeWidth: 2,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 24),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_rounded,
                                            size: 50,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Drag and drop blocks to create your day plan',
                                            maxLines: 5,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 12,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                Positioned.fill(
                                  child: DragTarget<PlanBlock>(
                                    onAcceptWithDetails: (details) {
                                      provider.addBlockAtIndex(
                                          details.data, displaySequence.length);
                                    },
                                    builder: (context, accepted, rejected) {
                                      return Container();
                                    },
                                  ),
                                ),
                                ReorderableListView.builder(
                                  buildDefaultDragHandles: true,
                                  shrinkWrap: true,
                                  proxyDecorator: proxyDecorator,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 12),
                                  onReorder: (oldIndex, newIndex) =>
                                      provider.onReorder(oldIndex, newIndex),
                                  itemCount: displaySequence.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == displaySequence.length) {
                                      return DragTarget<PlanBlock>(
                                        key: ValueKey('drag_target_end'),
                                        onAcceptWithDetails: (details) {
                                          provider.addBlockAtIndex(details.data,
                                              displaySequence.length);
                                        },
                                        builder: (context, accepted, rejected) {
                                          return SizedBox(
                                            height: 20,
                                            width: double.infinity,
                                          );
                                        },
                                      );
                                    }
                                    final block = displaySequence[index];
                                    return SequenceBlockCard(
                                      key: ValueKey('${block.placeId}_$index'),
                                      block: block,
                                      index: index,
                                      onRemove: (index) {
                                        provider.removeAtIndex(index);
                                      },
                                      onAdded: (newBlock, index) => provider
                                          .addBlockAtIndex(newBlock, index),
                                      onInfoTap: () => showPlaceDetails(block),
                                    );
                                  },
                                ),
                              ],
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Divider(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        thickness: 1,
                        height: 2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: provider.savedPlan != null
                                ? GestureDetector(
                                    onTap: () {
                                      UserInfoDialog.show(
                                        context,
                                        userId: provider
                                            .savedPlan!.createdBy.userId,
                                        role: 'Created this Day Plan',
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          child: Text(
                                            (provider.savedPlan!.createdBy
                                                    .userName[0])
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
                                            'by ${provider.savedPlan!.createdBy.userName}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(),
                          ),
                          if (provider.isEditing) ...[
                            if (provider.savedPlan != null)
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
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
                                    size: 24,
                                  ),
                                ),
                                onTap: () {
                                  provider.toggleEditing();
                                },
                              ),
                            SizedBox(width: 12),
                          ],
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: provider.isEditing && !provider.isDirty
                                    ? Colors.grey.withOpacity(0.3)
                                    : theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    provider.isEditing ? 'Save' : 'Edit',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  provider.isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        )
                                      : Icon(
                                          provider.isEditing
                                              ? Icons.check_rounded
                                              : Icons.edit_outlined,
                                          color: theme.colorScheme.onSurface,
                                          size: 20,
                                        ),
                                ],
                              ),
                            ),
                            onTap: () {
                              provider.isEditing
                                  ? provider.isDirty
                                      ? provider.saveSequence()
                                      : null
                                  : provider.toggleEditing();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: provider.isEditing
                    ? MediaQuery.of(context).size.height * 0.35
                    : 0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    width: 1.5,
                  ),
                  color: Colors.grey.withOpacity(0.1),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6.5, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Saved Locations',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          MyOutlineButton(
                            title: _showOnlyUnselected ? 'All' : 'Unselected',
                            onPressed: () {
                              setState(() {
                                _showOnlyUnselected = !_showOnlyUnselected;
                              });
                            },
                            icon: Icon(_showOnlyUnselected
                                ? Icons.filter_alt_off_rounded
                                : Icons.select_all_rounded),
                            color: theme.colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: availableBlocks.isEmpty
                          ? Center(child: Text('No available blocks'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 12),
                              itemCount: availableBlocks.length,
                              itemBuilder: (context, index) {
                                final block = availableBlocks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: AvailableBlockCard(
                                    block: block,
                                    index: index,
                                    onInfoTap: () => showPlaceDetails(block),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
