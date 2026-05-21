import 'dart:convert';

class VendingLocation {
  final String id;
  final String name;
  final String building;
  final String floor;
  final String distance;
  final bool isOpen;
  final bool isOnline;
  final String hours;
  final List<String> categories;
  final int machineCount;
  final double lat;
  final double lng;

  const VendingLocation({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.distance,
    required this.isOpen,
    required this.isOnline,
    required this.hours,
    required this.categories,
    required this.machineCount,
    required this.lat,
    required this.lng,
  });

  factory VendingLocation.fromJson(Map<String, dynamic> json) {
    // Determine model_type to infer categories
    final modelType = (json['model_type'] ?? '').toString().toLowerCase();
    List<String> categories;
    if (json['categories'] != null) {
      categories = List<String>.from(json['categories'] as List);
    } else if (modelType.contains('hot') || modelType.contains('coffee')) {
      categories = ['Hot', 'Drinks'];
    } else if (modelType.contains('drink') || modelType.contains('beverage')) {
      categories = ['Drinks'];
    } else {
      categories = ['Snacks', 'Drinks'];
    }

    return VendingLocation(
      id: (json['serial_number'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      building: json['location_name'] ?? json['building'] ?? '',
      floor: json['floor'] ?? (json['massage'] ?? '').toString(),
      distance: json['distance'] ?? '',
      isOpen: json['isOpen'] ?? false,
      isOnline: json['is_online'] ?? false,
      hours: json['hours'] ?? '',
      categories: categories,
      machineCount: json['machineCount'] ?? 0,
      lat: (json['latitude'] != null && json['latitude'] != 'null')
          ? double.tryParse(json['latitude'].toString()) ?? 0.0
          : 0.0,
      lng: (json['longitude'] != null && json['longitude'] != 'null')
          ? double.tryParse(json['longitude'].toString()) ?? 0.0
          : 0.0,
    );
  }

  static List<VendingLocation> listFromJson(String source) {
    final list = jsonDecode(source) as List;
    return list
        .map((e) => VendingLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
