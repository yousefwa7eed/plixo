import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class TransferOwnershipScreen extends StatefulWidget {
  final Map<String, dynamic> community;

  const TransferOwnershipScreen({super.key, required this.community});

  @override
  State<TransferOwnershipScreen> createState() => _TransferOwnershipScreenState();
}

class _TransferOwnershipScreenState extends State<TransferOwnershipScreen> {
  final supabase = SupabaseConfig.client;
  final _currentOwnerController = TextEditingController();
  final _newOwnerController = TextEditingController();
  bool isLoading = false;
  String? currentUsername;

  @override
  void initState() {
    super.initState();
    _currentOwnerController.text = widget.community['owner_id'];
    _loadCurrentOwnerName();
  }

  Future<void> _loadCurrentOwnerName() async {
    // يمكن جلب اسم المالك الحالي هنا وعرضه بدلاً من ID
    setState(() => currentUsername = "المالك الحالي (ID: ${widget.community['owner_id'].toString().substring(0,8)}...)");
  }

  Future<void> _transferOwnership() async {
    if (_newOwnerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال معرف المالك الجديد'), backgroundColor: Colors.red));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1740),
        title: const Text('تأكيد نقل الملكية', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من نقل ملكية "${widget.community['name']}" إلى المستخدم: ${_newOwnerController.text}؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('نعم، انقل الملكية')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        // تحديث قاعدة البيانات
        await supabase.from('communities').update({'owner_id': _newOwnerController.text}).eq('id', widget.community['id']);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نقل الملكية بنجاح!'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل النقل: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String colorHex = widget.community['theme_color'] ?? '#534AB7';
    final Color themeColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1A),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('نقل الملكية', style: TextStyle(color: Colors.white)), leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD)))
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('نقل ملكية المجتمع', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('مجتمع: ${widget.community['name']}', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF12102B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المالك الحالي', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(currentUsername ?? 'جاري التحميل...', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('المالك الجديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _newOwnerController,
              decoration: InputDecoration(
                hintText: 'أدخل معرف المستخدم (UUID) أو اليوزر',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF12102B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.person_add, color: Color(0xFF7F77DD)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text('ملاحظة: يجب أن يكون المستخدم الجديد عضواً بالفعل في المجتمع.', style: TextStyle(color: Colors.orange, fontSize: 12)),

            const Spacer(),

            ElevatedButton(
              onPressed: _transferOwnership,
              style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('تأكيد ونقل الملكية', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}