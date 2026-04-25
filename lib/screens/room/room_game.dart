import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'room_config.dart';
import 'furniture_item.dart';

/// المحرك الرئيسي للغرفة — يرسم الـ Dollhouse View
/// ويدير الـ Grid والتصادم والحفظ
class RoomGame extends FlameGame with DragCallbacks {

  final List<Map<String, dynamic>>? savedLayout;
  RoomGame({this.savedLayout});

  // ── لون الخلفية خلف الغرفة (بدل الأسود) ─────────────────
  @override
  Color backgroundColor() => const Color(0xFF0D0B1A);

  // ── Sprites للخلفية ──────────────────────────────────────
  Sprite? _floorTileA;
  Sprite? _floorTileB;
  Sprite? _wallTileA;
  Sprite? _wallTileB;

  bool _ready = false;

  // ── تحميل ─────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    // تحميل الـ sprites — الأسماء متوافقة مع الملفات الموجودة
    _floorTileA = await _tryLoadSprite('tile_floor.png');
    _floorTileB = await _tryLoadSprite('tile_floor.png'); // نفس الملف — تكرار للـ checkerboard
    _wallTileA  = await _tryLoadSprite('tile_wall.png');
    _wallTileB  = await _tryLoadSprite('tile_wall.png');  // نفس الملف

