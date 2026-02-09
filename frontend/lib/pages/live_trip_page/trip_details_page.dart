import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/config/constants.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/models/trip.dart';
import 'package:travel_app/pages/day_planner/provider/curr_plan_provider.dart';
import 'package:travel_app/pages/day_planner/screens/create_day_plan.dart';
import 'package:travel_app/pages/day_planner/screens/day_plans_list_page.dart';
import 'package:travel_app/pages/day_planner/services/day_plan_service.dart';
import 'package:travel_app/pages/explore_page/explorePage.dart';
import 'package:travel_app/pages/live_trip_page/utils/map_markers.dart';
import 'package:travel_app/pages/live_trip_page/widgets/location_card.dart';
import 'package:travel_app/providers/auth_provider.dart';
import 'package:travel_app/services/trip_services.dart';
import 'package:travel_app/pages/emergency_page/emergency_page.dart';
import 'package:travel_app/pages/search_page/search_page.dart';

class TripDetailsPage extends StatefulWidget {
  final Trip trip;

  const TripDetailsPage({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  late List<PlaceModel> _places;
  late TripService tripService;
  GoogleMapController? _mapController;
  String? _selectedLocationId;
  String? _expandedLocationId;
  final Map<String, GlobalKey> _locationKeys = {};
  Set<Marker> _markers = {};
  String? _mapStyle;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _places = widget.trip.locations;
    tripService = TripService(auth: Provider.of<Auth>(context, listen: false));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeMarkers();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    final brightness = Theme.of(context).brightness;

    final path = brightness == Brightness.dark
        ? 'assets/map_styles/dark.json'
        : 'assets/map_styles/light.json';

    final style = await rootBundle.loadString(path);

    setState(() {
      _mapStyle = style;
      print(style);
    });
  }

  Future<void> _navigateToAddLocation() async {
    final PlaceModel? selectedPlace = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );

    if (selectedPlace != null && mounted) {
      try {
        final tripService = TripService(
          auth: Provider.of<Auth>(context, listen: false),
        );

        await tripService.addLocation(widget.trip.id, selectedPlace);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location added successfully')),
          );
          _refreshTrip();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }
  }

