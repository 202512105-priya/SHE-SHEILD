import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  static Future<void> generateAndPrintReport({
    required Map<String, dynamic> caseDoc,
    required Map<String, dynamic> victimDoc,
    required List<Map<String, dynamic>> evidenceList,
    required List<Map<String, dynamic>> timelineLogs,
    required List<Map<String, dynamic>> guardiansList,
  }) async {
    final pdf = pw.Document();

    final String caseId = caseDoc['caseId'] ?? "SHS-2025-000001";
    final String incidentId = caseDoc['sourceId'] ?? "INC-2025-000001";
    final String status = caseDoc['status'] ?? "Under Investigation";
    final String priority = caseDoc['casePriority'] ?? "High";
    final String severity = caseDoc['caseSeverity'] ?? "High";
    final String timestamp = caseDoc['createdAt'] ?? DateTime.now().toIso8601String();
    
    final String victimName = victimDoc['name'] ?? "Unknown Citizen";
    final String victimPhone = victimDoc['mobile'] ?? "N/A";
    final String victimEmail = victimDoc['email'] ?? "N/A";
    final String victimUid = victimDoc['uid'] ?? "N/A";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.sp
<truncated 6454 bytes>
            pw.Column(
                children: timelineLogs.map((log) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(log['remarks'] ?? log['statusEvent'] ?? "Incident status updated"),
                        pw.Text(log['timestamp']?.toString().substring(0, 10) ?? ""),
                      ],
                    ),
                  );
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Outcome
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.purple, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "FINAL OUTCOME: ${status.toUpperCase()}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, textColor: PdfColors.purple),
                  ),
                  pw.Text(
                    "Priority Level: ${priority.toUpperCase()}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, textColor: PdfColors.red),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
