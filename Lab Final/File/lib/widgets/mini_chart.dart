import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

class MiniTrendChart extends StatelessWidget {
  final List<TrendPoint> data;
  const MiniTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('No data', style: TextStyle(color: AppColors.mutedFg))));
    }
    final maxY = data.fold<double>(0, (m, d) => [m, d.present.toDouble(), d.absent.toDouble(), d.late.toDouble()].reduce((a, b) => a > b ? a : b));

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  final label = data[i].date.length >= 5 ? data[i].date.substring(5) : data[i].date;
                  return Text(label, style: const TextStyle(fontSize: 9, color: AppColors.mutedFg));
                },
                reservedSize: 20,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY + 2,
          lineBarsData: [
            _line(data.map((d) => d.present.toDouble()).toList(), AppColors.present),
            _line(data.map((d) => d.absent.toDouble()).toList(), AppColors.absent),
            _line(data.map((d) => d.late.toDouble()).toList(), AppColors.late),
          ],
        ),
      ),
    );
  }

  LineChartBarData _line(List<double> values, Color color) => LineChartBarData(
        spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
        isCurved: true,
        color: color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: color.withOpacity(0.08),
        ),
      );
}

class MiniBarChart extends StatelessWidget {
  final List<({String label, double value})> data;
  const MiniBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 100);
    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  final label = data[i].label;
                  final short = label.length > 5 ? label.substring(0, 5) : label;
                  return Text(short, style: const TextStyle(fontSize: 9, color: AppColors.mutedFg));
                },
                reservedSize: 18,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: AppColors.primary,
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }
}
