import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_place/google_place.dart';
import 'package:travel_app/models/place_model.dart';
import 'package:travel_app/widgets/user_info_dialog.dart';

class PlaceTile extends StatefulWidget {
  final SearchResult place;
  final bool isSaved;
  final AddedBy? addedBy;
  final String currentUserId;
  final String ownerId;
  final VoidCallback onSaveTap;
  final List<String> imageUrls;
  final bool isLoadingMore;
  final List<String>? openingHours;
  final bool isHotel;

  const PlaceTile({
    required this.place,
    required this.isSaved,
    this.addedBy,
    required this.currentUserId,
    required this.ownerId,
    required this.onSaveTap,
    required this.imageUrls,
    required this.isLoadingMore,
    this.openingHours,
    required this.isHotel,
  });

  @override
  State<PlaceTile> createState() => _PlaceTileState();
}

class _PlaceTileState extends State<PlaceTile> {
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  String? _getCurrentDayOpeningHours() {
    if (widget.openingHours == null || widget.openingHours!.isEmpty) {
      return null;
    }
    final now = DateTime.now();
    final dayOfWeek = now.weekday % 7;
    if (dayOfWeek < widget.openingHours!.length) {
      return widget.openingHours![dayOfWeek];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final todayHours = _getCurrentDayOpeningHours();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CarouselSlider(
                carouselController: _carouselController,
                items: _buildCarouselItems(screenWidth),
                options: CarouselOptions(
                  height: 160,
                  viewportFraction: 0.5,
                  initialPage: 0,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  padEnds: false,
                ),
              ),
              if (widget.imageUrls.length > 2)
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentImageIndex > 0)
                        GestureDetector(
                          onTap: () {
                            _carouselController.animateToPage(
                              _currentImageIndex - 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                      if (_currentImageIndex < widget.imageUrls.length - 2)
                        GestureDetector(
                          onTap: () {
                            _carouselController.animateToPage(
                              _currentImageIndex + 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                ),
              if (widget.imageUrls.length > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${widget.imageUrls.length - 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.place.name ?? 'Unknown',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.place.types?.isNotEmpty == true
                              ? _formatTypes(widget.place.types!)
                              : widget.isHotel
                                  ? 'Hotel'
                                  : 'Place',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (widget.place.vicinity != null)
                          Text(
                            widget.place.vicinity!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondary,
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.isSaved && widget.addedBy != null) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              UserInfoDialog.show(
                                context,
                                userId: widget.addedBy!.userId,
                                role:
                                    'Added this ${widget.isHotel ? 'hotel' : 'place'}',
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: theme.colorScheme.primary,
                                  child: Text(
                                    (widget.addedBy!.userName[0]).toUpperCase(),
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
                                    'by ${widget.addedBy!.userName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          Builder(
                            builder: (context) {
                              final bool canEdit = !widget.isSaved ||
                                  widget.currentUserId == widget.ownerId ||
                                  (widget.addedBy == null) ||
                                  (widget.addedBy?.userId ==
                                      widget.currentUserId);
                              final bool showTick = !canEdit;

                              return InkWell(
                                onTap: canEdit ? widget.onSaveTap : null,
                                child: Icon(
                                  showTick
                                      ? Icons.check_circle
                                      : (widget.isSaved
                                          ? Icons.bookmark
                                          : Icons.bookmark_border),
                                  color: showTick
                                      ? Colors.green
                                      : (widget.isSaved
                                          ? theme.colorScheme.primary
                                          : Colors.grey),
                                  size: 24,
                                ),
                              );
                            },
                          ),
                          Text(
                            widget.isSaved ? 'Saved' : 'Save',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.isSaved
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (widget.place.rating != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                Text(
                                  ' ${widget.place.rating}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (!widget.isHotel && todayHours != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    widget.place.openingHours?.openNow == true
                                        ? Colors.green.shade50
                                        : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                todayHours.split(': ').length > 1
                                    ? todayHours.split(': ')[1]
                                    : todayHours,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      widget.place.openingHours?.openNow == true
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700,
                                ),
                              ),
                            )
                          else if (!widget.isHotel &&
                              widget.place.openingHours?.openNow != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.place.openingHours!.openNow!
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.place.openingHours!.openNow!
                                    ? 'Open Now'
                                    : 'Closed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: widget.place.openingHours!.openNow!
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCarouselItems(double screenWidth) {
    final List<String> displayImages = [...widget.imageUrls];
    // while (displayImages.length < 2) {
    //   displayImages.add('https://via.placeholder.com/400x200?text=No+Image');
    // }
    return displayImages.map((imageUrl) {
      return SizedBox(
        width: screenWidth / 2 - 1,
        child: widget.isLoadingMore && displayImages.indexOf(imageUrl) > 0
            ? _buildLoadingImagePlaceholder()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildErrorImagePlaceholder(),
              ),
      );
    }).toList();
  }

  Widget _buildLoadingImagePlaceholder() {
    return Container(
      height: 160,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorImagePlaceholder() {
    return Container(
      height: 160,
      color: Colors.grey.shade300,
      child: const Center(child: Icon(Icons.image, size: 40)),
    );
  }

  String _formatTypes(List<String> types) {
    final formattedTypes = types.map((type) {
      return type.replaceAll('_', ' ').split(' ').map((word) {
        return word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '';
      }).join(' ');
    }).toList();
    return formattedTypes.take(2).join(' • ');
  }
}
