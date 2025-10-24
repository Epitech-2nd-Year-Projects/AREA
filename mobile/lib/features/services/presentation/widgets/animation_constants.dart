import 'package:flutter/material.dart';

class AnimationConstants {
  // Durations
  static const Duration shortDuration = Duration(milliseconds: 300);
  static const Duration mediumDuration = Duration(milliseconds: 500);
  static const Duration longDuration = Duration(milliseconds: 800);
  
  // Curves
  static final curve = Curves.easeInOutCubic;
  static final bouncy = Curves.elasticOut;
}