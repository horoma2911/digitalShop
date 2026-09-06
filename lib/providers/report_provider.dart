import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/sale.dart';
import '../models/expense.dart';

enum ReportPeriod { daily, weekly, monthly, yearly, custom }

class ChartDataPoint {
  final double x;
  final double y;
  final String label;

  ChartDataPoint({required this.x, required this.y, required this.label});
}

class ReportData {
  final double totalSales;
  final double totalProfit;
  final List<Sale> sales;
  final String dateRangeDisplay;
  final List<ChartDataPoint> chartPoints;
  final Map<String, double> expenseBreakdown;
  final String mostSoldProduct;
  final int mostSoldQuantity;

  ReportData({
    required this.totalSales,
    required this.totalProfit,
    required this.sales,
    required this.dateRangeDisplay,
    required this.chartPoints,
    required this.expenseBreakdown,
    required this.mostSoldProduct,
    required this.mostSoldQuantity,
  });
}

class ReportProvider with ChangeNotifier {
  ReportData getReport(List<Sale> allSales, List<Expense> allExpenses, ReportPeriod period, DateTime date, {DateTimeRange? customRange}) {
    List<Sale> filteredSales = [];
    List<Expense> filteredExpenses = [];
    String rangeDisplay = "";
    Map<int, double> grouping = {};
    List<ChartDataPoint> chartPoints = [];
    Map<String, int> productQuantities = {};

    for (var sale in allSales) {
      bool match = false;
      switch (period) {
        case ReportPeriod.daily:
          match = sale.date.year == date.year &&
              sale.date.month == date.month &&
              sale.date.day == date.day;
          rangeDisplay = DateFormat('yyyy-MM-dd').format(date);
          if (match) {
            grouping[sale.date.hour] = (grouping[sale.date.hour] ?? 0) + sale.totalPrice;
          }
          break;
        case ReportPeriod.weekly:
          final difference = date.difference(sale.date).inDays;
          match = difference >= 0 && difference < 7;
          rangeDisplay = "Last 7 Days";
          if (match) {
            grouping[sale.date.weekday] = (grouping[sale.date.weekday] ?? 0) + sale.totalPrice;
          }
          break;
        case ReportPeriod.monthly:
          match = sale.date.year == date.year && sale.date.month == date.month;
          rangeDisplay = DateFormat('MMMM yyyy').format(date);
          if (match) {
            grouping[sale.date.day] = (grouping[sale.date.day] ?? 0) + sale.totalPrice;
          }
          break;
        case ReportPeriod.yearly:
          match = sale.date.year == date.year;
          rangeDisplay = date.year.toString();
          if (match) {
            grouping[sale.date.month] = (grouping[sale.date.month] ?? 0) + sale.totalPrice;
          }
          break;
        case ReportPeriod.custom:
          if (customRange != null) {
            final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
            final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
            match = (sale.date.isAfter(start) || sale.date.isAtSameMomentAs(start)) && 
                    (sale.date.isBefore(end) || sale.date.isAtSameMomentAs(end));
            rangeDisplay = "${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}";
            if (match) {
              int dayKey = DateTime(sale.date.year, sale.date.month, sale.date.day).millisecondsSinceEpoch;
              grouping[dayKey] = (grouping[dayKey] ?? 0) + sale.totalPrice;
            }
          }
          break;
      }
      if (match) {
        filteredSales.add(sale);
        productQuantities[sale.productName] = (productQuantities[sale.productName] ?? 0) + sale.quantity;
      }
    }

    String topProduct = "None";
    int topQty = 0;
    if (productQuantities.isNotEmpty) {
      var sorted = productQuantities.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topProduct = sorted.first.key;
      topQty = sorted.first.value;
    }

    for (var exp in allExpenses) {
      bool match = false;
      switch (period) {
        case ReportPeriod.daily:
          match = exp.date.year == date.year && exp.date.month == date.month && exp.date.day == date.day;
          break;
        case ReportPeriod.weekly:
          final difference = date.difference(exp.date).inDays;
          match = difference >= 0 && difference < 7;
          break;
        case ReportPeriod.monthly:
          match = exp.date.year == date.year && exp.date.month == date.month;
          break;
        case ReportPeriod.yearly:
          match = exp.date.year == date.year;
          break;
        case ReportPeriod.custom:
          if (customRange != null) {
            final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
            final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
            match = (exp.date.isAfter(start) || exp.date.isAtSameMomentAs(start)) && (exp.date.isBefore(end) || exp.date.isAtSameMomentAs(end));
          }
          break;
      }
      if (match) filteredExpenses.add(exp);
    }

    Map<String, double> breakdown = {};
    for (var exp in filteredExpenses) {
      breakdown[exp.category] = (breakdown[exp.category] ?? 0) + exp.amount;
    }

    // Generate chart points based on period
    if (period == ReportPeriod.daily) {
      for (int i = 0; i < 24; i++) {
        chartPoints.add(ChartDataPoint(x: i.toDouble(), y: grouping[i] ?? 0, label: "$i:00"));
      }
    } else if (period == ReportPeriod.weekly) {
      List<String> weekdays = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      for (int i = 1; i <= 7; i++) {
        chartPoints.add(ChartDataPoint(x: i.toDouble(), y: grouping[i] ?? 0, label: weekdays[i]));
      }
    } else if (period == ReportPeriod.monthly) {
      int daysInMonth = DateTime(date.year, date.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        chartPoints.add(ChartDataPoint(x: i.toDouble(), y: grouping[i] ?? 0, label: "Day $i"));
      }
    } else if (period == ReportPeriod.yearly) {
      List<String> months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      for (int i = 1; i <= 12; i++) {
        chartPoints.add(ChartDataPoint(x: i.toDouble(), y: grouping[i] ?? 0, label: months[i]));
      }
    } else if (period == ReportPeriod.custom && customRange != null) {
      var diff = customRange.end.difference(customRange.start).inDays;
      for (int i = 0; i <= diff; i++) {
        DateTime current = customRange.start.add(Duration(days: i));
        int dayKey = DateTime(current.year, current.month, current.day).millisecondsSinceEpoch;
        chartPoints.add(ChartDataPoint(
          x: i.toDouble(), 
          y: grouping[dayKey] ?? 0, 
          label: DateFormat('MM/dd').format(current)
        ));
      }
    }

    double totalSales = filteredSales.fold(0, (sum, item) => sum + item.totalPrice);
    double totalProfit = filteredSales.fold(0, (sum, item) => sum + item.profit);

    return ReportData(
      totalSales: totalSales,
      totalProfit: totalProfit,
      sales: filteredSales,
      dateRangeDisplay: rangeDisplay,
      chartPoints: chartPoints,
      expenseBreakdown: breakdown,
      mostSoldProduct: topProduct,
      mostSoldQuantity: topQty,
    );
  }

