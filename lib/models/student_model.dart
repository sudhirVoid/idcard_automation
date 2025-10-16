import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  String id;
  String name;
  String rollNo;
  String className;
  String section;
  String? photoUrl;
  String? address;
  String? parentName;
  String? contactNumber;
  String? busRoute;
  DateTime? createdAt;
  DateTime? updatedAt;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.className,
    required this.section,
    this.photoUrl,
    this.address,
    this.parentName,
    this.contactNumber,
    this.busRoute,
    this.createdAt,
    this.updatedAt,
  });

  factory Student.fromFirestore(Map<String, dynamic> data, String id) {
    return Student(
      id: id,
      name: data['name'] ?? '',
      rollNo: data['rollNo'] ?? '',
      className: data['className'] ?? '',
      section: data['section'] ?? '',
      photoUrl: data['photoUrl'],
      address: data['address'],
      parentName: data['parentName'],
      contactNumber: data['contactNumber'],
      busRoute: data['busRoute'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'rollNo': rollNo,
      'className': className,
      'section': section,
      'photoUrl': photoUrl,
      'address': address,
      'parentName': parentName,
      'contactNumber': contactNumber,
      'busRoute': busRoute,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
