import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../models/line_item.dart';
import '../models/customer.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required List<LineItem> items,
    required Customer customer,
    String? businessName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName ?? 'Your Business',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (businessEmail != null)
                        pw.Text(businessEmail, style: const pw.TextStyle(fontSize: 10)),
                      if (businessPhone != null)
                        pw.Text(businessPhone, style: const pw.TextStyle(fontSize: 10)),
                      if (businessAddress != null)
                        pw.Text(businessAddress, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.Text(
                        invoice.invoiceNumber,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Bill To
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          customer.name,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (customer.email != null)
                          pw.Text(customer.email!, style: const pw.TextStyle(fontSize: 10)),
                        if (customer.phone != null)
                          pw.Text(customer.phone!, style: const pw.TextStyle(fontSize: 10)),
                        if (customer.address != null)
                          pw.Text(customer.address!, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildInfoRow('Date:', _formatDate(invoice.createdAt)),
                      if (invoice.dueDate != null)
                        _buildInfoRow('Due Date:', _formatDate(invoice.dueDate!)),
                      _buildInfoRow('Status:', invoice.status.name.toUpperCase()),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Item', isHeader: true),
                      _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Price', isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Items
                  ...items.map((item) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(
                          item.description != null
                              ? '${item.name}\n${item.description}'
                              : item.name,
                        ),
                        _buildTableCell(
                          item.quantity.toString(),
                          align: pw.TextAlign.center,
                        ),
                        _buildTableCell(
                          '\$${item.unitPrice.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                        ),
                        _buildTableCell(
                          '\$${item.total.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildTotalRow('Subtotal:', invoice.subtotal),
                      if (invoice.tax > 0)
                        _buildTotalRow('Tax:', invoice.tax),
                      if (invoice.discount > 0)
                        _buildTotalRow('Discount:', -invoice.discount, isNegative: true),
                      pw.Divider(),
                      _buildTotalRow('TOTAL:', invoice.total, isTotal: true),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Notes
              if (invoice.notes != null) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 10)),
              ],

              // Footer
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isNegative = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: isTotal ? 14 : 10,
                fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.SizedBox(width: 20),
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '${isNegative ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: isTotal ? 14 : 10,
                fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isNegative ? PdfColors.red : null,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  static Future<void> printInvoice({
    required Invoice invoice,
    required List<LineItem> items,
    required Customer customer,
    String? businessName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      invoice: invoice,
      items: items,
      customer: customer,
      businessName: businessName,
      businessEmail: businessEmail,
      businessPhone: businessPhone,
      businessAddress: businessAddress,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
    );
  }

  static Future<void> shareInvoice({
    required Invoice invoice,
    required List<LineItem> items,
    required Customer customer,
    String? businessName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      invoice: invoice,
      items: items,
      customer: customer,
      businessName: businessName,
      businessEmail: businessEmail,
      businessPhone: businessPhone,
      businessAddress: businessAddress,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${invoice.invoiceNumber}.pdf',
    );
  }
}