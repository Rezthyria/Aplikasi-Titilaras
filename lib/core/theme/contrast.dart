import 'dart:math' as math;

import 'package:flutter/material.dart';

class ContrastPair {
  final Color foreground;
  final Color background;

  const ContrastPair(this.foreground, this.background);
}

double contrastRatio(Color foreground, Color background) {
  final l1 = _relativeLuminance(foreground);
  final l2 = _relativeLuminance(background);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double channel(double c) {
    return c <= 0.03928 ? c / 12.92 : powDouble((c + 0.055) / 1.055, 2.4);
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double powDouble(double base, double exponent) {
  return math.pow(base, exponent).toDouble();
}
