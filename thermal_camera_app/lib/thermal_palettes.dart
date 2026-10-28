import 'dart:ui';
import 'package:flutter/material.dart';

class ThermalPalettes {
  static const List<Color> ironbow = [
    Color(0xFF000000), // Black
    Color(0xFF000080), // Dark Blue
    Color(0xFF800080), // Purple
    Color(0xFFFF0000), // Red
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFFFFFF), // White
  ];

  static const List<Color> rainbow = [
    Color(0xFF0000FF), // Blue
    Color(0xFF00FFFF), // Cyan
    Color(0xFF00FF00), // Green
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF0000), // Red
  ];

  static const List<Color> whiteHot = [
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
  ];

  static const List<Color> blackHot = [
    Color(0xFFFFFFFF), // White
    Color(0xFF000000), // Black
  ];

  // Helper method to generate a 256-color palette based on gradient stops
  static List<int> generatePalette(List<Color> colors) {
    List<int> palette = List.filled(256, 0);
    int numColors = colors.length;
    int sectionSize = 255 ~/ (numColors - 1);

    for (int i = 0; i < numColors - 1; i++) {
      Color c1 = colors[i];
      Color c2 = colors[i + 1];

      for (int j = 0; j < sectionSize; j++) {
        double t = j / sectionSize;
        int r = (c1.red + (c2.red - c1.red) * t).round();
        int g = (c1.green + (c2.green - c1.green) * t).round();
        int b = (c1.blue + (c2.blue - c1.blue) * t).round();

        int index = i * sectionSize + j;
        if (index < 256) {
          palette[index] = 0xFF000000 | (r << 16) | (g << 8) | b;
        }
      }
    }

    // Fill the remaining spots if any due to integer division
    Color lastColor = colors.last;
    int lastValue = 0xFF000000 | (lastColor.red << 16) | (lastColor.green << 8) | lastColor.blue;
    for (int i = (numColors - 1) * sectionSize; i < 256; i++) {
      palette[i] = lastValue;
    }

    return palette;
  }
}
