import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

class MembersManagementScreen extends StatefulWidget {
  final Map<String, dynamic> community;

  const MembersManagementScreen({super.key, required this.community});

  @override
  State<MembersManagementScreen> createState() => _MembersManagementScreenState();
}

class _MembersManagementScreenState extends State<MembersManagementScreen> {
  final supabase = SupabaseConfig.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> pendingRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    // محاكاة بيانات أعضاء حالياً
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        members = [
          {'id': '1', 'username': 'أحمد محمد', 'role': 'admin', 'avatar': 'A'},
          {'id': '2', 'username': 'سارة علي', 'role': 'member', 'avatar': 'S'},
          {'id': '3', 'username': 'خالد يوسف', 'role': 'member', 'avatar': 'K'},
        ];
        if (!(widget.community['is_public'] ?? true)) {
          pendingRequests = [
            {'id': '4', 'username': 'طالب انضمام 1', 'avatar': 'T'},
            {'id': '5', 'username': 'طالب انضمام 2', 'avatar': 'T'},
          ];
        }
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String colorHex = widget.community['theme_color'] ?? '#534AB7';
    final Color themeColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    final bool isPrivate = !(widget.community['is_public'] ?? true);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('إدارة الأعضاء', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD)))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو اليوزر...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF12102B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() {}),
            ),
          ),

          if (isPrivate && pendingRequests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(children: [
                const Text('طلبات الانضمام', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: Text('${pendingRequests.length}', style: const TextStyle(color: Colors.white, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: pendingRequests.length,
                itemBuilder: (ctx, i) => _buildRequestTile(pendingRequests[i], themeColor),
              ),
            ),
            const Divider(color: Colors.white10),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('قائمة الأعضاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: members.where((m) => m['username'].contains(_searchController.text)).length,
              itemBuilder: (ctx, i) {
                final member = members.where((m) => m['username'].contains(_searchController.text)).toList()[i];
                return _buildMemberTile(member, themeColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> req, Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF12102B), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.orange, child: Text(req['avatar'], style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 12),
          Expanded(child: Text(req['username'], style: const TextStyle(color: Colors.white))),
          IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () {}),
          IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, Color themeColor) {
    final bool isAdmin = member['role'] == 'admin';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF12102B), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: isAdmin ? themeColor : const Color(0xFF534AB7), child: Text(member['avatar'], style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(member['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), if (isAdmin) const Text('مشرف', style: TextStyle(color: Colors.green, fontSize: 10))])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'ban') ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حظر المستخدم')));
              if (val == 'promote') ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعيينه مشرفاً')));
            },
            itemBuilder: (ctx) => [
              if (!isAdmin) const PopupMenuItem(value: 'promote', child: Text('تعيين كمشرف')),
              const PopupMenuItem(value: 'ban', child: Text('حظر وطرد', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }
}