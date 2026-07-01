import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/priority_level.dart';
import '../../core/constants/offer_types.dart';

Color priorityColor(PriorityLevel level) {
  return switch (level) {
    PriorityLevel.high => AppColors.highPriority,
    PriorityLevel.medium => AppColors.mediumPriority,
    PriorityLevel.low => AppColors.lowPriority,
    PriorityLevel.excluded => AppColors.excluded,
  };
}

Color offerColor(OfferType offer) {
  return switch (offer) {
    OfferType.website => const Color(0xFF2563EB),
    OfferType.businessSoftware => const Color(0xFF7C3AED),
    OfferType.easyRest => const Color(0xFF059669),
    OfferType.crm => const Color(0xFF64748B),
  };
}
