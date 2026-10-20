import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/cloud_document.dart';
import '../../domain/models/document_permission.dart';
import '../../state/supabase_provider.dart';

class ShareDocumentDialog extends StatefulWidget {
  final CloudDocument document;

  const ShareDocumentDialog({super.key, required this.document});

  @override
  State<ShareDocumentDialog> createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final TextEditingController _emailController = TextEditingController();
  PermissionLevel _selectedLevel = PermissionLevel.view;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupabaseProvider>();
    final currentDoc = provider.documents.firstWhere(
      (d) => d.id == widget.document.id,
      orElse: () => widget.document,
    );
    final isOwner = currentDoc.canShare(
      provider.activeUser.id,
      provider.activeUser.email,
    );
    final otherAccounts = provider.availableTestAccounts
        .where((u) => u.email.toLowerCase() != provider.activeUser.email.toLowerCase())
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.share, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Phân quyền Chia sẻ Tài liệu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentDoc.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Chủ sở hữu: ${currentDoc.ownerEmail ?? currentDoc.ownerId}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const Divider(height: 24),
              if (isOwner) ...[
                const Text(
                  'Cấp quyền cho người dùng khác:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: otherAccounts.map((acc) {
                    return ActionChip(
                      avatar: const Icon(Icons.person_add_alt_1, size: 16),
                      label: Text(acc.email),
                      onPressed: () {
                        setState(() {
                          _emailController.text = acc.email;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email người nhận',
                    hintText: 'Nhập email (vd: bob@nhom11.edu.vn)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Mức quyền RLS: '),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<PermissionLevel>(
                        value: _selectedLevel,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: PermissionLevel.values.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text('${level.label} (${level.code})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLevel = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        if (email.isEmpty) return;
                        final ok = await provider.shareDocument(
                          documentId: currentDoc.id,
                          targetEmail: email,
                          permissionLevel: _selectedLevel,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Đã chia sẻ quyền ${_selectedLevel.label} cho $email'
                                    : (provider.errorMessage ?? 'Lỗi chia sẻ'),
                              ),
                              backgroundColor: ok ? Colors.green : Colors.red,
                            ),
                          );
                          if (ok) _emailController.clear();
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Cấp quyền'),
                    ),
                  ],
                ),
                const Divider(height: 24),
              ],
              const Text(
                'Danh sách người dùng được phân quyền (Bảng document_permissions):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (currentDoc.permissions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Tài liệu này đang ở chế độ Riêng tư (Chưa chia sẻ cho ai).',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                )
              else
                ...currentDoc.permissions.map((perm) {
                  final isEdit = perm.permissionLevel == PermissionLevel.edit;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: isEdit ? Colors.orange[100] : Colors.blue[100],
                        child: Icon(
                          isEdit ? Icons.edit_note : Icons.visibility,
                          color: isEdit ? Colors.deepOrange : Colors.blue[800],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        perm.sharedWithEmail,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Quyền hạn: ${perm.permissionLevel.label} (${perm.permissionLevel.code})'),
                      trailing: isOwner
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              tooltip: 'Thu hồi quyền truy cập',
                              onPressed: () async {
                                await provider.revokePermission(
                                  documentId: currentDoc.id,
                                  permissionId: perm.id,
                                );
                              },
                            )
                          : null,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
