import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../../theme/app_theme.dart';
import '../../models/vending_location.dart';
import '../../services/locations_service.dart';

// const _filters = ['All', 'Nearby'];

// ─── Screen ────────────────────────────────────────────────────────────────

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  double _collapseProgress = 0.0;
  static const double _expandedHeight = 170.0;
  static const double _fadeStart = 130.0;

  String _activeFilter = 'All';
  String _query = '';

  List<VendingLocation> _allLocations = [];
  bool _loading = true;
  String? _error;
  Position? _userPosition;

  Future<Position?> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  String _calculateDistance(double lat, double lng) {
    if (_userPosition == null || lat == 0 || lng == 0) return '';

    final double userLat = _userPosition!.latitude;
    final double userLng = _userPosition!.longitude;

    const double earthRadius = 6371;
    final double dLat = _toRadians(lat - userLat);
    final double dLng = _toRadians(lng - userLng);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(userLat)) *
            cos(_toRadians(lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    if (distance < 1) {
      final int meters = (distance * 1000).round();
      return '$meters m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final data = await LocationsService.fetch();
      final position = await _getUserLocation();
      if (mounted)
        setState(() {
          _allLocations = data;
          _userPosition = position;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  void _onScroll() {
    final offset = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
    final progress = ((offset - _fadeStart) / (_expandedHeight - _fadeStart))
        .clamp(0.0, 1.0);
    if (progress != _collapseProgress) {
      setState(() => _collapseProgress = progress);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<VendingLocation> get _filtered {
    final result = _allLocations.where((l) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!l.name.toLowerCase().contains(q) &&
            !l.building.toLowerCase().contains(q)) {
          return false;
        }
      }
      switch (_activeFilter) {
        case 'Nearby':
          final dist = _calculateDistance(l.lat, l.lng);
          if (dist.isEmpty) return false;
          final km = _parseDistance(dist);
          return km <= 2.0;
        case 'Online':
          return l.isOpen;
        case 'Snacks':
        case 'Drinks':
        case 'Hot':
          return l.categories.contains(_activeFilter);
        default:
          return true;
      }
    }).toList();

    if (_userPosition != null) {
      result.sort((a, b) {
        if (a.isOnline != b.isOnline) {
          return a.isOnline ? -1 : 1;
        }
        final distA = _calculateDistance(a.lat, a.lng);
        final distB = _calculateDistance(b.lat, b.lng);
        if (distA.isEmpty && distB.isEmpty) return 0;
        if (distA.isEmpty) return 1;
        if (distB.isEmpty) return -1;

        final kmA = _parseDistance(distA);
        final kmB = _parseDistance(distB);
        return kmA.compareTo(kmB);
      });
    } else {
      result.sort((a, b) {
        if (a.isOnline == b.isOnline) return 0;
        return a.isOnline ? -1 : 1;
      });
    }
    return result;
  }

  double _parseDistance(String dist) {
    if (dist.contains('km')) {
      return double.parse(dist.replaceAll(' km', ''));
    } else {
      return double.parse(dist.replaceAll(' m', '')) / 1000;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        onRefresh: _loadLocations,
        color: AppColors.orange,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Collapsing hero header ───────────────────────────────────────
            SliverAppBar(
              expandedHeight: _expandedHeight,
              pinned: true,
              stretch: true,
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              backgroundColor: Color.lerp(
                AppColors.offWhite,
                AppColors.originalCreamMid,
                _collapseProgress,
              ),
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.blurBackground],
                background: _LocationsHeader(locations: _allLocations),
              ),
            ),

            // ── Search bar ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _SearchBar(controller: _searchCtrl),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Filter chips ────────────────────────────────────────────────
            // SliverToBoxAdapter(
            //   child: Container(
            //     height: 58,
            //     color: AppColors.offWhite,
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: _filters.map((f) {
            //         final active = _activeFilter == f;
            //         return Padding(
            //           padding: const EdgeInsets.symmetric(
            //               horizontal: 6, vertical: 10),
            //           child: GestureDetector(
            //             onTap: () => setState(() => _activeFilter = f),
            //             child: AnimatedContainer(
            //               duration: const Duration(milliseconds: 220),
            //               curve: Curves.easeInOut,
            //               padding: const EdgeInsets.symmetric(
            //                 horizontal: 28,
            //                 vertical: 7,
            //               ),
            //               decoration: BoxDecoration(
            //                 color: active ? AppColors.orange : Colors.white,
            //                 borderRadius: BorderRadius.circular(20),
            //                 border: Border.all(
            //                   color:
            //                       active ? AppColors.orange : AppColors.beige,
            //                   width: 1.5,
            //                 ),
            //                 boxShadow: active
            //                     ? [
            //                         BoxShadow(
            //                           color: AppColors.orange.withOpacity(0.3),
            //                           blurRadius: 8,
            //                           offset: const Offset(0, 2),
            //                         ),
            //                       ]
            //                     : null,
            //               ),
            //               child: Text(
            //                 f,
            //                 style: TextStyle(
            //                   fontFamily: AppFonts.inter,
            //                   fontSize: 12,
            //                   fontWeight: FontWeight.w600,
            //                   color: active ? Colors.white : AppColors.navy,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         );
            //       }).toList(),
            //     ),
            //   ),
            // ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // ── Location cards ──────────────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error: $_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  subtitle: _activeFilter == 'Nearby' && _userPosition == null
                      ? 'Enable location access to see nearby machines'
                      : 'Try a different filter or search term',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _LocationCard(
                    location: filtered[i],
                    delay: Duration(milliseconds: 50 * i.clamp(0, 4)),
                    calculatedDistance:
                        _calculateDistance(filtered[i].lat, filtered[i].lng),
                  ),
                  childCount: filtered.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

class _LocationsHeader extends StatelessWidget {
  final List<VendingLocation> locations;
  const _LocationsHeader({required this.locations});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.originalCream,
            AppColors.originalCreamLight,
            AppColors.originalCreamMid,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative orbs
          // Positioned(
          //   top: -20,
          //   right: -10,
          //   child: ImageFiltered(
          //     imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          //     child: Container(
          //       width: 120,
          //       height: 120,
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         color: AppColors.orange.withOpacity(0.17),
          //       ),
          //     ),
          //   ),
          // ),
          // Positioned(
          //   bottom: 30,
          //   left: -10,
          //   child: ImageFiltered(
          //     imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          //     child: Container(
          //       width: 100,
          //       height: 100,
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         color: AppColors.orange.withOpacity(0.12),
          //       ),
          //     ),
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find a Machine',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'iVend Machines near you',
                          style: TextStyle(
                            color: AppColors.navyMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeaderStat(
                      value: '${locations.length}',
                      label: 'Locations',
                      icon: Icons.storefront_rounded,
                    ),
                    const SizedBox(width: 12),
                    _HeaderStat(
                      value: '${locations.where((l) => l.isOnline).length}',
                      label: 'Online',
                      icon: Icons.circle,
                      iconColor: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _HeaderStat(
                      value: '${locations.length}',
                      label: 'Machines',
                      icon: Icons.local_grocery_store,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? iconColor;

  const _HeaderStat({
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navy.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor ?? AppColors.orange),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 10,
                  color: AppColors.navy.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Search bar ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 14,
          color: AppColors.navy,
        ),
        decoration: InputDecoration(
          hintText: 'Search locations or buildings…',
          hintStyle: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            color: AppColors.grey.withOpacity(0.8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.grey,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.clear(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.grey,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─── Location card ─────────────────────────────────────────────────────────

class _LocationCard extends StatefulWidget {
  final VendingLocation location;
  final Duration delay;
  final String calculatedDistance;

  const _LocationCard({
    required this.location,
    required this.delay,
    required this.calculatedDistance,
  });

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _openInMaps() async {
    final loc = widget.location;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${loc.lat},${loc.lng}&query_place_id=${Uri.encodeComponent(loc.name)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _openInMaps,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: loc.isOpen
                                ? [
                                    AppColors.orange.withOpacity(0.15),
                                    AppColors.orange.withOpacity(0.05),
                                  ]
                                : [
                                    AppColors.grey.withOpacity(0.1),
                                    AppColors.grey.withOpacity(0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: loc.isOpen ? AppColors.orange : AppColors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    loc.name,
                                    style: const TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                _OnlineStatusBadge(isOnline: loc.isOnline),
                                const SizedBox(width: 6),
                                // _StatusBadge(isOpen: loc.isOpen),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              loc.building,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                color: AppColors.navy.withOpacity(0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              loc.floor,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 11,
                                color: AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // Categories
                                ...loc.categories.map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: _CategoryChip(label: c),
                                  ),
                                ),
                                const Spacer(),
                                // Distance
                                Row(
                                  children: [
                                    Icon(
                                      Icons.near_me_rounded,
                                      size: 12,
                                      color: AppColors.orange.withOpacity(
                                        0.8,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      widget.calculatedDistance.isNotEmpty
                                          ? widget.calculatedDistance
                                          : loc.distance,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.inter,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Row(
                            //   children: [
                            //     Icon(
                            //       Icons.access_time_rounded,
                            //       size: 11,
                            //       color: loc.isOpen
                            //           ? AppColors.success
                            //           : AppColors.grey,
                            //     ),
                            //     const SizedBox(width: 4),
                            //     Text(
                            //       loc.hours,
                            //       style: TextStyle(
                            //         fontFamily: AppFonts.inter,
                            //         fontSize: 11,
                            //         color: loc.isOpen
                            //             ? AppColors.success
                            //             : AppColors.grey,
                            //         fontWeight: FontWeight.w500,
                            //       ),
                            //     ),
                            //     const SizedBox(width: 10),
                            //     Icon(
                            //       Icons.local_grocery_store,
                            //       size: 11,
                            //       color: AppColors.navyMuted.withOpacity(
                            //         0.5,
                            //       ),
                            //     ),
                            //     const SizedBox(width: 4),
                            //     Text(
                            //       '${loc.machineCount} machine${loc.machineCount > 1 ? 's' : ''}',
                            //       style: TextStyle(
                            //         fontFamily: AppFonts.inter,
                            //         fontSize: 11,
                            //         color: AppColors.navyMuted.withOpacity(
                            //           0.6,
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  // final bool isOpen;
  // const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      // decoration: BoxDecoration(
      //   color: isOpen
      //       ? AppColors.success.withOpacity(0.1)
      //       : AppColors.grey.withOpacity(0.1),
      //   borderRadius: BorderRadius.circular(20),
      // ),
      // child: Row(
      //   mainAxisSize: MainAxisSize.min,
      //   children: [
      //     Container(
      //       width: 5,
      //       height: 5,
      //       decoration: BoxDecoration(
      //         shape: BoxShape.circle,
      //         color: isOpen ? AppColors.success : AppColors.grey,
      //       ),
      //     ),
      //     const SizedBox(width: 4),
      //     Text(
      //       isOpen ? 'Open' : 'Closed',
      //       style: TextStyle(
      //         fontFamily: AppFonts.inter,
      //         fontSize: 10,
      //         fontWeight: FontWeight.w600,
      //         color: isOpen ? AppColors.success : AppColors.grey,
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  Color get _color {
    switch (label) {
      case 'Drinks':
        return AppColors.navy;
      case 'Hot':
        return AppColors.orangeDark;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _OnlineStatusBadge extends StatelessWidget {
  final bool isOnline;
  const _OnlineStatusBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isOnline ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String subtitle;
  const _EmptyState({this.subtitle = 'Try a different filter or search term'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: AppColors.orange,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No locations found',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
