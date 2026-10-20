import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../state/document_provider.dart';
import '../widgets/empty_state_view.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  void _showSubjectDialog(BuildContext context, [Subject? subject]) {
    final isEditing = subject != null;
    final codeController = TextEditingController(text: subject?.code ?? '');
    final nameController = TextEditingController(text: subject?.name ?? '');
    final lecturerController = TextEditingController(text: subject?.lecturer ?? '');
    final semesterController = TextEditingController(text: subject?.semester ?? '');
    String selectedColor = subject?.colorHex ?? '#1E88E5';

    final colors = [
      '#1E88E5', '#43A047', '#E53935', '#FB8C00', '#8E24AA', '#00ACC1', '#3949AB',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isEditing ? 'Sửa môn học' : 'Thêm môn học mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Mã môn học *', hintText: 'VD: IT001'),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên môn học *', hintText: 'VD: Kiến trúc Phần mềm'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lecturerController,
                  decoration: const InputDecoration(labelText: 'Giảng viên', hintText: 'VD: TS. Nguyễn Văn A'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: semesterController,
                  decoration: const InputDecoration(labelText: 'Học kỳ', hintText: 'VD: HK1 2026-2027'),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Màu đại diện:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: colors.map((hex) {
                    final colorVal = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
                    return InkWell(
                      onTap: () => setState(() => selectedColor = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: selectedColor == hex
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeController.text.trim();
                final name = nameController.text.trim();
                if (code.isEmpty || name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập mã và tên môn học.')),
                  );
                  return;
                }

                final provider = context.read<DocumentProvider>();
                if (isEditing) {
                  await provider.updateSubject(
                    subjectPk: subject.subjectPk,
                    code: code,
                    name: name,
                    lecturer: lecturerController.text,
                    semester: semesterController.text,
                    colorHex: selectedColor,
                  );
                } else {
                  await provider.addSubject(
                    code: code,
                    name: name,
                    lecturer: lecturerController.text,
                    semester: semesterController.text,
                    colorHex: selectedColor,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSubjectDialog(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa môn học'),
        content: Text(
          'Bạn có chắc chắn muốn xóa môn "${subject.name}"?\n'
          'Thao tác này sẽ ghi nhận vết vào bảng DeleteLogs (Tombstone).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<DocumentProvider>().deleteSubject(subject.subjectPk);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa môn học và ghi nhận DeleteLog!')),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final subjects = provider.subjects;
    final allDocs = provider.allDocuments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục Môn học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm môn học',
            onPressed: () => _showSubjectDialog(context),
          ),
        ],
      ),
      body: subjects.isEmpty
          ? EmptyStateView(
              icon: Icons.school_outlined,
              title: 'Chưa có môn học nào',
              subtitle: 'Thêm các môn học để dễ dàng phân loại bài giảng và bài tập.',
              action: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Thêm Môn Học'),
                onPressed: () => _showSubjectDialog(context),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subj = subjects[index];
                final docCount = allDocs.where((d) => d.subjectFk == subj.subjectPk).length;
                Color color = Colors.blue;
                try {
                  color = Color(int.parse('FF${subj.colorHex.replaceFirst('#', '')}', radix: 16));
                } catch (_) {}

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Text(
                        subj.code.isNotEmpty ? subj.code.substring(0, 1) : 'S',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    title: Text('${subj.code} - ${subj.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subj.lecturer != null && subj.lecturer!.isNotEmpty)
                          Text('GV: ${subj.lecturer}'),
                        Text(
                          '${subj.semester ?? "Học kỳ hiện tại"} • $docCount tài liệu',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') _showSubjectDialog(context, subj);
                        if (val == 'delete') _showDeleteSubjectDialog(context, subj);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
