class PlaceSearchResult {
  const PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.neighborhood,
    required this.city,
    required this.lat,
    required this.lng,
  });

  final String placeId;
  final String name;
  final String neighborhood;
  final String city;
  final double lat;
  final double lng;
}
