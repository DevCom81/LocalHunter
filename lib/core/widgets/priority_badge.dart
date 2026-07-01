import 'package:flutter/material.dart';
import '../constants/priority_level.dart';
import '../theme/badge_styles.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final PriorityLevel priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priorityColor(priority).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: priorityColor(priority).withValues(alpha: 0.4)),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: priorityColor(priority),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
