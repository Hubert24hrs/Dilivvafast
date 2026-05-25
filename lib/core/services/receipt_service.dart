// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
import 'package:fast_delivery/core/models/ride_model.dart';
import 'package:flutter/foundation.dart';

class ReceiptService {
  // Generate PDF receipt for a ride
  Future<String> generateReceipt(RideModel ride) async {
    // WEB COMPATIBILITY: functionality disabled
    debugPrint('ReceiptService: generateReceipt called. (Disabled for Web Build)');
    return 'receipt_stub.pdf'; 
    /*
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'FAST DELIVERY',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
              ),
              // ... truncated ...
            ],
          );
        },
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_${ride.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
    */
  }
}
