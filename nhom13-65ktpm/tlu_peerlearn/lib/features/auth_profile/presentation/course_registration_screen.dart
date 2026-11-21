import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/registration_repository.dart';
import '../domain/program_registration.dart';
import 'widgets/schedule_slot_picker.dart';

class CourseRegistrationScreen extends ConsumerStatefulWidget {
  final List<Course>? initialCourses;

  const CourseRegistrationScreen({super.key, this.initialCourses});

  @override
  ConsumerState<CourseRegistrationScreen> createState() =>
      _CourseRegistrationScreenState();
}

class _CourseRegistrationScreenState
    extends ConsumerState<CourseRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCourseId;
  String _role = 'mentee';
  final _gradeController = TextEditingController();
  final _notesController = TextEditingController();
  int _maxMentees = 5;
  final Set<int> _selectedSlots = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _gradeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn học phần')),
      );
      return;
    }

    final profile = ref.read(currentProfileProvider).value;
    if (profile == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(registrationRepositoryProvider).upsertRegistration(
            userId: profile.id,
            courseId: _selectedCourseId!,
            role: _role,
            courseGrade: _role == 'mentor'
                ? double.tryParse(_gradeController.text)
                : null,
            strengthsOrNeeds: _notesController.text,
            maxMentees: _maxMentees,
            availableSlots: _selectedSlots.toList(),
          );
      ref.invalidate(myRegistrationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu đăng ký học phần thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng ký: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = widget.initialCourses != null
        ? AsyncValue.data(widget.initialCourses!)
        : ref.watch(coursesProvider);
    final myRegsAsync = widget.initialCourses != null
        ? const AsyncValue<List<ProgramRegistration>>.data([])
        : ref.watch(myRegistrationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký Mentor / Mentee')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  coursesAsync.when(
                    data: (courses) => DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn học phần *',
                        border: OutlineInputBorder(),
                      ),
                      items: courses
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.code} - ${c.name}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCourseId = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Lỗi tải học phần: $e'),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'mentee', label: Text('Mentee')),
                      ButtonSegment(value: 'mentor', label: Text('Mentor')),
                    ],
                    selected: {_role},
                    onSelectionChanged: (set) {
                      setState(() => _role = set.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_role == 'mentor') ...[
                    TextFormField(
                      controller: _gradeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Điểm tổng kết môn (thang 10) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (_role != 'mentor') return null;
                        final grade = double.tryParse(v ?? '');
                        if (grade == null || grade < 0 || grade > 10) {
                          return 'Nhập điểm hợp lệ (0 - 10)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _maxMentees,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng Mentee tối đa',
                        border: OutlineInputBorder(),
                      ),
                      items: [1, 2, 3, 4, 5, 6, 8, 10]
                          .map((n) => DropdownMenuItem(
                                value: n,
                                child: Text('$n Mentee'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _maxMentees = v);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: _role == 'mentor'
                          ? 'Thế mạnh kiến thức'
                          : 'Chủ đề / Kiến thức đang gặp khó khăn',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ScheduleSlotPicker(
                    selectedSlots: _selectedSlots,
                    onToggleSlot: (slot) {
                      setState(() {
                        if (_selectedSlots.contains(slot)) {
                          _selectedSlots.remove(slot);
                        } else {
                          _selectedSlots.add(slot);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu đăng ký'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Học phần đã đăng ký',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            myRegsAsync.when(
              data: (regs) {
                if (regs.isEmpty) {
                  return const Text('Bạn chưa đăng ký học phần nào.');
                }
                return Column(
                  children: regs.map((r) {
                    return Card(
                      child: ListTile(
                        title: Text(
                            '${r.courseCode ?? ''} - ${r.courseName ?? r.courseId}'),
                        subtitle: Text(
                          'Vai trò: ${r.role.toUpperCase()} • ${r.availableSlots.length} buổi rảnh',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await ref
                                .read(registrationRepositoryProvider)
                                .deleteRegistration(r.id);
                            ref.invalidate(myRegistrationsProvider);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi tải danh sách: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

