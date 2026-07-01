import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ScoreIndicator extends StatelessWidget {
  const ScoreIndicator({super.key, required this.score, this.compact = false});

  final int score;
  final bool compact;

  Color get _color {
    if (score >= 70) return AppColors.scoreHigh;
    if (score >= 45) return AppColors.scoreMedium;
    return AppColors.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Text(
        '$score',
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$score/100',
          style: TextStyle(
            color: _color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: AppColors.border,
          color: _color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
