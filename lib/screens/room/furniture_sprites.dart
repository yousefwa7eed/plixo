import 'package:flutter/material.dart';

/// خريطة ألوان الأثاث - كل نوع له لون مختلف
/// هتستخدم لما ترسم الـ sprites في Piskel
class FurnitureColors {
  static const Map<String, Color> furnitureColorMap = {
    'bed':      Color(0xFF534AB7), // بنفسجي
    'desk':     Color(0xFF1D9E75), // أخضر
    'chair':    Color(0xFF7F77DD), // بنفسجي فاتح
    'plant':    Color(0xFF3AA33A), // أخضر غامق
    'shelf':    Color(0xFFBA7517), // برتقالي
    'lamp':     Color(0xFFEF9F27), // أصفر
    'sofa':     Color(0xFF5DCAA5), // تركواز
    'gaming':   Color(0xFFD85A30), // أحمر
  };
  
  static Color getColor(String type) {
    return furnitureColorMap[type] ?? const Color(0xFF888888);
  }
}
