import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_material_manager/domain/exceptions/permission_denied_exception.dart';
import 'package:study_material_manager/domain/models/cloud_document.dart';
import 'package:study_material_manager/domain/models/document_permission.dart';
import 'package:study_material_manager/domain/services/supabase_document_service.dart';

void main() {
  late SupabaseDocumentService service;

  // Định nghĩa 3 tài khoản người dùng kiểm thử (Checklist 6)
  const aliceId = 'user-alice-uid-001';
  const aliceEmail = 'alice@nhom11.edu.vn';

  const bobId = 'user-bob-uid-002';
  const bobEmail = 'bob@nhom11.edu.vn';

  const charlieId = 'user-charlie-uid-003';
  const charlieEmail = 'charlie@nhom11.edu.vn';

  setUp(() {
    service = SupabaseDocumentService(seedDefaultData: true);
  });

  group('Checklist 5 & 6: Kiểm thử Phân quyền RLS trên 3 Tài khoản (Alice, Bob, Charlie)', () {
    test('1. Kiểm tra RLS SELECT: Mỗi tài khoản chỉ nhìn thấy tài liệu mình sở hữu hoặc được chia sẻ', () async {
      // Alice: Sở hữu doc-001 (Shared), doc-002 (Private), và được Bob chia sẻ doc-003 (VIEW) -> Thấy 3 tài liệu
      final aliceDocs = await service.getAccessibleDocuments(
        userId: aliceId,
        userEmail: aliceEmail,
      );
      expect(aliceDocs.length, 3);
      expect(aliceDocs.map((d) => d.id), containsAll(['doc-001', 'doc-002', 'doc-003']));

      // Bob: Được Alice chia sẻ doc-001 (EDIT) và sở hữu doc-003 -> Thấy 2 tài liệu, KHÔNG thấy doc-002 (Riêng tư của Alice)
      final bobDocs = await service.getAccessibleDocuments(
        userId: bobId,
        userEmail: bobEmail,
      );
      expect(bobDocs.length, 2);
      expect(bobDocs.map((d) => d.id), containsAll(['doc-001', 'doc-003']));
      expect(bobDocs.map((d) => d.id), isNot(contains('doc-002')));

      // Charlie: Được Alice chia sẻ doc-001 (VIEW) và được Bob chia sẻ doc-003 (EDIT) -> Thấy 2 tài liệu, KHÔNG thấy doc-002
      final charlieDocs = await service.getAccessibleDocuments(
        userId: charlieId,
        userEmail: charlieEmail,
      );
      expect(charlieDocs.length, 2);
      expect(charlieDocs.map((d) => d.id), containsAll(['doc-001', 'doc-003']));
      expect(charlieDocs.map((d) => d.id), isNot(contains('doc-002')));
    });

    test('2. Tài khoản 1 (Alice - OWNER): Có toàn quyền Tạo, Sửa, Chia sẻ và Xóa tài liệu của mình', () async {
      // Alice tạo tài liệu mới kèm tệp đính kèm trên Supabase Storage
      final uploadedUrl = await service.uploadFileToSupabaseStorage(
        userId: aliceId,
        fileName: 'de_cuong_ai.pdf',
        fileBytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      expect(uploadedUrl, contains('study-documents'));
      expect(uploadedUrl, contains('de_cuong_ai.pdf'));

      final newDoc = await service.createDocument(
        ownerId: aliceId,
        ownerEmail: aliceEmail,
        title: 'Nhập môn Trí tuệ Nhân tạo',
        docType: 'LECTURE',
        content: 'Tìm kiếm A*, Mạng nơ-ron nhân tạo',
        fileUrl: uploadedUrl,
        subjectCode: 'AI201',
        subjectName: 'Trí tuệ Nhân tạo',
      );

      expect(newDoc.ownerId, aliceId);
      expect(newDoc.getRoleForUser(aliceId, aliceEmail), UserDocumentRole.owner);

      // Alice cập nhật tài liệu của mình
      final updatedDoc = await service.updateDocument(
        documentId: newDoc.id,
        currentUserId: aliceId,
        currentUserEmail: aliceEmail,
        title: 'Nhập môn Trí tuệ Nhân tạo (Đã cập nhật)',
      );
      expect(updatedDoc.title, 'Nhập môn Trí tuệ Nhân tạo (Đã cập nhật)');

      // Alice chia sẻ quyền VIEW cho Charlie
      final perm = await service.shareDocument(
        documentId: newDoc.id,
        currentUserId: aliceId,
        currentUserEmail: aliceEmail,
        targetEmail: charlieEmail,
        permissionLevel: PermissionLevel.view,
      );
      expect(perm.sharedWithEmail, charlieEmail);
      expect(perm.permissionLevel, PermissionLevel.view);

      // Alice xóa tài liệu của mình thành công
      await service.deleteDocument(
        documentId: newDoc.id,
        currentUserId: aliceId,
        currentUserEmail: aliceEmail,
      );
      final aliceDocsAfterDelete = await service.getAccessibleDocuments(
        userId: aliceId,
        userEmail: aliceEmail,
      );
      expect(aliceDocsAfterDelete.map((d) => d.id), isNot(contains(newDoc.id)));
    });

    test('3. Tài khoản 2 (Bob - EDITOR trên doc-001): Được phép sửa nội dung nhưng BỊ CHẶN khi cố xóa hoặc chia sẻ tiếp', () async {
      // Bob có quyền EDIT trên doc-001 nên cập nhật thành công
      final updatedByBob = await service.updateDocument(
        documentId: 'doc-001',
        currentUserId: bobId,
        currentUserEmail: bobEmail,
        title: 'Bài giảng Giải tích 1 (Bob đã bổ sung bài tập)',
        status: 'COMPLETED',
      );
      expect(updatedByBob.title, 'Bài giảng Giải tích 1 (Bob đã bổ sung bài tập)');
      expect(updatedByBob.status, 'COMPLETED');

      // Bob cố tình xóa doc-001 của Alice -> Bị RLS chặn với PermissionDeniedException
      expect(
        () => service.deleteDocument(
          documentId: 'doc-001',
          currentUserId: bobId,
          currentUserEmail: bobEmail,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      // Bob cố tình chia sẻ doc-001 của Alice cho người thứ 4 -> Bị RLS chặn
      expect(
        () => service.shareDocument(
          documentId: 'doc-001',
          currentUserId: bobId,
          currentUserEmail: bobEmail,
          targetEmail: 'david@nhom11.edu.vn',
          permissionLevel: PermissionLevel.view,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      // Bob cố tình sửa tài liệu riêng tư doc-002 của Alice -> Bị RLS chặn
      expect(
        () => service.updateDocument(
          documentId: 'doc-002',
          currentUserId: bobId,
          currentUserEmail: bobEmail,
          title: 'Bob cố sửa tài liệu riêng tư',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('4. Tài khoản 3 (Charlie - VIEWER trên doc-001, EDITOR trên doc-003): Chỉ được xem doc-001 nhưng sửa được doc-003', () async {
      // Charlie chỉ có quyền VIEW trên doc-001 -> Cố sửa sẽ bị chặn bởi RLS
      expect(
        () => service.updateDocument(
          documentId: 'doc-001',
          currentUserId: charlieId,
          currentUserEmail: charlieEmail,
          title: 'Charlie cố sửa tài liệu chỉ có quyền xem',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      // Charlie cố xóa doc-001 -> Bị chặn bởi RLS
      expect(
        () => service.deleteDocument(
          documentId: 'doc-001',
          currentUserId: charlieId,
          currentUserEmail: charlieEmail,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );

      // Tuy nhiên trên doc-003, Bob đã cấp quyền EDIT cho Charlie -> Charlie sửa thành công!
      final updatedDoc3 = await service.updateDocument(
        documentId: 'doc-003',
        currentUserId: charlieId,
        currentUserEmail: charlieEmail,
        content: 'Charlie đã cập nhật phần kịch bản kiểm thử RLS 3 tài khoản.',
      );
      expect(updatedDoc3.content, contains('Charlie đã cập nhật'));
    });

    test('5. Kiểm thử Thu hồi quyền (Revoke Permission) & Nâng cấp quyền', () async {
      // Alice nâng cấp quyền cho Charlie trên doc-001 từ VIEW lên EDIT
      await service.shareDocument(
        documentId: 'doc-001',
        currentUserId: aliceId,
        currentUserEmail: aliceEmail,
        targetEmail: charlieEmail,
        permissionLevel: PermissionLevel.edit,
      );

      // Bây giờ Charlie có thể sửa doc-001 thành công
      final editedByCharlie = await service.updateDocument(
        documentId: 'doc-001',
        currentUserId: charlieId,
        currentUserEmail: charlieEmail,
        content: 'Charlie sửa sau khi được nâng quyền lên EDIT',
      );
      expect(editedByCharlie.content, 'Charlie sửa sau khi được nâng quyền lên EDIT');

      // Alice thu hồi quyền của Bob (perm-001) trên doc-001
      await service.revokePermission(
        documentId: 'doc-001',
        permissionId: 'perm-001',
        currentUserId: aliceId,
        currentUserEmail: aliceEmail,
      );

      // Sau khi bị thu hồi, Bob không còn nhìn thấy doc-001 trong danh sách nữa
      final bobDocsAfterRevoke = await service.getAccessibleDocuments(
        userId: bobId,
        userEmail: bobEmail,
      );
      expect(bobDocsAfterRevoke.map((d) => d.id), isNot(contains('doc-001')));

      // Và Bob cũng không thể sửa doc-001 được nữa
      expect(
        () => service.updateDocument(
          documentId: 'doc-001',
          currentUserId: bobId,
          currentUserEmail: bobEmail,
          title: 'Bob cố sửa sau khi bị thu hồi quyền',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('6. Kiểm thử Tìm kiếm và Lọc phạm vi (ALL / OWNED / SHARED) cho từng tài khoản', () async {
      // Tìm kiếm theo từ khóa "Giải tích" với tài khoản Bob
      final searchResult = await service.searchDocuments(
        userId: bobId,
        userEmail: bobEmail,
        query: 'Giải tích',
      );
      expect(searchResult.length, 1);
      expect(searchResult.first.id, 'doc-001');

      // Lọc tài liệu OWNED (Của tôi) với tài khoản Bob -> Chỉ có doc-003
      final bobOwned = await service.searchDocuments(
        userId: bobId,
        userEmail: bobEmail,
        filterScope: 'OWNED',
      );
      expect(bobOwned.length, 1);
      expect(bobOwned.first.id, 'doc-003');

      // Lọc tài liệu SHARED (Được chia sẻ với tôi) với tài khoản Bob -> Chỉ có doc-001
      final bobShared = await service.searchDocuments(
        userId: bobId,
        userEmail: bobEmail,
        filterScope: 'SHARED',
      );
      expect(bobShared.length, 1);
      expect(bobShared.first.id, 'doc-001');
    });
  });
}
