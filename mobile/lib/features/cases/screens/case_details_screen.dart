import 'package:flutter/material.dart';

class CaseDetailsScreen extends StatelessWidget {
  final dynamic caseItem;

  const CaseDetailsScreen({super.key, this.caseItem});

  @override
  Widget build(BuildContext context) {
    String title = 'Case Details';
    String status = 'Active';
    String description = 'No description provided.';
    String caseId = 'N/A';
    String date = 'N/A';
    Map<String, dynamic> debugData = {};

    try {
      if (caseItem != null) {
        try {
          if (caseItem.toJson() is Map) {
            debugData = Map<String, dynamic>.from(caseItem.toJson());
          }
        } catch (_) {
          try {
            if (caseItem.toMap() is Map) {
              debugData = Map<String, dynamic>.from(caseItem.toMap());
            }
          } catch (_) {}
        }

        title = debugData['title'] ?? 
                debugData['name'] ?? 
                debugData['caseName'] ?? 
                _tryGetProperty(caseItem, 'title') ?? 
                _tryGetProperty(caseItem, 'name') ?? 
                'Case Details';

        status = debugData['status'] ?? 
                 _tryGetProperty(caseItem, 'status') ?? 
                 'Active';

        description = debugData['description'] ?? 
                      debugData['details'] ?? 
                      debugData['notes'] ?? 
                      _tryGetProperty(caseItem, 'description') ?? 
                      _tryGetProperty(caseItem, 'notes') ?? 
                      'No description provided.';

        caseId = debugData['id']?.toString() ?? 
                 debugData['caseId']?.toString() ?? 
                 _tryGetProperty(caseItem, 'id')?.toString() ?? 
                 'N/A';

        date = debugData['date'] ?? 
               debugData['createdAt'] ?? 
               _tryGetProperty(caseItem, 'date')?.toString() ?? 
               'N/A';
      }
    } catch (e) {
      debugPrint('Error parsing case details: $e');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title.toString()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(status.toString()),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Biometric Verified',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Case Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Case ID', caseId),
                    const SizedBox(height: 12),
                    _buildInfoRow('Title', title),
                    const SizedBox(height: 12),
                    _buildInfoRow('Date Created', date),
                    if (debugData.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...debugData.entries.where((e) => !['title', 'name', 'status', 'description', 'id', 'date', 'createdAt'].contains(e.key)).map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildInfoRow(_formatKey(entry.key), entry.value?.toString() ?? 'N/A'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description / Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      description.toString(),
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  dynamic _tryGetProperty(dynamic obj, String propertyName) {
    try {
      if (propertyName == 'title') return obj.title;
      if (propertyName == 'name') return obj.name;
      if (propertyName == 'status') return obj.status;
      if (propertyName == 'description') return obj.description;
      if (propertyName == 'id') return obj.id;
      if (propertyName == 'date') return obj.date;
    } catch (_) {}
    return null;
  }

  String _formatKey(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1).replaceAll(RegExp(r'(?=[A-Z])'), ' ');
  }
}