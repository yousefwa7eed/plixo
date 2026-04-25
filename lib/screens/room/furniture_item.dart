import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'room_config.dart';
import 'room_game.dart';

/// قطعة أثاث واحدة — تدعم السحب والإفلات مع كشف التصادم
class FurnitureItem extends PositionComponent
    with DragCallbacks, HasGameRef<RoomGame> {

  // ── بيانات القطعة ────────────────────────────────────────
  final String     id;
  final String     furnitureType; // 'bed', 'desk', 'chair'…

  int _gridX;
  int _gridY;
  int get gridX => _gridX;
  int get gridY => _gridY;

  // ── حالة السحب ───────────────────────────────────────────
  bool   _isDragging     = false;
  bool   _canPlace       = true;
  int    _snapGridX      = 0;
  int    _snapGridY      = 0;
  Offset _savedPosition  = Offset.zero; // للرجوع لو التوضيع مش صالح

  // ── الـ Sprite ────────────────────────────────────────────
  Sprite? _sprite;

  FurnitureItem({
    required this.id,
    required this.furnitureType,
    required int gridX,
    required int gridY,
  })  : _gridX = gridX,
        _gridY  = gridY,
        super(anchor: Anchor.topLeft);

  FurnitureDef get _def =>
      RoomConfig.furnitureDefs[furnitureType] ??
          const FurnitureDef(gridW: 1, gridH: 1, label: '?', emoji: '❓',
              assetPath: '', price: 0);

  // ── تحميل ────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_def.assetPath.isNotEmpty) {
      try {
        _sprite = await gameRef.loadSprite(_def.assetPath);
      } catch (_) {}
    }
    _applyGridPosition(_gridX, _gridY);
  }

  /// حساب الحجم والموقع من إحداثيات الشبكة
  void _applyGridPosition(int gx, int gy) {
    final t = RoomConfig.currentTileSize;
    size     = Vector2(_def.gridW * t, _def.gridH * t);
    position = Vector2(gx * t, gy * t);
    // Z-order: الأثاث الأقرب للأمام (y أكبر) يكون فوق
    priority = gy + _def.gridH;
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    _applyGridPosition(_gridX, _gridY);
  }

  // ── السحب ────────────────────────────────────────────────
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging    = true;
    _savedPosition = Offset(position.x, position.y);
    // ارفعه للأمام أثناء السحب
    priority = 999;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) return;
    position += event.localDelta;

    // حسب إحداثيات الشبكة الحالية
    final t   = RoomConfig.currentTileSize;
    _snapGridX = (position.x / t).round().clamp(0, RoomConfig.gridCols - _def.gridW);
    _snapGridY = (position.y / t).round().clamp(
      RoomConfig.wallRows,                              // فوق الأرضية بس
      RoomConfig.gridRows - _def.gridH,
    );

    // هل الموضع فاضي؟
    _canPlace = gameRef.canPlace(
      excludeId : id,
      gridX     : _snapGridX,
      gridY     : _snapGridY,
      gridW     : _def.gridW,
      gridH     : _def.gridH,
    );
    
    // تحديث الـ priority أثناء السحب عشان القطعة تطلع فوق
    priority = 1000 + _snapGridY;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;

    if (_canPlace) {
      // ثبّت في المكان الجديد
      _gridX = _snapGridX;
      _gridY = _snapGridY;
      _applyGridPosition(_gridX, _gridY);
    } else {
      // ارجع للمكان القديم
      position = Vector2(_savedPosition.dx, _savedPosition.dy);
      priority = _gridY + _def.gridH;
    }
    _canPlace = true;
  }

  // ── الرسم ─────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    if (_sprite != null) {
      _sprite!.render(canvas, position: Vector2.zero(), size: size);
    } else {
      // fallback لو الصورة مش موجودة — مربع ملون بلون النوع
      final bodyPaint = Paint()..color = _typeColor.withOpacity(0.55);
      canvas.drawRect(rect.deflate(2), bodyPaint);

      // رسم Emoji في المنتصف
      final tp = TextPainter(
        text: TextSpan(
          text: _def.emoji,
          style: TextStyle(fontSize: size.y * 0.45),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2),
      );
    }

    // ── مؤشر السحب ──────────────────────────────────────────
    if (_isDragging) {
      // ظل الموضع الجديد (snap preview)
      final snapX = _snapGridX * RoomConfig.currentTileSize - position.x;
      final snapY = _snapGridY * RoomConfig.currentTileSize - position.y;
      final previewRect = Rect.fromLTWH(snapX, snapY, size.x, size.y);

      canvas.drawRect(
        previewRect,
        Paint()
          ..color = (_canPlace ? Colors.greenAccent : Colors.redAccent)
              .withOpacity(0.25),
      );
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = _canPlace ? Colors.greenAccent : Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // إطار القطعة الحالية شفاف
      canvas.drawRect(
        rect.deflate(1),
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  Color get _typeColor {
    switch (furnitureType) {
      case 'bed':    return const Color(0xFF534AB7);
      case 'desk':   return const Color(0xFF1D9E75);
      case 'chair':  return const Color(0xFF7F77DD);
      case 'plant':  return const Color(0xFF3AA33A);
      case 'shelf':  return const Color(0xFFBA7517);
      case 'lamp':   return const Color(0xFFEF9F27);
      case 'sofa':   return const Color(0xFF5DCAA5);
      case 'gaming': return const Color(0xFFD85A30);
      default:       return const Color(0xFF888888);
    }
  }

  /// بيانات الحفظ
  Map<String, dynamic> toJson() => {
    'id'   : id,
    'type' : furnitureType,
    'x'    : _gridX,
    'y'    : _gridY,
  };
}