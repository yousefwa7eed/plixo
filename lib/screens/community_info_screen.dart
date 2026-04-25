import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class CommunityInfoScreen extends StatefulWidget {
  final Map<String, dynamic> community;

  const CommunityInfoScreen({super.key, required this.community});

  @override
  State<CommunityInfoScreen> createState() => _CommunityInfoScreenState();
}

class _CommunityInfoScreenState extends State<CommunityInfoScreen> {
  final supabase = SupabaseConfig.client;
  Map<String, dynamic>? ownerProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOwnerDetails();
  }

  Future<void> _fetchOwnerDetails() async {
    try {
      final ownerId = widget.community['owner_id'];
      final response = await supabase
          .from('profiles')
          .select('username, created_at')
          .eq('id', ownerId)
          .single();

      if (mounted) {
        setState(() {
          ownerProfile = response;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String colorHex = widget.community['theme_color'] ?? '#534AB7';
    final Color themeColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    final DateTime createdAt = DateTime.parse(widget.community['created_at']);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('معلومات المجتمع', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              icon: Icons.title,
              title: 'اسم المجتمع',
              value: widget.community['name'] ?? 'غير معروف',
              color: themeColor,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.person,
              title: 'تأسس بواسطة',
              value: ownerProfile?['username'] ?? widget.community['owner_id'].toString().substring(0, 8) + '...',
              subtitle: 'معرف المالك: ${widget.community['owner_id']}',
              color: themeColor,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'تاريخ الإنشاء',
              value: '${createdAt.day}/${createdAt.month}/${createdAt.year}',
              subtitle: createdAt.toString().substring(11, 16),
              color: themeColor,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.visibility,
              title: 'نوع الخصوصية',
              value: widget.community['is_public'] ? 'عام (Public)' : 'خاص (Private)',
              color: widget.community['is_public'] ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.people,
              title: 'السعة القصوى',
              value: '${widget.community['member_count']} / ${widget.community['max_capacity']} عضو',
              color: themeColor,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF12102B), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('وصف المجتمع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(widget.community['description'] ?? 'لا يوجد وصف متاح.', style: const TextStyle(color: Colors.white70, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value, String? subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF12102B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                if (subtitle != null) const SizedBox(height: 4),
                if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}