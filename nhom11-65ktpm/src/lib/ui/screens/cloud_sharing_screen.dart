import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/cloud_document.dart';
import '../../state/auth_provider.dart';
import '../../state/supabase_provider.dart';
import '../widgets/share_document_dialog.dart';

class CloudSharingScreen extends StatelessWidget {
  const CloudSharingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = context.watch<SupabaseProvider>();
    final auth = context.watch<AuthProvider>();
    final activeUser = supabase.activeUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Cloud & Phân quyền RLS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu từ Supabase',
            onPressed: () => supabase.refreshDocuments(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Khối chuyển đổi 3 tài khoản kiểm thử phân quyền (Checklist 6)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, size: 18, color: Colors.teal),
                    const SizedBox(width: 6),
                    Text(
                      'KIỂM THỬ PHÂN QUYỀN ĐA TÀI KHOẢN (RLS): ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Đang đăng nhập: ${activeUser.email}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...supabase.availableTestAccounts.map((acc) {
                        final isSelected = acc.email.toLowerCase() == activeUser.email.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(
                              isSelected ? Icons.check_circle : Icons.account_circle_outlined,
                              size: 16,
                            ),
                            label: Text(acc.email.split('@').first.toUpperCase()),
                            selected: isSelected,
                            onSelected: (_) => supabase.switchActiveAccount(acc),
                          ),
                        );
                      }),
                      if (auth.isSignedIn && auth.currentUser?.email != null)
                        ActionChip(
                          avatar: const Icon(Icons.login, size: 16, color: Colors.orange),
                          label: Text('Google: ${auth.currentUser!.email}'),
                          onPressed: () {
                            supabase.syncGoogleUserToSupabase(
                              uid: auth.currentUser!.uid,
                              email: auth.currentUser!.email!,
                              displayName: auth.currentUser!.displayName,
                              photoUrl: auth.currentUser!.photoURL,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Thanh tìm kiếm và lọc phạm vi tài liệu
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              onChanged: (val) => supabase.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tài liệu Cloud (tiêu đề, môn học, nội dung, email)...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _buildScopeChip(context, supabase, 'ALL', 'Tất cả có quyền'),
                const SizedBox(width: 8),
                _buildScopeChip(context, supabase, 'OWNED', 'Tài liệu của tôi'),
                const SizedBox(width: 8),
                _buildScopeChip(context, supabase, 'SHARED', 'Được chia sẻ'),
              ],
            ),
          ),

          // 3. Danh sách tài liệu theo RLS
          Expanded(
            child: supabase.isLoading
                ? const Center(child: CircularProgressIndicator())
                : supabase.documents.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có tài liệu nào khớp với quyền truy cập hiện tại.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: supabase.documents.length,
                        itemBuilder: (context, index) {
                          final doc = supabase.documents[index];
                          final role = doc.getRoleForUser(activeUser.id, activeUser.email);
                          return _buildCloudDocumentCard(context, supabase, doc, role);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrEditDialog(context, supabase),
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Thêm Tài liệu Cloud'),
      ),
    );
  }

  Widget _buildScopeChip(
    BuildContext context,
    SupabaseProvider provider,
    String scope,
    String label,
  ) {
    final selected = provider.filterScope == scope;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => provider.setFilterScope(scope),
    );
  }

  Widget _buildCloudDocumentCard(
    BuildContext context,
    SupabaseProvider provider,
    CloudDocument doc,
    UserDocumentRole role,
  ) {
    Color badgeColor;
    IconData badgeIcon;
    switch (role) {
      case UserDocumentRole.owner:
        badgeColor = Colors.green;
        badgeIcon = Icons.admin_panel_settings;
        break;
      case UserDocumentRole.editor:
        badgeColor = Colors.deepOrange;
        badgeIcon = Icons.edit_document;
        break;
      case UserDocumentRole.viewer:
        badgeColor = Colors.blue;
        badgeIcon = Icons.visibility;
        break;
      case UserDocumentRole.none:
        badgeColor = Colors.grey;
        badgeIcon = Icons.lock;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 14, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        'Quyền: ${role.label} (${role.code})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (doc.subjectCode != null && doc.subjectCode!.isNotEmpty)
                  Chip(
                    label: Text(
                      '${doc.subjectCode} - ${doc.subjectName ?? ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                const Spacer(),
                Text(
                  doc.docType,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              doc.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (doc.content != null && doc.content!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                doc.content!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Chủ sở hữu: ${doc.ownerEmail ?? doc.ownerId}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.group_outlined, size: 14, color: Colors.teal),
                const SizedBox(width: 4),
                Text(
                  'Chia sẻ: ${doc.permissions.length} người',
                  style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Nút Chia sẻ (Mở hộp thoại phân quyền)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ShareDocumentDialog(document: doc),
                    );
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(role == UserDocumentRole.owner ? 'Phân quyền' : 'Xem quyền'),
                ),
                const SizedBox(width: 4),
                // Nút Chỉnh sửa (Kiểm tra RLS khi nhấn)
                TextButton.icon(
                  onPressed: () {
                    _showCreateOrEditDialog(context, provider, existingDoc: doc);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Cập nhật'),
                ),
                const SizedBox(width: 4),
                // Nút Xóa (Kiểm tra RLS: chỉ Owner xóa được)
                TextButton.icon(
                  onPressed: () async {
                    final ok = await provider.deleteDocument(doc.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Đã xóa tài liệu "${doc.title}"'
                                : (provider.errorMessage ?? 'Bị chặn bởi RLS!'),
                          ),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOrEditDialog(
    BuildContext context,
    SupabaseProvider provider, {
    CloudDocument? existingDoc,
  }) {
    final titleCtrl = TextEditingController(text: existingDoc?.title ?? '');
    final contentCtrl = TextEditingController(text: existingDoc?.content ?? '');
    final subjectCodeCtrl = TextEditingController(text: existingDoc?.subjectCode ?? 'IT101');
    final subjectNameCtrl = TextEditingController(text: existingDoc?.subjectName ?? 'Công nghệ Phần mềm');
    final fileUrlCtrl = TextEditingController(
      text: existingDoc?.fileUrl ?? 'https://study-material-nhom11.supabase.co/storage/v1/object/public/study-documents/bai_giang.pdf',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingDoc == null ? 'Tạo Tài liệu Supabase Mới' : 'Cập nhật Tài liệu'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề tài liệu *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subjectCodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mã môn',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: subjectNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên môn học',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung tóm tắt / Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fileUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Đường dẫn tệp (Supabase Storage URL)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              bool ok;
              if (existingDoc == null) {
                ok = await provider.createDocument(
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  subjectCode: subjectCodeCtrl.text,
                  subjectName: subjectNameCtrl.text,
                  fileUrl: fileUrlCtrl.text,
                );
              } else {
                ok = await provider.updateDocument(
                  documentId: existingDoc.id,
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  subjectCode: subjectCodeCtrl.text,
                  subjectName: subjectNameCtrl.text,
                  fileUrl: fileUrlCtrl.text,
                );
              }

              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? (provider.lastActionMessage ?? 'Thành công!')
                          : (provider.errorMessage ?? 'Thao tác bị từ chối bởi RLS!'),
                    ),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text(existingDoc == null ? 'Tạo mới' : 'Lưu cập nhật'),
          ),
        ],
      ),
    );
  }
}
