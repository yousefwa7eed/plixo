import 'package:flutter/material.dart';

/// إعدادات الغرفة المركزية — كل الأرقام والألوان هنا
class RoomConfig {
  // ── شبكة الغرفة ─────────────────────────────────────────
  static const int gridCols    = 20;   // عدد الأعمدة
  static const int gridRows    = 14;   // عدد الصفوف الكلية
  static const int wallRows    = 4;    // صفوف الحيط (من الأعلى)
  static const int floorRows   = 10;   // صفوف الأرضية

  // ── حجم الـ Tile ─────────────────────────────────────────
  static const double baseTileSize = 16.0; // الحجم الأصلي في Piskel
  static double currentTileSize   = 40.0; // بيتحسب ديناميكياً

  // ── أبعاد الغرفة المحسوبة ───────────────────────────────
  static double get roomWidth    => gridCols * currentTileSize;
  static double get roomHeight   => gridRows * currentTileSize;
  static double get wallHeight   => wallRows * currentTileSize;
  static double get floorHeight  => floorRows * currentTileSize;
  static double get floorStartY  => wallHeight; // بداية الأرضية

  // ── حساب الحجم حسب الشاشة ───────────────────────────────
  static void recalculate(Size screenSize, {EdgeInsets padding = EdgeInsets.zero}) {
    final availW = screenSize.width  - padding.horizontal;
    final availH = screenSize.height - padding.vertical;
    final byWidth  = availW / gridCols;
    final byHeight = availH / gridRows;
    // اختر الأصغر عشان الغرفة تتناسب كاملة
    currentTileSize = (byWidth < byHeight ? byWidth : byHeight).clamp(20.0, 64.0);
  }

  // ── الألوان ─────────────────────────────────────────────
  static const Color wallColorA    = Color(0xFF13102B);
  static const Color wallColorB    = Color(0xFF1A1640);
  static const Color floorColorA   = Color(0xFF1A1740);
  static const Color floorColorB   = Color(0xFF221E50);
  static const Color gridLineColor = Color(0x0D7F77DD);
  static const Color floorBorder   = Color(0xFF2A2260);
  static const Color accentPurple  = Color(0xFF534AB7);
  static const Color accentTeal    = Color(0xFF1D9E75);
  static const Color accentGold    = Color(0xFFEF9F27);

  // ── تعريفات الأثاث ──────────────────────────────────────
  // assetPath كلهم بيشيروا لـ furniture_box.png المتاحة دلوقتي
  // هتستبدلهم بالصور الصح لما ترسمهم في Piskel
  static const Map<String, FurnitureDef> furnitureDefs = {
    'bed':      FurnitureDef(gridW: 4, gridH: 2, label: 'سرير',        emoji: '🛏️',  assetPath: 'furniture_box.png', price: 0),
    'desk':     FurnitureDef(gridW: 5, gridH: 2, label: 'مكتب',        emoji: '🖥️',  assetPath: 'furniture_box.png', price: 8),
    'chair':    FurnitureDef(gridW: 2, gridH: 3, label: 'كرسي',        emoji: '🪑',  assetPath: 'furniture_box.png', price: 3),
    'plant':    FurnitureDef(gridW: 1, gridH: 3, label: 'نبتة',        emoji: '🌱',  assetPath: 'furniture_box.png', price: 2),
    'shelf':    FurnitureDef(gridW: 4, gridH: 3, label: 'رف',          emoji: '📚',  assetPath: 'furniture_box.png', price: 5),
    'lamp':     FurnitureDef(gridW: 1, gridH: 3, label: 'لمبة',        emoji: '💡',  assetPath: 'furniture_box.png', price: 4),
    'sofa':     FurnitureDef(gridW: 5, gridH: 2, label: 'أريكة',       emoji: '🛋️',  assetPath: 'furniture_box.png', price: 10),
    'gaming':   FurnitureDef(gridW: 2, gridH: 4, label: 'كرسي Gaming', emoji: '🎮',  assetPath: 'furniture_box.png', price: 15),
  };
}

/// تعريف قطعة أثاث واحدة
class FurnitureDef {
  final int    gridW;
  final int    gridH;
  final String label;
  final String emoji;
  final String assetPath;
  final int    price; // بالكوينز

  const FurnitureDef({
    required this.gridW,
    required this.gridH,
    required this.label,
    required this.emoji,
    required this.assetPath,
    required this.price,
  });
}