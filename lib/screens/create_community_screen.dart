import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'Social'; // Social, Study, Gaming
  String _selectedColor = '#534AB7';
  int _maxCapacity = 50;
  bool _isPublic = true;
  bool _isLoading = false;

  // لوحة الألوان المستوحاة من تصميم Pixel Art
  final List<Map<String, dynamic>> _colors = [
    {'name': 'بنفسجي', 'code': '#534AB7', 'icon': Icons.color_lens},
    {'name': 'أخضر زمردي', 'code': '#1D9E75', 'icon': Icons.eco},
    {'name': 'برتقالي ناري', 'code': '#D85A30', 'icon': Icons.local_fire_department},
    {'name': 'ذهبي ملكي', 'code': '#BA7517', 'icon': Icons.star},
    {'name': 'أزرق نيون', 'code': '#7F77DD', 'icon': Icons.electric_bolt},
    {'name': 'فيروزي محيطي', 'code': '#5DCAA5', 'icon': Icons.water_drop},
  ];

  Future<void> _createCommunity() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('يرجى كتابة اسم المجتمع', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      // 1. التأكد من وجود البروفايل (Safety Check)
      // في الوضع الطبيعي الـ Trigger يقوم بهذا، لكن هذا احتياط إضافي
      final profileCheck = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (profileCheck == null) {
        await SupabaseConfig.client.from('profiles').insert({
          'id': user.id,
          'username': user.email?.split('@').first ?? 'User_${user.id.toString().substring(0, 5)}',
          'wallet_balance': 15,
          'avatar_config': '{"body": "default", "skin": "tone1"}',
        });
      }

      // 2. إدراج المجتمع الجديد
      final response = await SupabaseConfig.client
          .from('communities')
          .insert({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'theme_color': _selectedColor,
        'max_capacity': _maxCapacity,
        'is_public': _isPublic,
        'owner_id': user.id,
        'member_count': 1,
      })
          .select(); // نطلب البيانات المرتجعة للتأكد

      if (!mounted) return;

      // نجاح العملية
      _showMessage('تم إنشاء المجتمع بنجاح! 🎉', isError: false);

      // انتظار بسيط ثم العودة
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      _showMessage('حدث خطأ: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(int.parse(_selectedColor.substring(1), radix: 16) + 0xFF000000);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1A),
      appBar: AppBar(
        title: const Text('مجتمع جديد', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.15),
                      border: Border.all(color: themeColor, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 15)],
                    ),
                    child: Icon(_getTypeIcon(_selectedType), size: 40, color: themeColor),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'صمم هوية مجتمعك',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر النوع واللون المناسبين لجذب الأعضاء',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name Input
            _buildLabel('اسم المجتمع'),
            const SizedBox(height: 8),
            _buildTextField(_nameController, 'مثال: عشاق الأنمي', Icons.title),
            const SizedBox(height: 20),

            // Description Input
            _buildLabel('وصف مختصر (اختياري)'),
            const SizedBox(height: 8),
            _buildTextField(_descriptionController, 'عن ماذا يتحدث مجتمعكم؟', Icons.description, maxLines: 3),
            const SizedBox(height: 24),

            // Type Selector
            _buildLabel('نوع المجتمع'),
            const SizedBox(height: 12),
            Row(
              children: ['Social', 'Study', 'Gaming'].map((type) {
                final isSelected = _selectedType == type;
                IconData icon;
                String label;
                switch(type) {
                  case 'Social': icon = Icons.people_alt; label = 'عام'; break;
                  case 'Study': icon = Icons.school; label = 'دراسة'; break;
                  case 'Gaming': icon = Icons.sports_esports; label = 'ألعاب'; break;
                  default: icon = Icons.group; label = type;
                }
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? themeColor : const Color(0xFF1A1740),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
                          const SizedBox(height: 4),
                          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Color Selector
            _buildLabel('لون الهوية'),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final colorData = _colors[index];
                  final code = colorData['code'] as String;
                  final isSelected = _selectedColor == code;
                  final colorVal = Color(int.parse(code.substring(1), radix: 16) + 0xFF000000);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorVal,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                        boxShadow: isSelected ? [BoxShadow(color: colorVal, blurRadius: 10, spreadRadius: 2)] : [],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Capacity Slider
            _buildLabel('السعة القصوى: $_maxCapacity عضو'),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                activeTrackColor: themeColor,
                inactiveTrackColor: const Color(0xFF1A1740),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _maxCapacity.toDouble(),
                min: 10,
                max: 200,
                divisions: 19,
                onChanged: (val) => setState(() => _maxCapacity = val.round()),
              ),
            ),
            const SizedBox(height: 16),

            // Privacy Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1740),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_isPublic ? Icons.public : Icons.lock, color: _isPublic ? Colors.greenAccent : Colors.orangeAccent),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isPublic ? 'مجتمع عام' : 'مجتمع خاص', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(_isPublic ? 'مرئي للجميع' : 'بالدعوة فقط', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                    activeColor: Colors.greenAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createCommunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  elevation: 10,
                  shadowColor: themeColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'انطلق بالمجتمع 🚀',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14));

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF12102B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: const Color(0xFF7F77DD), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Social': return Icons.people_alt;
      case 'Study': return Icons.auto_stories;
      case 'Gaming': return Icons.sports_esports;
      default: return Icons.group;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}