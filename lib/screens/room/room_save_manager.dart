import '../config/supabase_config.dart';

/// مدير حفظ وتحميل بيانات الغرفة والكوينز
class RoomSaveManager {
  static final _supabase = SupabaseConfig.client;
  
  /// حفظ تخطيط الغرفة
  static Future<bool> saveLayout(List<Map<String, dynamic>> layout) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      await _supabase.from('user_homes').upsert(
        {
          'user_id': user.id,
          'furniture_layout': layout,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
      return true;
    } catch (e) {
      print('Error saving layout: $e');
      return false;
    }
  }
  
  /// تحديث عدد الكوينز
  static Future<bool> updateCoins(int coins) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      await _supabase.from('user_homes').upsert(
        {
          'user_id': user.id,
          'coins': coins,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
      return true;
    } catch (e) {
      print('Error updating coins: $e');
      return false;
    }
  }
  
  /// تحميل البيانات كاملة
  static Future<Map<String, dynamic>?> loadData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      
      final res = await _supabase
          .from('user_homes')
          .select('furniture_layout, coins')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (res == null) return null;
      
      List<Map<String, dynamic>>? layout;
      final raw = res['furniture_layout'];
      if (raw is List) {
        layout = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      
      return {
        'layout': layout,
        'coins': (res['coins'] as num?)?.toInt() ?? 50,
      };
    } catch (e) {
      print('Error loading data: $e');
      return null;
    }
  }
}
