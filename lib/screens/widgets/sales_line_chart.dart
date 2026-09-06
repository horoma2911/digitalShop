import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../providers/report_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/app_colors.dart';

class SalesLineChart extends StatelessWidget {
  final List<ChartDataPoint> points;
  final bool isDaily;

  const SalesLineChart({super.key, required this.points, this.isDaily = false});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    double maxY = points.fold(0.0, (max, p) => p.y > max ? p.y : max);
    if (maxY == 0) maxY = 1000; // Default scale if no sales

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxY / 5,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1),
              getDrawingVerticalLine: (value) => const FlLine(color: Color(0xffe7e8ec), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: points.length > 10 ? (points.length / 5).floorToDouble() : 1,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < points.length) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(points[index].label, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY / 5,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    String text = value >= 1000000 ? "${(value / 1000000).toStringAsFixed(1)}M" : value >= 1000 ? "${(value / 1000).toInt()}k" : value.toInt().toString();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(text, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                    );
                  },
                  reservedSize: 42,
                ),
              ),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d).withValues(alpha: 0.1))),
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.2,
            lineBarsData: [
              LineChartBarData(
                spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.y)).toList(),
                isCurved: true,
                gradient: const LinearGradient(colors: [AppColors.martiamGreen, AppColors.accentGreen]),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.martiamGreen.withValues(alpha: 0.3),
                      AppColors.martiamGreen.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => AppColors.darkGreen,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      "TZS ${CurrencyFormatter.format(spot.y)}\n${points[spot.x.toInt()].label}",
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