  Future<String> exportToExcel(ReportData data, String shopName, String periodName) async {
    var excel = Excel.createExcel();
    String sheetName = 'Sales Report';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    Sheet sheetObject = excel[sheetName];

    sheetObject.appendRow([
      TextCellValue('Shop Name:'),
      TextCellValue(shopName),
    ]);
    sheetObject.appendRow([
      TextCellValue('Report Period:'),
      TextCellValue(data.dateRangeDisplay),
    ]);
    sheetObject.appendRow([]);
    sheetObject.appendRow([
      TextCellValue('Date'),
      TextCellValue('Product'),
      TextCellValue('Quantity'),
      TextCellValue('Total Price (TZS)'),
      TextCellValue('Profit (TZS)'),
    ]);

    for (var sale in data.sales) {
      sheetObject.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(sale.date)),
        TextCellValue(sale.productName),
        IntCellValue(sale.quantity),
        DoubleCellValue(sale.totalPrice),
        DoubleCellValue(sale.profit),
      ]);
    }

    sheetObject.appendRow([]);
    sheetObject.appendRow([TextCellValue('Summary')]);
    sheetObject.appendRow([TextCellValue('Total Sales'), DoubleCellValue(data.totalSales)]);
    sheetObject.appendRow([TextCellValue('Total Profit'), DoubleCellValue(data.totalProfit)]);
    sheetObject.appendRow([TextCellValue('Top Product'), TextCellValue("${data.mostSoldProduct} (${data.mostSoldQuantity})")]);

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }
    return path;
  }

  Future<String> exportToPdf(ReportData data, String shopName, String periodName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Sales Report - $shopName', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Period: ${data.dateRangeDisplay}'),
              pw.Text('Top Product: ${data.mostSoldProduct} (${data.mostSoldQuantity})'),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Product', 'Qty', 'Total (TZS)', 'Profit (TZS)'],
                data: data.sales.map((s) => [
                  DateFormat('MM-dd HH:mm').format(s.date),
                  s.productName,
                  s.quantity.toString(),
                  s.totalPrice.toStringAsFixed(2),
                  s.profit.toStringAsFixed(2),
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Sales: TZS ${data.totalSales.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Total Profit: TZS ${data.totalProfit.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }
}
