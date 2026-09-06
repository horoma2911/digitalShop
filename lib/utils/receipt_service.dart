import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'currency_formatter.dart';
import '../models/product.dart';

class ReceiptService {
  static Future<void> generateAndOpenReceipt({
    required String shopName,
    required Product product,
    required int quantity,
  }) async {
    final pdf = pw.Document();
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final total = product.salePrice * quantity;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt style (80mm width)
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(shopName.toUpperCase(),
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(child: pw.Text('SALES RECEIPT', style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(date, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Items:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(product.name, style: const pw.TextStyle(fontSize: 10))),
                  pw.Text('$quantity x ${CurrencyFormatter.format(product.salePrice)}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL (TZS)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text(CurrencyFormatter.format(total),
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('THANK YOU FOR YOUR BUSINESS!',
                    style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text('Powered by DigitalShop',
                    style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }
}
