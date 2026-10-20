import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../state/document_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/search_filter_bar.dart';
import 'add_edit_document_screen.dart';
import 'document_detail_screen.dart';
import 'subjects_screen.dart';
import 'statistics_screen.dart';
import 'cloud_sharing_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _showDeleteDialog(BuildContext context, Document doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${doc.title}"?\n'
          'Thao tác này sẽ ghi nhận vết vào bảng DeleteLogs (Tombstone).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<DocumentProvider>().deleteDocument(doc.documentPk);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa tài liệu và tạo DeleteLog Tombstone!')),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(BuildContext context) {
    final provider = context.watch<DocumentProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredDocs = provider.filteredDocuments;

    return Column(
      children: [
        const SearchFilterBar(),
        const SizedBox(height: 8),
        Expanded(
          child: filteredDocs.isEmpty
              ? EmptyStateView(
                  icon: Icons.search_off_outlined,
                  title: provider.filter.hasActiveFilter
                      ? 'Không tìm thấy tài liệu phù hợp'
                      : 'Chưa có tài liệu học tập nào',
                  subtitle: provider.filter.hasActiveFilter
                      ? 'Hãy thử điều chỉnh từ khóa tìm kiếm hoặc bỏ bớt các bộ lọc.'
                      : 'Nhấn nút "+" bên dưới để thêm bài giảng, bài tập hoặc tài liệu tham khảo đầu tiên.',
                  action: provider.filter.hasActiveFilter
                      ? OutlinedButton.icon(
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Xóa bộ lọc'),
                          onPressed: () => provider.clearFilters(),
                        )
                      : FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm Tài Liệu'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddEditDocumentScreen(),
                              ),
                            );
                          },
                        ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final subject =
                        doc.subjectFk != null ? provider.subjectMap[doc.subjectFk] : null;

                    return DocumentCard(
                      document: doc,
                      subject: subject,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentDetailScreen(documentPk: doc.documentPk),
                          ),
                        );
                      },
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditDocumentScreen(document: doc),
                          ),
                        );
                      },
                      onDelete: () => _showDeleteDialog(context, doc),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('Tài Liệu Học Tập'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Làm mới',
                  onPressed: () => setState(() {}),
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDocumentsTab(context),
          const SubjectsScreen(),
          const CloudSharingScreen(),
          const StatisticsScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditDocumentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm tài liệu'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Tài liệu',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Môn học',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_sync_outlined),
            selectedIcon: Icon(Icons.cloud_sync),
            label: 'Cloud RLS',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
