import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ExpensePieChart extends StatelessWidget {
  final Map<String, double> breakdown;

  const ExpensePieChart({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const Center(child: Text('No expense data for this period'));

    final List<Color> colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: breakdown.entries.indexed.map((e) {
                final index = e.$1;
                final entry = e.$2;
                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: entry.value,
                  title: '', // Title shown in legend instead
                  radius: 50,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 15,
          runSpacing: 5,
          alignment: WrapAlignment.center,
          children: breakdown.entries.indexed.map((e) {
            final index = e.$1;
            final entry = e.$2;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text("${entry.key}: TZS ${entry.value.toStringAsFixed(0)}", style: const TextStyle(fontSize: 11, color: AppColors.darkGreen)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
