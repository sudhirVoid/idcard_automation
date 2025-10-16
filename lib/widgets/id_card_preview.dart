import 'package:flutter/material.dart';

class IdCardPreview extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final String rollNo;
  final String className;
  final String sectionName;
  final String? address;
  final String? parentName;
  final String? contactNumber;
  final String? busRoute;

  const IdCardPreview({
    super.key,
    this.photoUrl,
    required this.name,
    required this.rollNo,
    required this.className,
    required this.sectionName,
    this.address,
    this.parentName,
    this.contactNumber,
    this.busRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Photo Section
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[400]!,
                  width: 1,
                ),
              ),
              child: photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey[600],
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey[600],
                    ),
            ),
            const SizedBox(width: 16),
            // Information Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'STUDENT ID CARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Student Information
                  _buildInfoRow('Name:', name),
                  _buildInfoRow('Roll No:', rollNo),
                  _buildInfoRow('Class:', className),
                  _buildInfoRow('Section:', sectionName),
                  if (parentName != null && parentName!.isNotEmpty)
                    _buildInfoRow('Parent:', parentName!),
                  if (contactNumber != null && contactNumber!.isNotEmpty)
                    _buildInfoRow('Phone:', contactNumber!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
