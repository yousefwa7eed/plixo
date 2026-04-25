import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../config/supabase_config.dart';
import 'room/room_game.dart';
import 'room/room_config.dart';

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen>
    with SingleTickerProviderStateMixin {

  // ── الثوابت ──────────────────────────────────────────────
  static const _purple     = Color(0xFF534AB7);
  static const _purpleL    = Color(0xFF7F77DD);
  static const _purpleD    = Color(0xFF3C3489);
  static const _teal       = Color(0xFF1D9E75);
  static const _gold       = Color(0xFFEF9F27);
  static const _bg         = Color(0xFF0D0B1A);
  static const _bgCard     = Color(0xFF12102B);
  static const _bgCard2    = Color(0xFF1A1740);
  static const _txMain     = Color(0xFFE4E0FF);
  static const _txSub      = Color(0xFFA09CC8);
  static const _txDim      = Color(0xFF6B668F);
  static const _border     = Color(0xFF2A2460);

  // ── الحالة ───────────────────────────────────────────────
  final _supabase      = SupabaseConfig.client;
  RoomGame?            _game;
  bool                 _loading    = true;
  bool                 _saving     = false;
  bool                 _editMode   = false;
  bool                 _shopOpen   = false;
  int                  _coins      = 50; // سيُجلب من Supabase
  String?              _error;

  late AnimationController _shopAnim;
  late Animation<double>   _shopSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _shopAnim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _shopSlide = CurvedAnimation(parent: _shopAnim, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _shopAnim.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // ── تحميل البيانات ───────────────────────────────────────
  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      final res = await _supabase
          .from('user_homes')
          .select('furniture_layout, coins')
          .eq('user_id', user.id)
          .maybeSingle();

      List<Map<String, dynamic>>? layout;
      if (res != null) {
        final raw = res['furniture_layout'];
        if (raw is List) {
          layout = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        _coins = (res['coins'] as num?)?.toInt() ?? 50;
      }

      setState(() {
        _game    = RoomGame(savedLayout: layout);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _game    = RoomGame(savedLayout: null); // افتراضي
        _loading = false;
        _error   = e.toString();
      });
    }
  }

  // ── حفظ ───────────────────────────────────────────────────
  Future<void> _save() async {
    if (_game == null || _saving) return;
    setState(() => _saving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('user_homes').upsert(
        {
          'user_id'          : user.id,
          'furniture_layout' : _game!.getLayout(),
          'updated_at'       : DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      if (!mounted) return;
      _showSnack('تم حفظ الغرفة ✅', _teal);
      setState(() => _editMode = false);
    } catch (e) {
      _showSnack('فشل الحفظ: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content         : Text(msg, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
      backgroundColor : color,
      behavior        : SnackBarBehavior.floating,
      shape           : const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin          : const EdgeInsets.all(12),
      duration        : const Duration(seconds: 2),
    ));
  }

  // ── شراء أثاث ─────────────────────────────────────────────
  void _buyFurniture(String type, int price) {
    if (_game == null) return;
    if (_coins < price) {
      _showSnack('مش عندك كوينز كافية 😅', Colors.orangeAccent);
      return;
    }
    
    // تحقق من إمكانية الإضافة (في مكان فاضي)
    final def = RoomConfig.furnitureDefs[type];
    if (def == null) return;
    
    // ابحث عن أول مكان فاضي
    bool placed = false;
    for (int gx = 0; gx <= RoomConfig.gridCols - def.gridW && !placed; gx++) {
      for (int gy = RoomConfig.wallRows; gy <= RoomConfig.gridRows - def.gridH && !placed; gy++) {
        if (_game!.canPlace(excludeId: '', gridX: gx, gridY: gy, gridW: def.gridW, gridH: def.gridH)) {
          _game!.addFurnitureAt(type, gx, gy);
          placed = true;
        }
      }
    }
    
    if (!placed) {
      _showSnack('مافيش مكان كافي في الغرفة 😕', Colors.redAccent);
      return;
    }
    
    setState(() => _coins -= price);
    _showSnack('تمت الإضافة إلى غرفتك 🎉', _purple);
  }

  // ── Toggle Edit Mode ──────────────────────────────────────
  void _toggleEdit() {
    setState(() {
      _editMode  = !_editMode;
      if (!_editMode) {
        _shopOpen = false;
        _shopAnim.reverse();
      }
    });
  }

  void _toggleShop() {
    if (!_editMode) return;
    setState(() => _shopOpen = !_shopOpen);
    if (_shopOpen) {
      _shopAnim.forward();
    } else {
      _shopAnim.reverse();
    }
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isLandscape),
      body: _loading
          ? _buildLoader()
          : _error != null && _game == null
          ? _buildError()
          : _buildBody(isLandscape),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool landscape) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation      : 0,
      flexibleSpace  : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end  : Alignment.bottomCenter,
            colors: [Color(0xCC0D0B1A), Colors.transparent],
          ),
        ),
      ),
      leading: IconButton(
        icon    : const Icon(Icons.arrow_back_ios_new, color: _txSub, size: 18),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          const Text('غرفتي',
              style: TextStyle(color: _txMain, fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo', fontSize: 18)),
          if (_editMode) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _purple.withOpacity(.2),
                  border: Border.all(color: _purple.withOpacity(.5))),
              child: const Text('وضع التعديل',
                  style: TextStyle(color: _purpleL, fontSize: 10,
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      actions: [
        // عداد الكوينز
        Container(
          margin : const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color : _bgCard2,
            border: Border.all(color: _gold.withOpacity(.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$_coins',
                  style: const TextStyle(color: _gold, fontWeight: FontWeight.w900,
                      fontSize: 13, fontFamily: 'Cairo')),
            ],
          ),
        ),

        // زر التعديل
        IconButton(
          icon   : Icon(_editMode ? Icons.close_rounded : Icons.edit_rounded,
              color: _editMode ? Colors.redAccent : _purpleL),
          onPressed: _toggleEdit,
          tooltip  : _editMode ? 'إلغاء' : 'تعديل الغرفة',
        ),

        // زر الحفظ
        if (_editMode)
          _saving
              ? const Padding(
            padding: EdgeInsets.all(12),
            child  : SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _teal)),
          )
              : IconButton(
            icon   : const Icon(Icons.check_rounded, color: _teal),
            onPressed: _save,
            tooltip  : 'حفظ',
          ),

        const SizedBox(width: 4),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────
  Widget _buildBody(bool landscape) {
    return Stack(
      children: [
        // ── الغرفة ─────────────────────────────────────────
        _buildRoomArea(),

        // ── شريط الأدوات السفلي (وضع التعديل) ────────────
        if (_editMode) _buildToolbar(landscape),

        // ── متجر الأثاث ────────────────────────────────────
        if (_editMode) _buildShopPanel(landscape),
      ],
    );
  }

  Widget _buildRoomArea() {
    return Positioned.fill(
      child: LayoutBuilder(builder: (ctx, box) {
        // أعد حساب الـ tile size عشان الـ game يعرف
        RoomConfig.recalculate(
          Size(box.maxWidth, box.maxHeight),
          padding: const EdgeInsets.only(bottom: 80),
        );
        return _game == null
            ? const SizedBox()
            : GameWidget(
          game       : _game!,
          loadingBuilder: (_) => _buildLoader(),
        );
      }),
    );
  }

  // ── شريط الأدوات ─────────────────────────────────────────
  Widget _buildToolbar(bool landscape) {
    return Positioned(
      bottom : 0,
      left   : 0,
      right  : 0,
      child  : Container(
        height    : 72,
        decoration: BoxDecoration(
          color : _bgCard.withOpacity(.97),
          border: const Border(top: BorderSide(color: _border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _toolBtn(icon: '🛋️', label: 'أضف أثاث', onTap: _toggleShop, active: _shopOpen),
            _toolBtn(icon: '🎨', label: 'الألوان',   onTap: () => _showSnack('قريباً…', _purple)),
            _toolBtn(icon: '💡', label: 'الإضاءة',   onTap: () => _showSnack('قريباً…', _purple)),
            _toolBtn(icon: '🗑️', label: 'مسح',       onTap: () => _showSnack('قريباً…', Colors.redAccent)),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn({required String icon, required String label, required VoidCallback onTap, bool active = false}) {
    return GestureDetector(
      onTap  : onTap,
      child  : Container(
        padding : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: active
            ? BoxDecoration(color: _purple.withOpacity(.15),
            border: Border.all(color: _purple.withOpacity(.4)))
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color     : active ? _purpleL : _txDim,
                    fontSize  : 10,
                    fontFamily: 'Cairo',
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  // ── متجر الأثاث (يتسلل من الأسفل) ───────────────────────
  Widget _buildShopPanel(bool landscape) {
    final panelH = landscape ? 200.0 : 260.0;

    return Positioned(
      bottom : 72,
      left   : 0,
      right  : 0,
      child  : SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end  : Offset.zero,
        ).animate(_shopSlide),
        child: Container(
          height    : panelH,
          decoration: const BoxDecoration(
            color : _bgCard,
            border: Border(top: BorderSide(color: _border, width: 1.5)),
          ),
          child: Column(
            children: [
              // هيدر المتجر
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    const Text('🛋️ المتجر',
                        style: TextStyle(color: _txMain, fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo', fontSize: 15)),
                    const Spacer(),
                    Row(children: [
                      const Text('🪙 ', style: TextStyle(fontSize: 13)),
                      Text('$_coins كوينز',
                          style: const TextStyle(color: _gold, fontFamily: 'Cairo',
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
              ),
              const Divider(color: _border, height: 1),
              // قائمة الأثاث - قابلة للتمرير بشكل صحيح
              Expanded(
                child: ClipRect(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding        : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount      : RoomConfig.furnitureDefs.length,
                    itemBuilder: (ctx, index) {
                      final entry = RoomConfig.furnitureDefs.entries.elementAt(index);
                      return _shopItem(type: entry.key, def: entry.value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shopItem({required String type, required FurnitureDef def}) {
    final canAfford = _coins >= def.price;
    return GestureDetector(
      onTap: canAfford ? () => _buyFurniture(type, def.price) : null,
      child: Container(
        width  : 90,
        margin : const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color : _bgCard2,
          border: Border.all(
              color: canAfford ? _border : _border.withOpacity(.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(def.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(def.label,
                style: TextStyle(
                    color     : canAfford ? _txMain : _txDim,
                    fontFamily: 'Cairo',
                    fontSize  : 11,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: def.price == 0
                    ? _teal.withOpacity(.15)
                    : canAfford
                    ? _gold.withOpacity(.12)
                    : Colors.red.withOpacity(.1),
              ),
              child: Text(
                def.price == 0 ? 'مجاني' : '🪙 ${def.price}',
                style: TextStyle(
                    color     : def.price == 0 ? _teal : canAfford ? _gold : Colors.redAccent,
                    fontFamily: 'Cairo',
                    fontSize  : 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────
  Widget _buildLoader() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _purple, strokeWidth: 2),
        SizedBox(height: 16),
        Text('جاري تحميل غرفتك…',
            style: TextStyle(color: _txSub, fontFamily: 'Cairo', fontSize: 13)),
      ],
    ),
  );

  // ── Error ─────────────────────────────────────────────────
  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child  : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('حصل خطأ في التحميل',
              style: TextStyle(color: _txMain, fontFamily: 'Cairo',
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_error ?? '', textAlign: TextAlign.center,
              style: const TextStyle(color: _txDim, fontFamily: 'Cairo', fontSize: 12)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color : _purple.withOpacity(.15),
                border: Border.all(color: _purple.withOpacity(.5)),
              ),
              child: const Text('حاول مجدداً',
                  style: TextStyle(color: _purpleL, fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ),
  );
}