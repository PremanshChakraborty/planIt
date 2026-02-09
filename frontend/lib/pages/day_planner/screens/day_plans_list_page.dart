import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/models/trip.dart';
import 'package:travel_app/pages/day_planner/models/day_plan.dart';
import 'package:travel_app/pages/day_planner/models/processed_day_plan.dart';
import 'package:travel_app/pages/day_planner/provider/curr_plan_provider.dart';
import 'package:travel_app/pages/day_planner/provider/day_plan_map_provider.dart';
import 'package:travel_app/pages/day_planner/screens/create_day_plan.dart';
import 'package:travel_app/pages/day_planner/screens/day_plan_map_page.dart';
import 'package:travel_app/pages/day_planner/services/day_plan_service.dart';
import 'package:travel_app/pages/day_planner/cards/day_plan_list_card.dart';
import 'package:travel_app/pages/day_planner/widgets/day_planner_info_dialog.dart';
import 'package:travel_app/providers/auth_provider.dart';

class DayPlansListPage extends StatefulWidget {
  final Trip trip;

  const DayPlansListPage({super.key, required this.trip});

  @override
  State<DayPlansListPage> createState() => _DayPlansListPageState();
}

class _DayPlansListPageState extends State<DayPlansListPage> {
  List<ProcessedDayPlan> _processedPlans = [];
  bool _isLoading = true;
  String _error = '';
  late DayPlanService dayPlanService;

  @override
  void initState() {
    super.initState();
    dayPlanService =
        DayPlanService(auth: Provider.of<Auth>(context, listen: false));
    _fetchDayPlans();
  }

  Future<void> _fetchDayPlans() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      final plans = await dayPlanService.getProcessedDayPlans(widget.trip);
      if (mounted) {
        setState(() {
          _processedPlans = plans;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print(stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddPlan(PlaceModel location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => CurrPlanProvider(
            tripId: widget.trip.id,
            location: location,
            dayPlanService: dayPlanService,
          ),
          child: CreateDayPlan(),
        ),
      ),
    ).then((_) {
      _fetchDayPlans();
    });
  }

  void _navigateToRouteMap(ProcessedDayPlan plan, PlaceModel location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          final theme = Theme.of(context);
          return ChangeNotifierProvider(
            create: (context) => DayPlanMapProvider(
              locationName: location.placeName,
              plan: plan.dayPlan,
              dayPlanService: dayPlanService,
              theme: theme,
            ),
            child: DayPlanMapPage(
              theme: theme,
              location: location,
              isOwner: widget.trip.user.id ==
                  Provider.of<Auth>(context, listen: false).user!.id,
            ),
          );
        },
      ),
    ).then((_) {
      _fetchDayPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Day Plans',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            onPressed: () => DayPlannerInfoDialog.show(context),
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About Day Planner',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildLoadingShimmer(theme)
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load day plans: $_error',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: _fetchDayPlans,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: widget.trip.locations.length - 1,
                  itemBuilder: (context, index) {
                    final location = widget.trip.locations[index + 1];
                    final plansForLocation = _processedPlans
                        .where((p) => p.dayPlan.locationId == location.placeId)
                        .toList();

                    // Sort plans by day
                    plansForLocation
                        .sort((a, b) => a.dayPlan.day.compareTo(b.dayPlan.day));

                    return _buildLocationSection(
                        theme, location, plansForLocation);
                  },
                ),
    );
  }

  Widget _buildLocationSection(
      ThemeData theme, PlaceModel location, List<ProcessedDayPlan> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.placeName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${location.day} Day ${location.day == 1 ? "" : "s"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _navigateToAddPlan(location),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.secondaryContainer,
                  ),
                  child: Icon(Icons.add_rounded,
                      size: 30, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),

        // Plans List or Empty State
        if (plans.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  'No plans added yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              return DayPlanListCard(
                processedPlan: plans[index],
                ownerId: widget.trip.user.id,
                dayPlanService: dayPlanService,
                location: location,
                onDeleted: () {
                  setState(() {
                    _processedPlans.removeWhere(
                        (p) => p.dayPlan.id == plans[index].dayPlan.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Day plan deleted successfully'),
                        backgroundColor: Colors.greenAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                },
                onStarred: (isStarred) {
                  setState(() {
                    final planIndex = _processedPlans.indexWhere(
                        (p) => p.dayPlan.id == plans[index].dayPlan.id);
                    if (planIndex != -1) {
                      DayPlan newDayPlan = _processedPlans[planIndex]
                          .dayPlan
                          .copyWith(isStarred: isStarred);
                      _processedPlans[planIndex] = ProcessedDayPlan(
                          dayPlan: newDayPlan,
                          absoluteDate: _processedPlans[planIndex].absoluteDate,
                          creatorImageUrl:
                              _processedPlans[planIndex].creatorImageUrl);
                    }
                  });
                },
                onMapButtonPressed: () {
                  _navigateToRouteMap(plans[index], location);
                },
              );
            },
          ),

        const SizedBox(height: 8),
        Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.onSurface.withOpacity(0.05),
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