  Future<void> _refreshTrip() async {
    try {
      final trip = await tripService.getTrip(widget.trip.id);
      setState(() {
        _places = trip.locations;
        _initializeMarkers();
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeMarkers() async {
    final markers = <Marker>{};

    for (var i = 0; i < _places.length; i++) {
      final place = _places[i];
      final isSelected = _selectedLocationId == place.placeId;
      final isStart = i == 0;

      final customIcon = await MapMarkers.getMarker(
        index: i,
        isSelected: isSelected,
        isStart: isStart,
      );

      markers.add(
        Marker(
          markerId: MarkerId(place.placeId),
          position: LatLng(place.latitude, place.longitude),
          onTap: () => _onMarkerTapped(place.placeId),
          icon: customIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: place.placeName,
            snippet: isStart
                ? 'Start Location'
                : 'Day ${_calculateArrivalDay(place)}',
          ),
        ),
      );

      if (isSelected) {
        // Add hotel markers
        if (place.hotels != null && place.hotels!.isNotEmpty) {
          final hotelIcon = await MapMarkers.getHotelMarker(isSelected: false);

          for (var hotel in place.hotels!) {
            markers.add(
              Marker(
                markerId: MarkerId('hotel_${hotel.placeId}'),
                position: LatLng(hotel.latitude, hotel.longitude),
                icon: hotelIcon,
                anchor: const Offset(0.5, 0.5),
                infoWindow: InfoWindow(
                  title: hotel.name,
                  snippet: '${hotel.rating}⭐ • ${hotel.price}',
                ),
              ),
            );
          }
        }

        // Add attraction markers
        if (place.attractions != null && place.attractions!.isNotEmpty) {
          final attractionIcon =
              await MapMarkers.getPhotographyLocationMarker(isSelected: false);

          for (var attraction in place.attractions!) {
            markers.add(
              Marker(
                markerId: MarkerId('attraction_${attraction.placeId}'),
                position: LatLng(attraction.latitude, attraction.longitude),
                icon: attractionIcon,
                anchor: const Offset(0.5, 0.5),
                infoWindow: InfoWindow(
                  title: attraction.name,
                  snippet: '${attraction.rating}⭐ • ${attraction.type}',
                ),
              ),
            );
          }
        }
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  int _calculateArrivalDay(PlaceModel place) {
    int cumulativeDays = 0;
    for (var p in _places) {
      if (p.placeId == place.placeId) {
        return cumulativeDays + 1;
      }
      cumulativeDays += p.day;
    }
    return 1;
  }

  LatLngBounds? _getLocationWithPOIBounds(PlaceModel place) {
    // Collect all coordinates: location, hotels, and attractions
    List<LatLng> coordinates = [];

    // Add main location
    coordinates.add(LatLng(place.latitude, place.longitude));

    // Add hotels
    if (place.hotels != null && place.hotels!.isNotEmpty) {
      for (var hotel in place.hotels!) {
        coordinates.add(LatLng(hotel.latitude, hotel.longitude));
      }
    }

    // Add attractions
    if (place.attractions != null && place.attractions!.isNotEmpty) {
      for (var attraction in place.attractions!) {
        coordinates.add(LatLng(attraction.latitude, attraction.longitude));
      }
    }

    // If only the main location, return null to use default zoom
    if (coordinates.length == 1) {
      return null;
    }

    // Calculate bounds
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (var coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _onMarkerTapped(String placeId) {
    setState(() {
      _selectedLocationId = placeId;
      _expandedLocationId = placeId;
      _initializeMarkers();
    });

    // Animate bottom sheet to initial size
    _sheetController.animateTo(
      0.5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Scroll to and highlight the location card
    final index = _places.indexWhere((place) => place.placeId == placeId);
    if (index != -1) {
      final key = _locationKeys[placeId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

      // Zoom into the selected location including hotels and attractions
      final place = _places[index];
      final bounds = _getLocationWithPOIBounds(place);

      if (bounds != null) {
        // Fit to bounds if there are hotels/attractions
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      } else {
        // Default zoom if only main location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(place.latitude, place.longitude),
            14.0,
          ),
        );
      }
    }
  }

  void _onLocationCardTapped(PlaceModel place) {
    setState(() {
      _selectedLocationId = place.placeId;
      _expandedLocationId = place.placeId;
      _initializeMarkers();
    });

    // Animate camera to location including hotels and attractions
    final bounds = _getLocationWithPOIBounds(place);

    if (bounds != null) {
      // Fit to bounds if there are hotels/attractions
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } else {
      // Default zoom if only main location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(place.latitude, place.longitude),
          14.0,
        ),
      );
    }
  }

  LatLngBounds? _getLocationBounds() {
    if (_places.isEmpty) return null;
    if (_places.length == 1) return null;

    double minLat = _places.first.latitude;
    double maxLat = _places.first.latitude;
    double minLng = _places.first.longitude;
    double maxLng = _places.first.longitude;

    for (var place in _places) {
      if (place.latitude < minLat) minLat = place.latitude;
      if (place.latitude > maxLat) maxLat = place.latitude;
      if (place.longitude < minLng) minLng = place.longitude;
      if (place.longitude > maxLng) maxLng = place.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _resetSelection() {
    setState(() {
      _selectedLocationId = null;
      _expandedLocationId = null;
      _initializeMarkers();
    });

    // Reset camera to show all locations
    final bounds = _getLocationBounds();
    if (bounds != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trip to ${_places[1].placeName}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          Tooltip(
            message: 'Number of guests',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.trip.guests}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map Background
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.60,
            child: _mapStyle == null || _markers.isEmpty
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : GoogleMap(
                    style: _mapStyle,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _places.first.latitude,
                        _places.first.longitude,
                      ),
                      zoom: 12,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;

                      // Fit bounds to show all locations if multiple exist
                      final bounds = _getLocationBounds();
                      if (bounds != null) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          controller.animateCamera(
                            CameraUpdate.newLatLngBounds(bounds, 50),
                          );
                        });
                      }
                    },
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                  ),
          ),

          // Reset Selection Button (appears when location is selected)
          if (_selectedLocationId != null)
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _resetSelection,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reset',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.5,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
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
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          GestureDetector(
                            onTap: _navigateToDayPlans,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                                border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                    width: 1.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    size: 30,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Day Plans",
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      "New",
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: _navigateToDayPlans,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.secondaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 17,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              "Locations",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLocationsList(),
                          GestureDetector(
                            onTap: _navigateToAddLocation,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.3),
                                    thickness: 1,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.3)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_location_alt,
                                          size: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Add Location',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.3),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Safety Settings Tile
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Icon(Icons.security,
                                  color: theme.colorScheme.primary),
                              title: const Text("Safety Settings"),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const EmergencyContactPage()),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList() {
    int cumulativeDays = 0;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        final isStartLocation = index == 0;

        // Calculate arrival day number and date
        final arrivalDay = cumulativeDays + 1;
        final arrivalDate =
            widget.trip.startDate.add(Duration(days: cumulativeDays));
        final departureDay = arrivalDay + place.day - 1;

        // Prepare for next iteration
        cumulativeDays += place.day;

        // Create or get key for this location
        _locationKeys.putIfAbsent(place.placeId, () => GlobalKey());

        return LocationCard(
          cardKey: _locationKeys[place.placeId],
          owner: widget.trip.user,
          place: place,
          isStartLocation: isStartLocation,
          arrivalDay: arrivalDay,
          departureDay: departureDay,
          arrivalDate: arrivalDate,
          isSelected: _selectedLocationId == place.placeId,
          isExpanded: _expandedLocationId == place.placeId,
          onTap: () => _onLocationCardTapped(place),
          onHotelsTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (context) => CurrPlanProvider(
                      tripId: widget.trip.id,
                      location: place,
                      dayPlanService: DayPlanService(
                          auth: Provider.of<Auth>(context, listen: false))),
                  child: CreateDayPlan(),
                ),
              ),
            ).then((_) => _refreshTrip());
          },
          onAttractionsTap: () async {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ExplorePage(
                          place: place,
                          apiKey: Constants.googlePlacesApiKey,
                          tripId: widget.trip.id,
                          locationIndex: index,
                          ownerId: widget.trip.user.id,
                          tab: 0,
                        ))).then((value) {
              _refreshTrip();
            });
          },
          tripId: widget.trip.id,
          locationIndex: index,
          onRefresh: _refreshTrip,
        );
      },
    );
  }

  void _navigateToDayPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DayPlansListPage(
                trip: widget.trip,
              )),
    ).then((_) => _refreshTrip());
  }
}
