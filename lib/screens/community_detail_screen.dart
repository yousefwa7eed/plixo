import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'edit_community_screen.dart';
import 'community_settings_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final supabase = SupabaseConfig.client;
  bool _isJoined = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  void _checkOwnership() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _isOwner = (user.id == widget.community['owner_id']);
        _isJoined = _isOwner; // المالك منضم تلقائياً
      });
    }
  }

  Future<void> _toggleJoin() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // محاكاة منطق الانضمام (سيتم ربطه بقاعدة البيانات لاحقاً)
    setState(() {
      _isJoined = !_isJoined;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isJoined ? 'تم الانضمام إلى المجتمع بنجاح! 🎉' : 'تمت مغادرة المجتمع'),
        backgroundColor: _isJoined ? Colors.green : Colors.orange,
      ),
    );
  }

  // دالة لفتح صفحة الإعدادات ومعالجة النتائج العائدة منها
  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunitySettingsScreen(
          community: widget.community, // نمرر البيانات الأصلية
          isOwner: _isOwner,
          isJoined: _isJoined,
        ),
      ),
    );

    // إذا عاد المستخدم بنتيجة 'updated' أو 'left' أو 'deleted'، نقوم بتحديث الواجهة
    if (result != null && mounted) {
      if (result == 'deleted') {
        // إذا تم الحذف، نعود للشاشة الرئيسية ونحذف المجتمع من القائمة هناك
        Navigator.popUntil(context, (route) => route.isFirst);
      } else if (result == 'left') {
        setState(() {
          _isJoined = false;
        });
      } else if (result == 'updated') {
        // لا حاجة لفعل شيء هنا لأن StreamBuilder سيقوم بتحديث البيانات تلقائياً
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الإعدادات'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String communityId = widget.community['id'];

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('communities')
          .stream(primaryKey: ['id'])
          .eq('id', communityId)
          .limit(1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0B1A),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD))),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0B1A),
            body: Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            backgroundColor: const Color(0xFF0D0B1A),
            body: Center(child: Text('المجتمع غير موجود', style: TextStyle(color: Colors.white))),
          );
        }

        final community = snapshot.data!.first;
        final String colorHex = community['theme_color'] ?? '#534AB7';
        final Color themeColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
        final int memberCount = community['member_count'] ?? 0;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0B1A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              community['name'] ?? 'تفاصيل المجتمع',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // زر الإعدادات يظهر للجميع ولكن بمحتوى مختلف حسب الصلاحية
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Color(0xFF7F77DD)),
                onPressed: _openSettings,
                tooltip: 'إعدادات المجتمع',
              ),
              // زر التعديل السريع يظهر للمالك فقط في الشريط العلوي (اختياري)
              if (_isOwner)
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFFE74C3C)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCommunityScreen(community: community),
                      ),
                    ).then((result) {
                      if (result == 'saved' && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تعديل المجتمع'), backgroundColor: Colors.green),
                        );
                      }
                    });
                  },
                  tooltip: 'تعديل سريع',
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        themeColor.withOpacity(0.8),
                        themeColor.withOpacity(0.2),
                        const Color(0xFF0D0B1A),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getTypeIcon(community['type']),
                      size: 80,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              community['name'] ?? 'بدون اسم',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: themeColor),
                            ),
                            child: Text(
                              community['type'] ?? 'Social',
                              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            community['is_public'] ?? true ? Icons.public : Icons.lock,
                            color: community['is_public'] ?? true ? Colors.green : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            community['is_public'] ?? true ? 'مجتمع عام' : 'مجتمع خاص',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'عن المجتمع',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        community['description'] ?? 'لا يوجد وصف متاح.',
                        style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(Icons.people, '$memberCount', 'عضو'),
                          _buildStatCard(Icons.wifi, (community['is_public'] ?? true) ? 'نشط' : 'خاص', 'الحالة'),
                          _buildStatCard(Icons.calendar_today, 'اليوم', 'تاريخ الإنشاء'),
                        ],
                      ),

                      const SizedBox(height: 40),

                      if (_isOwner)
                        _buildOwnerPanel(themeColor)
                      else
                        _buildJoinButton(themeColor),

                      const SizedBox(height: 20),

                      const Text(
                        'أعضاء نشطون',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildMembersList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12102B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7F77DD), size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOwnerPanel(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة تحكم المالك',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('دعوة الأعضاء قريباً')),
                    );
                  },
                  icon: const Icon(Icons.person_add, color: Colors.black),
                  label: const Text('دعوة أعضاء', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('عرض الإحصائيات قريباً')),
                    );
                  },
                  icon: const Icon(Icons.analytics, color: Colors.black),
                  label: const Text('إحصائيات', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(Color themeColor) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isJoined ? null : _toggleJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isJoined ? Colors.grey : themeColor,
          disabledBackgroundColor: Colors.grey.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _isJoined ? 'أنت عضو في هذا المجتمع' : 'انضم إلى المجتمع الآن 🚀',
          style: TextStyle(
            color: _isJoined ? Colors.white70 : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: index.isEven ? const Color(0xFF534AB7) : const Color(0xFF1D9E75),
            child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
          ),
          title: Text('مستخدم تجريبي ${index + 1}', style: const TextStyle(color: Colors.white)),
          subtitle: const Text('متصل الآن', style: TextStyle(color: Colors.green, fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.message, color: Colors.grey),
            onPressed: () {},
          ),
        );
      },
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'Social': return Icons.people;
      case 'Study': return Icons.school;
      case 'Gaming': return Icons.sports_esports;
      default: return Icons.group;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}