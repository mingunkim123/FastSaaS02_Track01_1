import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportChart extends StatelessWidget {
  final Map<String, dynamic> section;

  const ReportChart({
    Key? key,
    required this.section,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chartType = section['type'] as String? ?? 'bar';
    final title = section['title'] as String?;
    final data = section['data'] as List<dynamic>?;

    // Handle missing or invalid data
    if (data == null || data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: _buildChart(chartType, data),
        ),
      ],
    );
  }

  Widget _buildChart(String chartType, List<dynamic> data) {
    switch (chartType) {
      case 'pie':
        return _buildPieChart(data);
      case 'bar':
        return _buildBarChart(data);
      case 'line':
        return _buildLineChart(data);
      default:
        return Center(
          child: Text('Unknown chart type: $chartType'),
        );
    }
  }

  Widget _buildPieChart(List<dynamic> data) {
    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
    ];

    double total = 0;
    for (var item in data) {
      final value = _getChartValue(item);
      total += value;
    }

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final value = _getChartValue(item);
      final percentage = total > 0 ? (value / total) * 100 : 0;

      sections.add(
        PieChartSectionData(
          value: value,
          color: colors[i % colors.length],
          title: '${percentage.toStringAsFixed(1)}%',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(sections: sections),
    );
  }

  Widget _buildBarChart(List<dynamic> data) {
    final barGroups = <BarChartGroupData>[];
    final maxValue = data
        .map((item) => _getChartValue(item))
        .reduce((a, b) => a > b ? a : b);

    for (var i = 0; i < data.length && i < 8; i++) {
      final item = data[i];
      final value = _getChartValue(item);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: Colors.blue,
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        maxY: maxValue > 0 ? maxValue * 1.1 : 100,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
      ),
    );
  }

  Widget _buildLineChart(List<dynamic> data) {
    final spots = <FlSpot>[];
    final maxValue = data
        .map((item) => _getChartValue(item))
        .reduce((a, b) => a > b ? a : b);

    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final value = _getChartValue(item);
      spots.add(FlSpot(i.toDouble(), value));
    }

    return LineChart(
      LineChartData(
        maxY: maxValue > 0 ? maxValue * 1.1 : 100,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  /// Extract numeric value from chart data item
  /// Handles both direct numbers and objects with 'value' field
  double _getChartValue(dynamic item) {
    if (item is num) return item.toDouble();
    if (item is Map<String, dynamic>) {
      final value = item['value'];
      if (value is num) return value.toDouble();
    }
    return 0.0;
  }
}
