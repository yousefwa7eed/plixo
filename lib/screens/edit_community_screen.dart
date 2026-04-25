import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class EditCommunityScreen extends StatefulWidget {
  final Map<String, dynamic> community;

  const EditCommunityScreen({super.key, required this.community});

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  final supabase = SupabaseConfig.client;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  String _selectedType = 'Social';
  String _selectedColor = '#534AB7';
  int _maxCapacity = 50;
  bool _isPublic = true;

  bool _isLoading = false;
  bool _isCheckingPermission = true;
  bool _isOwner = false;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'بنفسجي', 'code': '#534AB7'},
    {'name': 'أخضر', 'code': '#1D9E75'},
    {'name': 'برتقالي', 'code': '#D85A30'},
    {'name': 'ذهبي', 'code': '#BA7517'},
    {'name': 'أزرق نيون', 'code': '#7F77DD'},
    {'name': 'فيروزي', 'code': '#5DCAA5'},
  ];

  @override
  void initState() {
    super.initState();
    // تهيئة البيانات الحالية من المجتمع
    _nameController = TextEditingController(text: widget.community['name']);
    _descriptionController = TextEditingController(text: widget.community['description'] ?? '');
    _selectedType = widget.community['type'] ?? 'Social';
    _selectedColor = widget.community['theme_color'] ?? '#534AB7';
    _maxCapacity = widget.community['max_capacity'] ?? 50;
    _isPublic = widget.community['is_public'] ?? true;

    _checkOwnership();
  }

  // التحقق مما إذا كان المستخدم الحالي هو المالك
  Future<void> _checkOwnership() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() { _isCheckingPermission = false; });
      return;
    }

    // مقارنة ID المستخدم مع ID المالك في قاعدة البيانات
    if (user.id == widget.community['owner_id']) {
      setState(() {
        _isOwner = true;
        _isCheckingPermission = false;
      });
    } else {
      setState(() {
        _isOwner = false;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة اسم المجتمع'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('communities').update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'theme_color': _selectedColor,
        'max_capacity': _maxCapacity,
        'is_public': _isPublic,
      }).eq('id', widget.community['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات بنجاح! ✅'), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true); // العودة مع إشارة بأن هناك تحديث

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // حالة التحقق من الصلاحيات
    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0B1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF7F77DD))),
      );
    }

    // حالة عدم الملكية (رفض الوصول)
    if (!_isOwner) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0B1A),
        appBar: AppBar(
          title: const Text('خطأ في الصلاحيات', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.redAccent.withOpacity(0.5)),
              const SizedBox(height: 20),
              const Text(
                'عذراً، ليس لديك صلاحية تعديل هذا المجتمع',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'فقط منشئ المجتمع يمكنه تغيير الإعدادات',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                child: const Text('عودة', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    // واجهة التعديل للمالك
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1A),
      appBar: AppBar(
        title: const Text('تعديل المجتمع', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.greenAccent, size: 30),
              onPressed: _saveChanges,
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عنوان
            const Text(
              'تخصيص إعدادات المجتمع',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // الاسم
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('اسم المجتمع', Icons.title),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),

            // الوصف
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _inputDecoration('وصف المجتمع', Icons.description),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),

            // النوع
            _buildSectionTitle('نوع المجتمع'),
            const SizedBox(height: 10),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // اللون
            _buildSectionTitle('لون الهوية'),
            const SizedBox(height: 10),
            _buildColorSelector(),
            const SizedBox(height: 24),

            // السعة
            _buildCapacitySlider(),
            const SizedBox(height: 16),

            // الخصوصية
            _buildPrivacyToggle(),

            const SizedBox(height: 40),

            // زر الحفظ الكبير
            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('حفظ التغييرات 💾', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF12102B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      prefixIcon: Icon(icon, color: const Color(0xFF7F77DD)),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));

  Widget _buildTypeSelector() {
    return Row(
      children: ['Social', 'Study', 'Gaming'].map((type) {
        final isSelected = _selectedType == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedType = type),
              selectedColor: const Color(0xFF534AB7),
              backgroundColor: const Color(0xFF1A1740),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 10,
      children: _colors.map((c) {
        final isSelected = _selectedColor == c['code'];
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = c['code']),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Color(int.parse(c['code'].substring(1), radix: 16) + 0xFF000000),
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCapacitySlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('السعة القصوى'),
            Text('$_maxCapacity عضو', style: const TextStyle(color: Color(0xFF7F77DD))),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF534AB7),
            thumbColor: const Color(0xFF7F77DD),
          ),
          child: Slider(
            value: _maxCapacity.toDouble(),
            min: 10, max: 200, divisions: 19,
            onChanged: (v) => setState(() => _maxCapacity = v.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyToggle() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_isPublic ? Icons.public : Icons.lock, color: _isPublic ? Colors.green : Colors.orange),
      title: const Text('مجتمع عام', style: TextStyle(color: Colors.white)),
      subtitle: Text(_isPublic ? 'مرئي للجميع' : 'خاص فقط', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Switch(value: _isPublic, onChanged: (v) => setState(() => _isPublic = v)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}