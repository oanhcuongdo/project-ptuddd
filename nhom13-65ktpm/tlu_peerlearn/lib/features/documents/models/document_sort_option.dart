import 'document_item.dart';

enum DocumentSortOption {
  newest('Mới nhất'),
  oldest('Cũ nhất'),
  nameAsc('Tên A → Z'),
  nameDesc('Tên Z → A'),
  sizeDesc('Dung lượng lớn nhất');

  final String label;
  const DocumentSortOption(this.label);

  List<DocumentItem> sort(List<DocumentItem> list) {
    final copy = List<DocumentItem>.from(list);
    switch (this) {
      case DocumentSortOption.newest:
        copy.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        break;
      case DocumentSortOption.oldest:
        copy.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
        break;
      case DocumentSortOption.nameAsc:
        copy.sort((a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
        break;
      case DocumentSortOption.nameDesc:
        copy.sort((a, b) => b.fileName.toLowerCase().compareTo(a.fileName.toLowerCase()));
        break;
      case DocumentSortOption.sizeDesc:
        copy.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
    }
    return copy;
  }
}
