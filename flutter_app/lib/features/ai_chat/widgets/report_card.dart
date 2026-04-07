import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final Map<String, dynamic> section;

  const ReportCard({
    Key? key,
    required this.section,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sectionType = section['type'] as String? ?? 'card';
    final title = section['title'] as String?;
    final content = section['content'] as String?;

    Color backgroundColor;
    Color borderColor;
    IconData? icon;

    switch (sectionType) {
      case 'alert':
        backgroundColor = Colors.orange[50]!;
        borderColor = Colors.orange[300]!;
        icon = Icons.warning_rounded;
        break;
      case 'suggestion':
        backgroundColor = Colors.blue[50]!;
        borderColor = Colors.blue[300]!;
        icon = Icons.lightbulb_rounded;
        break;
      case 'card':
      default:
        backgroundColor = Colors.grey[100]!;
        borderColor = Colors.grey[300]!;
        icon = null;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: borderColor),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          if (title != null && content != null) const SizedBox(height: 8),
          if (content != null)
            Text(
              content,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
