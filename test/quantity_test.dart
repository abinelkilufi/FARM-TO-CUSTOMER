import 'package:farm_to_table/utils/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quantityStepForUnit', () {
    test('uses 0.5 for kilograms', () {
      expect(quantityStepForUnit('kg'), 0.5);
      expect(quantityStepForUnit(' KG '), 0.5);
    });

    test('uses 1 for other units', () {
      expect(quantityStepForUnit('bunch'), 1);
      expect(quantityStepForUnit('piece'), 1);
      expect(quantityStepForUnit('crate'), 1);
    });
  });

  group('formatQuantityValue', () {
    test('drops the decimal for whole numbers', () {
      expect(formatQuantityValue(2), '2');
      expect(formatQuantityValue(2.0), '2');
    });

    test('keeps one decimal for fractions', () {
      expect(formatQuantityValue(1.5), '1.5');
      expect(formatQuantityValue(0.5), '0.5');
    });
  });
}