    _ready = true;
    _rebuild();
  }

  Future<Sprite?> _tryLoadSprite(String path) async {
    try { return await loadSprite(path); } catch (_) { return null; }
  }

  // ── Resize ────────────────────────────────────────────────
  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    RoomConfig.recalculate(Size(newSize.x, newSize.y));
    if (_ready) _rebuild();
  }

  // ── بناء الغرفة ───────────────────────────────────────────
  void _rebuild() {
    // احذف كل العناصر القديمة
    removeAll(children.toList());

    _drawBackground();
    _spawnFurniture(savedLayout);
  }

  void _drawBackground() {
    final t = RoomConfig.currentTileSize;
    final tv = Vector2.all(t);

    for (int row = 0; row < RoomConfig.gridRows; row++) {
      final isWall = row < RoomConfig.wallRows;

      for (int col = 0; col < RoomConfig.gridCols; col++) {
        final pos = Vector2(col * t, row * t);
        final isEven = (row + col) % 2 == 0;

        Sprite? sprite;
        Color   fallback;

        if (isWall) {
          sprite   = isEven ? _wallTileA : _wallTileB;
          fallback = isEven
              ? RoomConfig.wallColorA
              : RoomConfig.wallColorB;
        } else {
          sprite   = isEven ? _floorTileA : _floorTileB;
          fallback = isEven
              ? RoomConfig.floorColorA
              : RoomConfig.floorColorB;
        }

        if (sprite != null) {
          add(SpriteComponent(sprite: sprite, size: tv, position: pos)
            ..priority = -10);
        } else {
          add(RectangleComponent(
            size    : tv,
            position: pos,
            paint   : Paint()..color = fallback,
          )..priority = -10);
        }
      }
    }

    // ── خط الأرضية (الـ Floor Border) ──────────────────────
    add(RectangleComponent(
      size    : Vector2(RoomConfig.roomWidth, 3),
      position: Vector2(0, RoomConfig.floorStartY),
      paint   : Paint()..color = RoomConfig.floorBorder,
    )..priority = -9);

    // ── خطوط الشبكة (شفافة جداً) ───────────────────────────
    _drawGrid();

    // ── ديكور الحيط الثابت ──────────────────────────────────
    _drawWallDecor();
  }

  void _drawGrid() {
    final t  = RoomConfig.currentTileSize;
    final p  = Paint()..color = RoomConfig.gridLineColor..style = PaintingStyle.stroke..strokeWidth = .5;

    for (int col = 0; col <= RoomConfig.gridCols; col++) {
      add(_LineComponent(
        from    : Vector2(col * t, 0),
        to      : Vector2(col * t, RoomConfig.roomHeight),
        paint   : p,
        priority: -8,
      ));
    }
    for (int row = 0; row <= RoomConfig.gridRows; row++) {
      add(_LineComponent(
        from    : Vector2(0, row * t),
        to      : Vector2(RoomConfig.roomWidth, row * t),
        paint   : p,
        priority: -8,
      ));
    }
  }

  /// ديكور ثابت على الحيط — نافذة + لوحة
  void _drawWallDecor() {
    final t = RoomConfig.currentTileSize;

    // نافذة — 3 خلايا من اليمين
    final winX = 2 * t;
    final winY = 0.5 * t;
    final winW = 3 * t;
    final winH = 2.8 * t;

    add(RectangleComponent(
      position: Vector2(winX, winY),
      size    : Vector2(winW, winH),
      paint   : Paint()..color = const Color(0xFF0D1C33),
    )..priority = -7);
    // إطار النافذة
    add(RectangleComponent(
      position: Vector2(winX, winY),
      size    : Vector2(winW, winH),
      paint   : Paint()
        ..color = const Color(0xFF534AB7).withOpacity(.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    )..priority = -6);
    // ضوء من النافذة على الأرضية
    add(RectangleComponent(
      position: Vector2(winX - t * .3, RoomConfig.floorStartY),
      size    : Vector2(winW + t * .6, t * 2),
      paint   : Paint()..color = const Color(0xFF534AB7).withOpacity(.04),
    )..priority = -7);

    // لوحة على الحيط
    final pX = (RoomConfig.gridCols - 5) * t;
    add(RectangleComponent(
      position: Vector2(pX, t * .4),
      size    : Vector2(3 * t, 2 * t),
      paint   : Paint()..color = const Color(0xFF1E1B50),
    )..priority = -7);
    add(RectangleComponent(
      position: Vector2(pX, t * .4),
      size    : Vector2(3 * t, 2 * t),
      paint   : Paint()
        ..color = const Color(0xFF7F77DD).withOpacity(.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    )..priority = -6);
  }

  // ── إضافة الأثاث ─────────────────────────────────────────
  void _spawnFurniture(List<Map<String, dynamic>>? layout) {
    if (layout != null && layout.isNotEmpty) {
      for (final item in layout) {
        _addItem(
          id  : item['id']?.toString()   ?? _uid(),
          type: item['type']?.toString() ?? 'bed',
          gx  : (item['x'] as num?)?.toInt() ?? 2,
          gy  : (item['y'] as num?)?.toInt() ?? RoomConfig.wallRows,
        );
      }
    } else {
      // أثاث افتراضي عند أول دخول
      _addItem(id: _uid(), type: 'bed',   gx: 1,  gy: RoomConfig.wallRows);
      _addItem(id: _uid(), type: 'desk',  gx: 7,  gy: RoomConfig.wallRows);
      _addItem(id: _uid(), type: 'plant', gx: 14, gy: RoomConfig.wallRows);
      _addItem(id: _uid(), type: 'chair', gx: 6,  gy: RoomConfig.wallRows + 2);
    }
  }

  void _addItem({required String id, required String type, required int gx, required int gy}) {
    add(FurnitureItem(id: id, furnitureType: type, gridX: gx, gridY: gy));
  }

  /// إضافة قطعة أثاث جديدة من المتجر
  void addFurniture(String type) {
    final def = RoomConfig.furnitureDefs[type];
    if (def == null) return;
    // ابحث عن أول مكان فاضي في الأرضية
    for (int gx = 0; gx <= RoomConfig.gridCols - def.gridW; gx++) {
      final gy = RoomConfig.wallRows;
      if (canPlace(excludeId: '', gridX: gx, gridY: gy, gridW: def.gridW, gridH: def.gridH)) {
        _addItem(id: _uid(), type: type, gx: gx, gy: gy);
        return;
      }
    }
  }

  // ── كشف التصادم ──────────────────────────────────────────
  bool canPlace({
    required String excludeId,
    required int    gridX,
    required int    gridY,
    required int    gridW,
    required int    gridH,
  }) {
    // حدود الغرفة
    if (gridX < 0 || gridX + gridW > RoomConfig.gridCols) return false;
    if (gridY < RoomConfig.wallRows || gridY + gridH > RoomConfig.gridRows) return false;

    for (final item in children.whereType<FurnitureItem>()) {
      if (item.id == excludeId) continue;
      final def = RoomConfig.furnitureDefs[item.furnitureType];
      if (def == null) continue;

      final ox = item.gridX; final ow = def.gridW;
      final oy = item.gridY; final oh = def.gridH;

      final overlapX = gridX < ox + ow && gridX + gridW > ox;
      final overlapY = gridY < oy + oh && gridY + gridH > oy;
      if (overlapX && overlapY) return false;
    }
    return true;
  }

  // ── حفظ ───────────────────────────────────────────────────
  List<Map<String, dynamic>> getLayout() =>
      children.whereType<FurnitureItem>().map((f) => f.toJson()).toList();

  // ── مساعد ─────────────────────────────────────────────────
  static int _counter = 0;
  static String _uid() => 'item_${++_counter}_${DateTime.now().millisecondsSinceEpoch}';
}

// ── مساعد رسم الخط ───────────────────────────────────────────
class _LineComponent extends Component {
  final Vector2 from;
  final Vector2 to;
  final Paint   paint;

  _LineComponent({required this.from, required this.to, required this.paint, int priority = 0})
      : super(priority: priority);

  @override
  void render(Canvas canvas) {
    canvas.drawLine(from.toOffset(), to.toOffset(), paint);
  }
}