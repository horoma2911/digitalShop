import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../providers/report_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_colors.dart';
import 'widgets/sales_line_chart.dart';
import 'widgets/expense_pie_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportPeriod _period = ReportPeriod.daily;
  DateTimeRange? _customRange;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.martiamGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = ReportPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final stock = context.watch<StockProvider>();
    final expenseProv = context.watch<ExpenseProvider>();
    final reportProv = context.watch<ReportProvider>();
    
    final sales = stock.sales;
    final expenses = expenseProv.expenses;
    
    final data = reportProv.getReport(sales, expenses, _period, DateTime.now(), customRange: _customRange);
    final totalExp = expenseProv.getTotalExpenses(expenses, range: _period == ReportPeriod.custom ? _customRange : null);
    final netProfit = data.totalProfit - totalExp;
    
    final shop = auth.currentShop;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.selectPeriod, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<ReportPeriod>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.martiamGreen,
                    selectedForegroundColor: Colors.white,
                  ),
                  segments: [
                    ButtonSegment(value: ReportPeriod.daily, label: Text(l10n.day)),
                    ButtonSegment(value: ReportPeriod.weekly, label: Text(l10n.week)),
                    ButtonSegment(value: ReportPeriod.monthly, label: Text(l10n.month)),
                    ButtonSegment(value: ReportPeriod.yearly, label: Text(l10n.year)),
                    ButtonSegment(value: ReportPeriod.custom, label: Text(l10n.custom)),
                  ],
                  selected: {_period},
                  onSelectionChanged: (newVal) async {
                    if (newVal.first == ReportPeriod.custom) {
                      await _selectDateRange(context);
                    } else {
                      setState(() => _period = newVal.first);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.martiamGreen, AppColors.darkGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(data.dateRangeDisplay.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10)),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('TZS ${CurrencyFormatter.format(data.totalSales)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    Text(l10n.totalRevenue, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    const Divider(color: Colors.white24, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(l10n.grossProfit, 'TZS ${CurrencyFormatter.format(data.totalProfit)}'),
                        _buildMiniStat(l10n.expenses, 'TZS ${CurrencyFormatter.format(totalExp)}'),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'TOP: ${data.mostSoldProduct} (${data.mostSoldQuantity})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30)),
                      child: Text(
                        '${l10n.netProfit}: TZS ${CurrencyFormatter.format(netProfit)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(l10n.sales.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen, fontSize: 16)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SalesLineChart(points: data.chartPoints, isDaily: _period == ReportPeriod.daily),
                ),
              ),
              const SizedBox(height: 30),
              Text(l10n.expenses.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen, fontSize: 16)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ExpensePieChart(breakdown: data.expenseBreakdown),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final path = await reportProv.exportToExcel(data, shop?.name ?? 'Shop', _period.name);
                        OpenFilex.open(path);
                      },
                      icon: const Icon(Icons.table_view),
                      label: Text(l10n.excel),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final path = await reportProv.exportToPdf(data, shop?.name ?? 'Shop', _period.name);
                        OpenFilex.open(path);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(l10n.pdf),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}
