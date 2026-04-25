import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'create_community_screen.dart';
import 'community_detail_screen.dart'; // صفحة التفاصيل الجديدة
import 'my_home_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  final supabase = SupabaseConfig.client;
  List<Map<String, dynamic>> _communities = [];
  bool _isLoading = true;
  String? _error;
  int _walletBalance = 15;

  // متغير لتخزين القناة
  RealtimeChannel? _communityChannel;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    );

    _fetchUserData();
    _fetchCommunities();
    _subscribeToCommunities();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('profiles')
            .select('wallet_balance')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _walletBalance = response['wallet_balance'] ?? 15;
          });
        }
      }
    } catch (e) {
      print("خطأ في جلب بيانات المستخدم: $e");
    }
  }

  Future<void> _fetchCommunities() async {
    try {
      final response = await supabase
          .from('communities')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _communities = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToCommunities() {
    _communityChannel = supabase.channel('communities_changes');

    _communityChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'communities',
      callback: (payload) {
        _fetchCommunities();
      },
    ).subscribe();
  }

  Future<void> _deleteCommunity(String id) async {
    try {
      await supabase.from('communities').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المجتمع'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  void _navigateToPage(String pageName) {
    _toggleDrawer();
    Widget targetPage;

    switch (pageName) {
      case 'home':
        return;
      case 'my_home':
        targetPage = const MyHomeScreen();
        break;
      case 'shop':
        targetPage = const ShopScreen();
        break;
      case 'logout':
        supabase.auth.signOut();
        return;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  // دالة جديدة لفتح تفاصيل المجتمع
  void _openCommunityDetail(Map<String, dynamic> community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailScreen(community: community),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildBalanceBadge(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF7F77DD), size: 30),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateCommunityScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(_isDrawerOpen ? Icons.close : Icons.menu, color: const Color(0xFFE4E0FF)),
            onPressed: _toggleDrawer,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(),

          if (_isDrawerOpen) ...[
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(_drawerAnimation),
                child: Container(
                  width: 280,
                  color: const Color(0xFF1A1740),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: const Color(0xFF534AB7),
                                child: const Icon(Icons.person, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      supabase.auth.currentUser?.email?.split('@').first ?? 'مستخدم',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'Level 1 Beginner',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 10),
                        _buildDrawerItem(Icons.home, 'الرئيسية', 'home'),
                        _buildDrawerItem(Icons.home_work, 'منزلي', 'my_home'),
                        _buildDrawerItem(Icons.shopping_bag, 'المتجر', 'shop'),
                        const Spacer(),
                        _buildDrawerItem(Icons.logout, 'تسجيل خروج', 'logout', isLogout: true),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFBA7517),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF9F27)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFBA7517).withOpacity(0.4), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text('$_walletBalance', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const Text(' Coins', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD)));
    }

    if (_error != null) {
      return Center(child: Text('خطأ: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_communities.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _communities.length,
      itemBuilder: (context, index) {
        final community = _communities[index];
        return GestureDetector(
          onTap: () => _openCommunityDetail(community),
          child: _buildCommunityCard(community),
        );
      },
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> community) {
    final String colorHex = community['theme_color'] ?? '#534AB7';
    final Color themeColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
    final int members = community['member_count'] ?? 0;
    final currentUser = supabase.auth.currentUser;
    final isOwner = currentUser?.id == community['owner_id'];

    return Container(
      key: ValueKey(community['id']),
      decoration: BoxDecoration(
        color: const Color(0xFF12102B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [themeColor.withOpacity(0.6), const Color(0xFF12102B)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  _getTypeIcon(community['type']),
                  size: 40,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community['name'] ?? 'بدون اسم',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$members عضو', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: () => _deleteCommunity(community['id'].toString()),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('لا توجد مجتمعات حالياً', style: TextStyle(color: Colors.white54, fontSize: 18)),
          const Text('كن أول من يصنع عالماً جديداً!', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String pageName, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? const Color(0xFFE74C3C) : const Color(0xFF7F77DD)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: () => _navigateToPage(pageName),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    if (_communityChannel != null) {
      supabase.removeChannel(_communityChannel!);
    }
    super.dispose();
  }
}