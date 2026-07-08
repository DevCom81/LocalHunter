import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/priority_level.dart';

Color priorityColor(PriorityLevel level) {
  return switch (level) {
    PriorityLevel.high => AppColors.highPriority,
    PriorityLevel.medium => AppColors.mediumPriority,
    PriorityLevel.low => AppColors.lowPriority,
    PriorityLevel.excluded => AppColors.excluded,
  };
}
