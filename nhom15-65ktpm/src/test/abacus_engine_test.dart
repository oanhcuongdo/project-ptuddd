import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/domain/entities/soroban_column.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/abacus_controller.dart';

void main() {
  group('Abacus Virtual Engine Tests (Module 1 - Nguyên Anh)', () {
    test('TC_AB_01: Khởi tạo cột Soroban mặc định có giá trị = 0', () {
      const col = SorobanColumn(columnIndex: 0);
      expect(col.upperBeadActive, isFalse);
      expect(col.lowerBeadsActive, 0);
      expect(col.value, 0);
    });

    test('TC_AB_02: Kích hoạt hạt trên (giá trị 5)', () {
      const col = SorobanColumn(columnIndex: 0, upperBeadActive: true);
      expect(col.value, 5);
    });

    test('TC_AB_03: Kích hoạt 3 hạt dưới (giá trị 3)', () {
      const col = SorobanColumn(columnIndex: 0, lowerBeadsActive: 3);
      expect(col.value, 3);
    });

    test('TC_AB_04: Kết hợp hạt trên và 4 hạt dưới (giá trị 9 tối đa 1 cột)', () {
      const col = SorobanColumn(
        columnIndex: 0,
        upperBeadActive: true,
        lowerBeadsActive: 4,
      );
      expect(col.value, 9);
    });

    test('TC_AB_05: Tính tổng giá trị toàn bộ bàn tính và Reset', () {
      final controller = AbacusController(columnCount: 3);
      // Đặt giá trị 352
      controller.setValue(352);
      expect(controller.totalValue, 352);

      // Reset bàn tính
      controller.reset();
      expect(controller.totalValue, 0);
      for (final col in controller.columns) {
        expect(col.value, 0);
      }
    });

    test('TC_AB_06: Tương tác gạt hạt trên và hạt dưới qua controller', () {
      final controller = AbacusController(columnCount: 2);
      // Cột 1 (hàng đơn vị): toggle hạt trên
      controller.toggleUpperBead(1);
      expect(controller.columns[1].upperBeadActive, isTrue);
      expect(controller.totalValue, 5);

      // Cột 1: set 2 hạt dưới
      controller.setLowerBeads(1, 2);
      expect(controller.totalValue, 7);

      // Cột 0 (hàng chục): set 1 hạt dưới
      controller.setLowerBeads(0, 1);
      expect(controller.totalValue, 17);
    });
  });
}
