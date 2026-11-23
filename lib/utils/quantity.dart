double quantityStepForUnit(String unit) {
  return unit.trim().toLowerCase() == 'kg' ? 0.5 : 1.0;
}

String formatQuantityValue(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}
