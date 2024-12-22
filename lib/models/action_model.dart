class ZoneAction {
  final String zoneId;
  final DateTime timestamp;
  final String description;
  final String? iconPath;
  final String? imagePath;

  ZoneAction({
    required this.zoneId,
    required this.timestamp,
    required this.description,
    this.iconPath,
    this.imagePath,
  });
}
