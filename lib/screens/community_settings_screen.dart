import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'edit_community_screen.dart';
import 'community_info_screen.dart';
import 'members_management_screen.dart';
import 'transfer_ownership_screen.dart';

class CommunitySettingsScreen extends StatefulWidget {
  final Map<String, dynamic> community;
  final bool isOwner;
  final bool isJoined;

  const CommunitySettingsScreen({
    super.key,
    required this.community,
    required this.isOwner,
    required this.isJoined,
  });

  @override
  State<CommunitySettingsScreen> createState() => _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  final supabase = SupabaseConfig.client;
  bool _notificationsEnabled = true;
  bool _isMuted = false;
  bool _isLoading = false;

  // --- وظائف العضو/الزائر ---

  Future<void> _toggleJoin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // محاكاة عملية الانضمام/المغادرة
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isJoined ? 'تمت مغادرة المجتمع' : 'تم الانضمام بنجاح!'),
          backgroundColor: widget.isJoined ? Colors.orange : Colors.green,
        ),
      );

      // إرجاع نتيجة للشاشة السابقة لتحديث الحالة
      if (mounted) Navigator.pop(context, !widget.isJoined);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reportCommunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1740),
        title: const Text('الإبلاغ عن مجتمع', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من رغبتك في الإبلاغ عن هذا المجتمع؟ سيتم مراجعة البلاغ من قبل الإدارة.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إبلاغ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال البلاغ للإدارة بنجاح. شكراً لمساهمتك.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  // --- وظائف المالك ---

  Future<void> _deleteCommunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1740),
        title: const Text('حذف المجتمع نهائياً', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('تحذير: هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع الغرف، الرسائل، والأعضاء نهائياً.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، احذفه', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await supabase.from('communities').delete().eq('id', widget.community['id']);
        if (!mounted) return;

        Navigator.pop(context); // إغلاق الإعدادات
        Navigator.pop(context); // إغلاق التفاصيل
        // العودة للشاشة الرئيسية
        Navigator.popUntil(context, (route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المجتمع بنجاح'), backgroundColor: Colors.red),
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الحذف: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditCommunityScreen(community: widget.community)),
    );
  }

  void _navigateToMembersManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MembersManagementScreen(community: widget.community)),
    );
  }

  void _navigateToTransferOwnership() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TransferOwnershipScreen(community: widget.community)),
    );
  }

  void _navigateToCommunityInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommunityInfoScreen(community: widget.community)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String colorHex = widget.community['theme_color'] ?? '#534AB7';
    final Color themeColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إعدادات المجتمع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD)))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم عام (للجميع)
          _buildSectionHeader('عام', themeColor),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'معلومات المجتمع',
            subtitle: 'تاريخ الإنشاء، المؤسس، والإحصائيات',
            onTap: _navigateToCommunityInfo,
          ),

          const Divider(height: 30, color: Colors.white10),

          // قسم العضوية (للزائر/العضو فقط)
          if (!widget.isOwner) ...[
            _buildSectionHeader('العضوية', themeColor),
            _buildSwitchTile(
              icon: Icons.notifications,
              title: 'الإشعارات',
              subtitle: 'استلام تنبيهات عند النشاط الجديد',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
              activeColor: themeColor,
            ),
            _buildSwitchTile(
              icon: Icons.volume_off,
              title: 'كتم الصوت',
              subtitle: 'إيقاف أصوات التنبيهات',
              value: _isMuted,
              onChanged: (val) => setState(() => _isMuted = val),
              activeColor: themeColor,
            ),
            const SizedBox(height: 10),
            _buildActionTile(
              icon: widget.isJoined ? Icons.exit_to_app : Icons.login,
              title: widget.isJoined ? 'مغادرة المجتمع' : 'انضمام للمجتمع',
              color: widget.isJoined ? Colors.orange : themeColor,
              onTap: _toggleJoin,
            ),
            const SizedBox(height: 10),
            _buildActionTile(
              icon: Icons.flag,
              title: 'الإبلاغ عن مشكلة',
              color: Colors.redAccent,
              onTap: _reportCommunity,
            ),
          ],

          // قسم الإدارة (للمالك فقط)
          if (widget.isOwner) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('إدارة المجتمع', themeColor),
            _buildActionTile(
              icon: Icons.edit,
              title: 'تعديل المعلومات',
              subtitle: 'تغيير الاسم، الوصف، واللون',
              color: themeColor,
              onTap: _navigateToEdit,
            ),
            _buildActionTile(
              icon: Icons.people_alt,
              title: 'إدارة الأعضاء',
              subtitle: 'قبول الطلبات، حظر المستخدمين، وتعيين مشرفين',
              color: themeColor,
              onTap: _navigateToMembersManagement,
            ),
            _buildActionTile(
              icon: Icons.shield_outlined,
              title: 'نقل الملكية',
              subtitle: 'تعيين مالك جديد للمجتمع',
              color: Colors.blueAccent,
              onTap: _navigateToTransferOwnership,
            ),

            const SizedBox(height: 30),
            _buildSectionHeader('منطقة الخطر', Colors.red),
            _buildActionTile(
              icon: Icons.delete_forever,
              title: 'حذف المجتمع نهائياً',
              subtitle: 'لا يمكن التراجع عن هذا الإجراء',
              color: Colors.red,
              textColor: Colors.red,
              onTap: _deleteCommunity,
            ),
          ],

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Plixo Platform v1.0.0',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets المساعدة ---

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: color, margin: const EdgeInsets.only(left: 8)),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12102B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF7F77DD)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12102B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF7F77DD)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: textColor ?? Colors.white, fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}