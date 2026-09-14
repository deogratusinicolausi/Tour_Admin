import 'package:flutter/material.dart';
import '../services/export_service.dart';
import '../utils/colors.dart';

class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key});

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  final _service = ExportService();
  String? _loadingKey;

  final List<Map<String, dynamic>> _reports = [
    {
      'key': 'stats',
      'title': 'Platform Statistics',
      'subtitle': 'Overall platform summary with revenue',
      'icon': '📊',
      'color': Color(0xFF0D47A1),
      'type': 'stats',
    },
    {
      'key': 'bookings',
      'title': 'All Bookings',
      'subtitle': 'Complete booking records',
      'icon': '📅',
      'color': Color(0xFF667eea),
      'type': 'collection',
      'collection': 'bookings',
    },
    {
      'key': 'users',
      'title': 'All Users',
      'subtitle': 'Registered user accounts',
      'icon': '👥',
      'color': Color(0xFF38f9d7),
      'type': 'collection',
      'collection': 'users',
    },
    {
      'key': 'destinations',
      'title': 'Destinations',
      'subtitle': 'All destination content',
      'icon': '📍',
      'color': Color(0xFF4facfe),
      'type': 'collection',
      'collection': 'destinations',
    },
    {
      'key': 'hotels',
      'title': 'Hotels & Lodges',
      'subtitle': 'All hotel listings',
      'icon': '🏨',
      'color': Color(0xFF43e97b),
      'type': 'collection',
      'collection': 'hotels',
    },
    {
      'key': 'tours',
      'title': 'Tours & Safaris',
      'subtitle': 'All tour packages',
      'icon': '🦁',
      'color': Color(0xFFfa709a),
      'type': 'collection',
      'collection': 'tours',
    },
    {
      'key': 'activities',
      'title': 'Activities',
      'subtitle': 'All activities',
      'icon': '🎯',
      'color': Color(0xFFff9a9e),
      'type': 'collection',
      'collection': 'activities',
    },
    {
      'key': 'deals',
      'title': 'Deals',
      'subtitle': 'All active deals',
      'icon': '🎁',
      'color': Color(0xFFf093fb),
      'type': 'collection',
      'collection': 'deals',
    },
  ];

  Future<void> _generateReport(Map<String, dynamic> report, String format) async {
    final key = '${report['key']}_$format';
    setState(() => _loadingKey = key);

    try {
      String path;
      String shareTitle = report['title'] as String;

      if (report['type'] == 'stats') {
        // Stats report (PDF only)
        if (format == 'pdf') {
          path = await _service.exportStatsPDF();
          await _showSuccessDialog(path, format, shareTitle);
        }
      } else {
        // Collection report
        final collection = report['collection'] as String;

        if (format == 'csv') {
          path = await _service.exportCollectionToCSV(collection);
        } else {
          path = await _service.exportCollectionToPDF(
            collection,
            reportTitle: shareTitle,
          );
        }

        await _showSuccessDialog(path, format, shareTitle);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingKey = null);
    }
  }

  Future<void> _showSuccessDialog(
      String path, String format, String title) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title report generated',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              format == 'csv'
                  ? '📄 CSV file saved'
                  : '📕 PDF file saved',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text('What to do next:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            _actionRow(
              Icons.share,
              'Share',
              'Send via WhatsApp, Email, etc.',
                  () {
                Navigator.pop(context);
                _shareReport(path, format, title);
              },
            ),
            _actionRow(
              Icons.print,
              'Print',
              'Print directly',
                  () {
                Navigator.pop(context);
                _printReport(path, format);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.grey.shade400, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReport(
      String path, String format, String title) async {
    try {
      if (format == 'csv') {
        await _service.shareCSVFile(path, title);
      } else {
        await _service.sharePDFFile(path, title);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  Future<void> _printReport(String path, String format) async {
    if (format == 'pdf') {
      try {
        await _service.printPDF(path);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Print failed: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('CSV cannot be printed directly — share instead')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📤 Export Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(width * 0.04),
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.file_download,
                    color: Colors.white, size: width * 0.12),
                SizedBox(width: width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export Data',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Download as PDF or CSV',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.025),

          // Reports
          ..._reports.map((r) => _buildReportCard(r, width, height)),
        ],
      ),
    );
  }

  Widget _buildReportCard(
      Map<String, dynamic> r, double width, double height) {
    final color = r['color'] as Color;
    final isStats = r['type'] == 'stats';

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.03),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  r['icon'] as String,
                  style: TextStyle(fontSize: width * 0.06),
                ),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['title'] as String,
                      style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: height * 0.003),
                    Text(
                      r['subtitle'] as String,
                      style: TextStyle(
                        fontSize: width * 0.028,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.015),

          // Action buttons
          if (isStats)
            _buildFormatButton(
              label: 'Export as PDF',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              key: '${r['key']}_pdf',
              onTap: () => _generateReport(r, 'pdf'),
              width: width,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildFormatButton(
                    label: 'PDF',
                    icon: Icons.picture_as_pdf,
                    color: Colors.red,
                    key: '${r['key']}_pdf',
                    onTap: () => _generateReport(r, 'pdf'),
                    width: width,
                  ),
                ),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: _buildFormatButton(
                    label: 'CSV',
                    icon: Icons.table_chart,
                    color: Colors.green,
                    key: '${r['key']}_csv',
                    onTap: () => _generateReport(r, 'csv'),
                    width: width,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required String label,
    required IconData icon,
    required Color color,
    required String key,
    required VoidCallback onTap,
    required double width,
  }) {
    final isLoading = _loadingKey == key;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: width * 0.03),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: isLoading
            ? Center(
          child: SizedBox(
            width: width * 0.05,
            height: width * 0.05,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: width * 0.045),
            SizedBox(width: width * 0.015),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.032,
              ),
            ),
          ],
        ),
      ),
    );
  }
}