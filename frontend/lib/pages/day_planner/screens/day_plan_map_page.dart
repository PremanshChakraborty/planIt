import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/pages/day_planner/cards/leg_card.dart';
import 'package:travel_app/pages/day_planner/provider/curr_plan_provider.dart';
import 'package:travel_app/pages/day_planner/provider/day_plan_map_provider.dart';
import 'package:travel_app/pages/day_planner/screens/create_day_plan.dart';
import 'package:travel_app/pages/day_planner/services/day_plan_service.dart';
import 'package:travel_app/pages/day_planner/widgets/place_details_dialog.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/providers/google_services_provider.dart';
import 'package:travel_app/pages/day_planner/widgets/trip_summary_widget.dart';

class DayPlanMapPage extends StatefulWidget {
  final ThemeData theme;
  final PlaceModel location;
  final bool isOwner;
  const DayPlanMapPage(
      {super.key, required this.theme, required this.location, required this.isOwner});

  @override
  State<DayPlanMapPage> createState() => _DayPlanMapPageState();
}

class _DayPlanMapPageState extends State<DayPlanMapPage> {
  String? _mapStyle;
  @override
  void initState() {
    super.initState();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final brightness = widget.theme.brightness;

    final path = brightness == Brightness.dark
        ? 'assets/map_styles/dark.json'
        : 'assets/map_styles/light.json';

    final style = await rootBundle.loadString(path);

    setState(() {
      _mapStyle = style;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DayPlanMapProvider>(
      builder: (context, provider, child) {
        final theme = widget.theme;
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
        if (provider.successMessage.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.successMessage),
                  backgroundColor: Colors.greenAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              provider.clearError();
            }
          });
        }

        // Set the callback for marker taps
        provider.onMarkerTap = (placeId, addedBy) {
          PlaceDetailsDialog.show(
            context,
            fetchPlaceDetails:
                Provider.of<GoogleServicesProvider>(context, listen: false)
                    .fetchPlaceDetails,
            placeId: placeId,
            addedBy: addedBy,
          );
        };

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.plan.planTitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  provider.locationName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
            actions: [
              Tooltip(
                message: 'Number of guests',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Day ${provider.plan.day}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.465,
                child: _mapStyle == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        style: _mapStyle,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            provider.plan.sequence.first.latitude,
                            provider.plan.sequence.first.longitude,
                          ),
                          zoom: 12,
                        ),
                        markers: provider.markers,
                        polylines: provider.polylines,
                        onMapCreated: (controller) {
                          provider.init(controller);
                        },
                        myLocationButtonEnabled: false,
                        myLocationEnabled: true,
                        zoomControlsEnabled: false,
                        onCameraMove: (_) => provider.onCameraMoved(),
                        mapToolbarEnabled: false,
                      ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.55,
                minChildSize: 0.55,
                maxChildSize: 0.75,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 50,
                        child: provider.selectedLegIndex != null
                            ? Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 10, right: 12),
                                  child: FloatingActionButton(
                                    onPressed: provider.resetSelection,
                                    backgroundColor: theme.colorScheme.surface,
                                    foregroundColor:
                                        theme.colorScheme.onSurface,
                                    child: Icon(Icons.close),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.transparent,
                              ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SingleChildScrollView(
                                controller: scrollController,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                          top: 12, bottom: 12),
                                      width: 50,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    if (provider.route != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: TripSummaryWidget(
                                          isOptimized: provider.isOptimized,
                                          showingOptimized:
                                              provider.showingOptimized,
                                          plan: provider.plan,
                                          route: provider.route,
                                          travelMode: provider.travelMode,
                                          oldRoute: provider.originalRoute,
                                          isAllowedToEdit:
                                              provider.plan.createdBy.userId ==
                                                  (Provider.of<Auth>(context,
                                                              listen: false)
                                                          .user
                                                          ?.id ??
                                                      ''),
                                          onSave: (asCopy, newTitle) {
                                            provider.saveOptimization(
                                                asCopy, newTitle);
                                          },
                                          onTravelModeChanged: (mode) {
                                            provider.changeTravelMode(mode);
                                          },
                                          onOptimize: () {
                                            provider.recalculateRoute(
                                                optimized: true);
                                          },
                                          onRevert: () {
                                            provider.revertOptimization();
                                          },
                                          onEdit: () {
                                            final plan = provider.plan;
                                            final dayPlanService =
                                                DayPlanService(
                                                    auth: Provider.of<Auth>(
                                                        context,
                                                        listen: false));
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChangeNotifierProvider(
                                                  create: (context) =>
                                                      CurrPlanProvider(
                                                          tripId: plan.tripId,
                                                          location:
                                                              widget.location,
                                                          dayPlanService:
                                                              dayPlanService,
                                                          savedPlan: plan),
                                                  child: CreateDayPlan(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 8),
                                        child: Text(
                                          'Route Legs',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: provider.isLoading
                                    ? _buildLoadingState(theme)
                                    : provider.route == null
                                        ? Center(
                                            child: Text(
                                              'No route information available',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          )
                                        : ListView.separated(
                                            shrinkWrap: true,
                                            physics:
                                                const ClampingScrollPhysics(),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 0),
                                            itemCount:
                                                provider.route!.legs.length,
                                            separatorBuilder:
                                                (context, index) =>
                                                    const SizedBox(height: 16),
                                            itemBuilder: (context, index) {
                                              provider.locationKeys.putIfAbsent(
                                                  'day plan map $index',
                                                  () => GlobalKey());
                                              return LegCard(
                                                  theme: theme,
                                                  index: index,
                                                  provider: provider);
                                            },
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
              if (!provider.hasCameraFitted)
                Positioned(
                  right: 12,
                  top: 12,
                  child: SizedBox(
                    height: 40,
                    width: 100,
                    child: FloatingActionButton.extended(
                      heroTag: 'reset_selection_btn',
                      onPressed: provider.fitCamera,
                      backgroundColor: theme.colorScheme.surface,
                      label: Text(
                        'Re-center',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Shimmer.fromColors(
            baseColor: theme.brightness == Brightness.light
                ? Colors.grey.shade300
                : Colors.grey.shade800,
            highlightColor: theme.brightness == Brightness.light
                ? Colors.grey.shade100
                : Colors.grey.shade700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 13,
                          height: 13,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          height: 14,
                          width: 1,
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
