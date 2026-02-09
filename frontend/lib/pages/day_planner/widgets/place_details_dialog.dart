import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/pages/day_planner/models/place_details.dart';
import 'package:travel_app/widgets/user_info_dialog.dart';

class PlaceDetailsDialog extends StatefulWidget {
  final Future<PlaceDetails?> Function(String) fetchPlaceDetails;
  final String placeId;
  final AddedBy addedBy;

  const PlaceDetailsDialog({
    super.key,
    required this.fetchPlaceDetails,
    required this.placeId,
    required this.addedBy,
  });

  @override
  State<PlaceDetailsDialog> createState() => _PlaceDetailsDialogState();

  static Future<void> show(
    BuildContext context, {
    required Future<PlaceDetails?> Function(String) fetchPlaceDetails,
    required String placeId,
    required AddedBy addedBy,
  }) {
    return showDialog(
      context: context,
      builder: (context) => PlaceDetailsDialog(
        fetchPlaceDetails: fetchPlaceDetails,
        placeId: placeId,
        addedBy: addedBy,
      ),
    );
  }
}

class _PlaceDetailsDialogState extends State<PlaceDetailsDialog> {
  PlaceDetails? _placeDetails;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _loadPlaceDetails();
  }

  Future<void> _loadPlaceDetails() async {
    try {
      final details = await widget.fetchPlaceDetails(widget.placeId);
      if (mounted) {
        setState(() {
          _placeDetails = details;
          _isLoading = false;
          if (details == null) {
            _error = 'Failed to load place details';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading place details';
          _isLoading = false;
        });
      }
    }
  }

  String? _getCurrentDayOpeningHours() {
    if (_placeDetails?.openingHours == null ||
        _placeDetails!.openingHours!.isEmpty) {
      return null;
    }
    final now = DateTime.now();
    final dayOfWeek = now.weekday % 7;
    if (dayOfWeek < _placeDetails!.openingHours!.length) {
      return _placeDetails!.openingHours![dayOfWeek];
    }
    return null;
  }

  String _formatTypes(List<String> types) {
    final formattedTypes = types.map((type) {
      return type.replaceAll('_', ' ').split(' ').map((word) {
        return word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '';
      }).join(' ');
    }).toList();
    return formattedTypes.take(3).join(' • ');
  }

  Future<void> _openInGoogleMaps() async {
    if (_placeDetails == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_placeDetails!.name)}&query_place_id=${widget.placeId}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Location Info',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(theme)
                  : _error != null
                      ? _buildErrorState(theme)
                      : _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 16,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Details shimmer
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_placeDetails == null) {
      return _buildErrorState(theme);
    }

    final todayHours = _getCurrentDayOpeningHours();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel
          if (_placeDetails!.photoUrls.isNotEmpty)
            Stack(
              children: [
                CarouselSlider(
                  carouselController: _carouselController,
                  items: _placeDetails!.photoUrls.map((url) {
                    return ClipRRect(
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          height: 250,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.image, size: 40),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                  options: CarouselOptions(
                    height: 250,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: _placeDetails!.photoUrls.length > 1,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                  ),
                ),
                if (_placeDetails!.photoUrls.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${_placeDetails!.photoUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_placeDetails!.photoUrls.length > 1)
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentImageIndex > 0)
                          GestureDetector(
                            onTap: () {
                              _carouselController.previousPage();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                        if (_currentImageIndex <
                            _placeDetails!.photoUrls.length - 1)
                          GestureDetector(
                            onTap: () {
                              _carouselController.nextPage();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
              ],
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _placeDetails!.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (_placeDetails!.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _placeDetails!.rating!.toStringAsFixed(1),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Types
                if (_placeDetails!.types != null &&
                    _placeDetails!.types!.isNotEmpty)
                  Text(
                    _formatTypes(_placeDetails!.types!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 16),
                // Address
                if (_placeDetails!.formattedAddress != null ||
                    _placeDetails!.vicinity != null)
                  _buildInfoRow(
                    theme,
                    Icons.location_on_outlined,
                    _placeDetails!.formattedAddress ?? _placeDetails!.vicinity!,
                  ),
                // Phone
                if (_placeDetails!.phoneNumber != null)
                  _buildInfoRow(
                    theme,
                    Icons.phone_outlined,
                    _placeDetails!.phoneNumber!,
                  ),
                // Website
                if (_placeDetails!.website != null)
                  _buildInfoRow(
                    theme,
                    Icons.language_outlined,
                    _placeDetails!.website!,
                    isLink: true,
                  ),
                // Google Maps link
                _buildInfoRow(
                  theme,
                  Icons.map_outlined,
                  'Open in Google Maps',
                  isLink: true,
                  onTap: _openInGoogleMaps,
                ),
                // Opening hours
                if (todayHours != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _placeDetails!.openNow == true
                                      ? Colors.green.shade50
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _placeDetails!.openNow == true
                                      ? 'Open Now'
                                      : 'Closed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _placeDetails!.openNow == true
                                        ? Colors.green.shade700
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                todayHours,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Divider(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                ),
                const SizedBox(height: 12),
                // Added by
                GestureDetector(
                  onTap: () {
                    UserInfoDialog.show(
                      context,
                      userId: widget.addedBy.userId,
                      role: 'Added this place',
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          (widget.addedBy.userName[0]).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.addedBy.userName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Added this place',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String text,
      {bool isLink = false, VoidCallback? onTap}) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isLink
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.8),
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: content,
              ),
            )
          : content,
    );
  }
}
