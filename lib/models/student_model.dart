class Student {
  final String name;
  final String address;
  final String parentName;
  final String contactNumber;
  final String busRoute;
  String? imagePath;

  Student({
    required this.name,
    required this.address,
    required this.parentName,
    required this.contactNumber,
    required this.busRoute,
    this.imagePath,
  });
}
