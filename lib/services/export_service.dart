import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐️ ===== CSV EXPORT =====

  Future<String> exportCollectionToCSV(
      String collection, {
        List<String>? selectedFields,
      }) async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection(collection).get();

      if (snapshot.docs.isEmpty) {
        throw Exception('No data in $collection');
      }

      // Get all field names
      final allFields = <String>{};
      for (var doc in snapshot.docs) {
        allFields.addAll((doc.data() as Map<String, dynamic>).keys);
      }
      final fields = selectedFields ?? allFields.toList();

      // Build CSV data
      List<List<dynamic>> rows = [];
      rows.add(fields); // Header

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> row = [];
        for (var field in fields) {
          final value = data[field];
          row.add(_formatValue(value));
        }
        rows.add(row);
      }

      // Convert to CSV
      final csv = const ListToCsvConverter().convert(rows);

      // Save file
      String basePath;
      if (kIsWeb) {
        basePath = 'downloads';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        basePath = dir.path;
      }
      final path = '$basePath/...';

      final file = File(path);
      await file.writeAsString(csv);

      return path;
    } catch (e) {
      print('🔥 Error exporting CSV: $e');
      throw Exception('Export failed: $e');
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      return DateFormat('yyyy-MM-dd HH:mm').format(value.toDate());
    }
    if (value is List) return value.join(', ');
    if (value is Map) return value.toString();
    return value.toString();
  }

  // ⭐️ ===== SHARE CSV =====

  Future<void> shareCSVFile(String path, String collectionName) async {
    final file = File(path);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'TURIVA - $collectionName Report',
      text: 'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
    );
  }

  // ⭐️ ===== PDF EXPORT =====

  Future<String> exportCollectionToPDF(
      String collection, {
        String reportTitle = 'Report',
        List<String>? selectedFields,

      }) async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection(collection).get();

      if (snapshot.docs.isEmpty) {
        throw Exception('No data in $collection');
      }
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      // Get all field names
      final allFields = <String>{};
      for (var doc in snapshot.docs) {
        allFields.addAll((doc.data() as Map<String, dynamic>).keys);
      }
      final fields = selectedFields ?? allFields.toList();

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0D47A1'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TURIVA',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        reportTitle,
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        DateFormat('dd MMM yyyy')
                            .format(DateTime.now()),
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${snapshot.docs.length} records',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5A623'),
                  ),
                  children: fields.map((field) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        field.toUpperCase(),
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Data Rows
                ...snapshot.docs.asMap().entries.map((entry) {
                  final data = entry.value.data()
                  as Map<String, dynamic>;
                  final rowColor = entry.key % 2 == 0
                      ? PdfColors.white
                      : PdfColors.grey100;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowColor),
                    children: fields.map((field) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          _formatValueForPDF(data[field]),
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '© 2025 TURIVA',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  '© 2025 TURIVA - Made in Tanzania',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      // Save
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${dir.path}/${collection}_$timestamp.pdf';

      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      return path;
    } catch (e) {
      print('🔥 Error exporting PDF: $e');
      throw Exception('PDF export failed: $e');
    }
  }

  String _formatValueForPDF(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(value.toDate());
    }
    if (value is List) return value.join(', ');
    if (value is Map) return value.toString();
    final str = value.toString();
    // Truncate long strings
    if (str.length > 50) return '${str.substring(0, 47)}...';
    return str;
  }

  Future<void> sharePDFFile(String path, String reportTitle) async {
    final file = File(path);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'TURIVA - $reportTitle',
      text: 'TURIVA Report - ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
    );
  }

  // ⭐️ ===== PRINT PDF =====

  Future<void> printPDF(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'TURIVA Report',
    );
  }

  // ⭐️ ===== STATS REPORT =====

  Future<String> exportStatsPDF() async {
    try {
      final usersCount =
          (await _firestore.collection('users').get()).docs.length;
      final bookingsCount =
          (await _firestore.collection('bookings').get()).docs.length;
      final destinationsCount =
          (await _firestore.collection('destinations').get()).docs.length;
      final hotelsCount =
          (await _firestore.collection('hotels').get()).docs.length;
      final toursCount =
          (await _firestore.collection('tours').get()).docs.length;
      final activitiesCount =
          (await _firestore.collection('activities').get()).docs.length;
      final dealsCount =
          (await _firestore.collection('deals').get()).docs.length;

      // Revenue
      double revenue = 0;
      final bookings = await _firestore
          .collection('bookings')
          .where('bookingStatus', whereIn: ['confirmed', 'completed'])
          .get();
      for (var doc in bookings.docs) {
        revenue += ((doc.data())['amount'] ?? 0.0).toDouble();
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0D47A1'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TURIVA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Platform Statistics Report',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              pw.Text(
                'Generated: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 30),

              // Stats Grid
              pw.Text(
                'Platform Overview',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0D47A1'),
                ),
              ),
              pw.SizedBox(height: 15),

              _statRow('Total Users', usersCount.toString()),
              _statRow('Total Bookings', bookingsCount.toString()),
              _statRow('Destinations', destinationsCount.toString()),
              _statRow('Hotels & Lodges', hotelsCount.toString()),
              _statRow('Tours & Safaris', toursCount.toString()),
              _statRow('Activities', activitiesCount.toString()),
              _statRow('Active Deals', dealsCount.toString()),

              pw.SizedBox(height: 30),

              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5A623'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Revenue',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      '\$${revenue.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  '© 2025 TURIVA - Made with love in Tanzania',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${dir.path}/TURIVA_Stats_$timestamp.pdf';

      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      return path;
    } catch (e) {
      print('🔥 Error exporting stats PDF: $e');
      throw Exception('Stats PDF export failed: $e');
    }
  }

  pw.Widget _statRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0D47A1'),
            ),
          ),
        ],
      ),
    );
  }
}