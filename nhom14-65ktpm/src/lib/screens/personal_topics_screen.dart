import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/personal_topic_model.dart';
import '../services/personal_topic_service.dart';

class PersonalTopicsScreen extends StatefulWidget {
  const PersonalTopicsScreen({super.key});

  @override
  State<PersonalTopicsScreen> createState() => _PersonalTopicsScreenState();
}

class _PersonalTopicsScreenState extends State<PersonalTopicsScreen> {
  final PersonalTopicService _service = PersonalTopicService();
  List<PersonalTopic> _topics = [];
  List<FieldItem> _fields = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final topicsData = await _service.fetchPersonalTopics();
      final fieldsData = await _service.fetchFields();
      if (!mounted) return;
      setState(() {
        _topics = topicsData;
        _fields = fieldsData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Lỗi tải dữ liệu: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  List<PersonalTopic> get _filteredTopics {
    if (_selectedFilter == 'all') return _topics;
    return _topics.where((t) => t.status == _selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'idea':
      default:
        return Colors.blue;
    }
  }

  void _openTopicForm({PersonalTopic? existingTopic}) {
    final isEditing = existingTopic != null;
    final titleCtrl = TextEditingController(text: existingTopic?.title ?? '');
    final descCtrl = TextEditingController(text: existingTopic?.description ?? '');
    final objCtrl = TextEditingController(text: existingTopic?.objectives ?? '');
    final techCtrl = TextEditingController(text: existingTopic?.technologies ?? '');
    final planCtrl = TextEditingController(text: existingTopic?.implementationPlan ?? '');

    String? selectedFieldId = existingTopic?.fieldId;
    if (selectedFieldId != null && !_fields.any((f) => f.id == selectedFieldId)) {
      selectedFieldId = null;
    }
    String selectedStatus = existingTopic?.status ?? 'idea';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Chỉnh sửa đề tài cá nhân' : 'Thêm đề tài mới',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên đề tài *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Vui lòng nhập tên đề tài'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (_fields.isNotEmpty) ...[
                        DropdownButtonFormField<String?>(
                          value: selectedFieldId,
                          decoration: const InputDecoration(
                            labelText: 'Lĩnh vực nghiên cứu',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('-- Chọn lĩnh vực --'),
                            ),
                            ..._fields.map(
                              (f) => DropdownMenuItem<String?>(
                                value: f.id,
                                child: Text(f.name),
                              ),
                            ),
                          ],
                          onChanged: (val) => setModalState(() => selectedFieldId = val),
                        ),
                        const SizedBox(height: 12),
                      ],
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'idea', child: Text('Ý tưởng')),
                          DropdownMenuItem(value: 'in_progress', child: Text('Đang phát triển')),
                          DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedStatus = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả chi tiết',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: objCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Mục tiêu đề tài',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: techCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Công nghệ sử dụng (VD: Flutter, Supabase)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: planCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Hướng triển khai thực hiện',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSaving = true);
                                  try {
                                    final userId = Supabase.instance.client.auth.currentUser!.id;
                                    final topicData = PersonalTopic(
                                      id: existingTopic?.id,
                                      userId: userId,
                                      fieldId: selectedFieldId,
                                      title: titleCtrl.text.trim(),
                                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                      objectives: objCtrl.text.trim().isEmpty ? null : objCtrl.text.trim(),
                                      technologies: techCtrl.text.trim().isEmpty ? null : techCtrl.text.trim(),
                                      implementationPlan: planCtrl.text.trim().isEmpty ? null : planCtrl.text.trim(),
                                      status: selectedStatus,
                                      source: existingTopic?.source ?? 'manual',
                                    );

                                    if (isEditing) {await _service.updateTopic(topicData);
if (!mounted) return;
Navigator.pop(ctx);
_showSnackBar('Đã cập nhật đề tài!');
} else {
await _service.createTopic(topicData);
if (!mounted) return;
Navigator.pop(ctx);
_showSnackBar('Đã thêm đề tài mới!');
}
_loadInitialData();
} catch (e) {
setModalState(() => isSaving = false);
_showSnackBar('Lỗi lưu đề tài: $e', isError: true);
}
},
child: isSaving
? const SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(strokeWidth: 2),
)
: Text(isEditing ? 'Lưu thay đổi' : 'Tạo đề tài'),
),
),
],
),
),
),
);
},
);
},
);
}
Future _confirmDelete(PersonalTopic topic) async {
final confirmed = await showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: const Text('Xóa đề tài?'),
content: Text('Bạn có chắc muốn xóa đề tài "${topic.title}" không?'),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx, false),
child: const Text('Hủy'),
),
TextButton(
onPressed: () => Navigator.pop(ctx, true),
style: TextButton.styleFrom(foregroundColor: Colors.red),
child: const Text('Xóa'),
),
],
),
);
if (confirmed == true && topic.id != null) {
try {
await _service.deleteTopic(topic.id!);
_showSnackBar('Đã xóa đề tài');
_loadInitialData();
} catch (e) {
_showSnackBar('Lỗi khi xóa: $e', isError: true);
}
}
}
void _showTopicDetail(PersonalTopic topic) {
showDialog(
context: context,
builder: (ctx) => AlertDialog(
title: Text(topic.title),
content: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
_detailRow('Trạng thái:', topic.statusLabel),
_detailRow(
'Nguồn tạo:',
topic.source == 'ai_suggestion' ? 'Lưu từ gợi ý AI' : 'Tự tạo',
),
if (topic.fieldName != null) _detailRow('Lĩnh vực:', topic.fieldName!),
if (topic.description != null) _detailRow('Mô tả:', topic.description!),
if (topic.objectives != null) _detailRow('Mục tiêu:', topic.objectives!),
if (topic.technologies != null) _detailRow('Công nghệ:', topic.technologies!),
if (topic.implementationPlan != null)
_detailRow('Hướng triển khai:', topic.implementationPlan!),
],
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx),
child: const Text('Đóng'),
),
ElevatedButton(
onPressed: () {
Navigator.pop(ctx);
_openTopicForm(existingTopic: topic);
},
child: const Text('Chỉnh sửa'),
),
],
),
);
}
Widget _detailRow(String label, String value) {
return Padding(
padding: const EdgeInsets.only(bottom: 8),
child: RichText(
text: TextSpan(
style: const TextStyle(color: Colors.black87, fontSize: 14),
children: [
TextSpan(
text: '$label ',
style: const TextStyle(fontWeight: FontWeight.bold),
),
TextSpan(text: value),
],
),
),
);
}
@override
Widget build(BuildContext context) {
final list = _filteredTopics;
return Scaffold(
appBar: AppBar(
title: const Text('Đề tài cá nhân'),
actions: [
IconButton(
icon: const Icon(Icons.refresh),
tooltip: 'Làm mới',
onPressed: _loadInitialData,
),
],
),
body: Column(
children: [
SingleChildScrollView(
scrollDirection: Axis.horizontal,
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
child: Row(
children: [
_buildFilterChip('Tất cả', 'all'),
const SizedBox(width: 8),
_buildFilterChip('Ý tưởng', 'idea'),
const SizedBox(width: 8),
_buildFilterChip('Đang phát triển', 'in_progress'),
const SizedBox(width: 8),
_buildFilterChip('Hoàn thành', 'completed'),
],
),
),
Expanded(
child: _isLoading
? const Center(child: CircularProgressIndicator())
: list.isEmpty
? Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
const SizedBox(height: 12),
const Text(
'Chưa có đề tài cá nhân nào',
style: TextStyle(fontSize: 16, color: Colors.grey),
),
const SizedBox(height: 8),
ElevatedButton.icon(
onPressed: () => _openTopicForm(),
icon: const Icon(Icons.add),
label: const Text('Tạo đề tài đầu tiên'),
),
],
),
)
: RefreshIndicator(
onRefresh: _loadInitialData,
child: ListView.builder(
padding: const EdgeInsets.all(12),
itemCount: list.length,
itemBuilder: (context, index) {
final topic = list[index];
final statusColor = _getStatusColor(topic.status);
return Card(
margin: const EdgeInsets.only(bottom: 12),
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
child: InkWell(
borderRadius: BorderRadius.circular(12),
onTap: () => _showTopicDetail(topic),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Text(
topic.title,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
),
PopupMenuButton(
onSelected: (value) {
if (value == 'edit') {
_openTopicForm(existingTopic: topic);
} else if (value == 'delete') {
_confirmDelete(topic);
}
},
itemBuilder: (ctx) => const [
PopupMenuItem(
value: 'edit',
child: Row(
children: [
Icon(Icons.edit, size: 18),
SizedBox(width: 8),
Text('Chỉnh sửa'),
],
),
),
PopupMenuItem(
value: 'delete',
child: Row(
children: [
Icon(Icons.delete, size: 18, color: Colors.red),
SizedBox(width: 8),
Text('Xóa', style: TextStyle(color: Colors.red)),
],
),
),
],
),
],
),
if (topic.description != null &&
topic.description!.isNotEmpty) ...[
const SizedBox(height: 6),
Text(
topic.description!,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: TextStyle(color: Colors.grey.shade700),
),
],
const SizedBox(height: 10),
Wrap(
spacing: 8,
runSpacing: 6,
children: [
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: statusColor.withOpacity(0.15),
borderRadius: BorderRadius.circular(20),
),
child: Text(
topic.statusLabel,
style: TextStyle(
color: statusColor,
fontWeight: FontWeight.w600,
fontSize: 12,
),
),
),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10, vertical: 4),
decoration: BoxDecoration(
color: topic.source == 'ai_suggestion'
? Colors.purple.shade50
: Colors.grey.shade200,
borderRadius: BorderRadius.circular(20),
),
child: Text(
topic.source == 'ai_suggestion'
? '✨ Gợi ý AI'
: '✍️ Tự tạo',
style: TextStyle(
color: topic.source == 'ai_suggestion'
? Colors.purple.shade700
: Colors.black87,
fontSize: 12,
),
),
),
if (topic.fieldName != null)
Chip(
label: Text(
topic.fieldName!,
style: const TextStyle(fontSize: 12),
),
visualDensity: VisualDensity.compact,
materialTapTargetSize:
MaterialTapTargetSize.shrinkWrap,
),
],
),
],
),
),
),
);
},
),
),
),
],
),
floatingActionButton: FloatingActionButton.extended(
onPressed: () => _openTopicForm(),
icon: const Icon(Icons.add),
label: const Text('Thêm đề tài'),
),
);
}
Widget _buildFilterChip(String label, String value) {
final isSelected = _selectedFilter == value;
return ChoiceChip(
label: Text(label),
selected: isSelected,
onSelected: (selected) {
if (selected) setState(() => _selectedFilter = value);
},
);
}
}
