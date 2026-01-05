import 'package:flutter/material.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/pages/explore_page/attractions_page/attractions_page.dart';
import 'package:travel_app/pages/explore_page/hotels_page/hotels_page.dart';

class ExplorePage extends StatefulWidget {
  final PlaceModel place;
  final String? apiKey;
  final String tripId;
  final int locationIndex;
  final String ownerId;
  final int tab;
  const ExplorePage({
    super.key,
    required this.place,
    this.apiKey,
    required this.tripId,
    required this.locationIndex,
    required this.ownerId,
    required this.tab,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2, // number of tabs
      vsync: this,
      initialIndex: widget.tab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      //backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 65,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.place.placeName,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Nearby ${_tabController.index == 0 ? 'Attractions' : 'Hotels'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 45,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              indicator: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withOpacity(0.6),
              splashBorderRadius: BorderRadius.circular(25),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: "Attractions"),
                Tab(text: "Hotels"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NearbyAttractionsPage(
            place: widget.place,
            apiKey: widget.apiKey,
            tripId: widget.tripId,
            locationIndex: widget.locationIndex,
            ownerId: widget.ownerId,
          ),
          NearbyHotelsPage(
            place: widget.place,
            apiKey: widget.apiKey,
            tripId: widget.tripId,
            locationIndex: widget.locationIndex,
            ownerId: widget.ownerId,
          ),
        ],
      ),
    );
  }
}
