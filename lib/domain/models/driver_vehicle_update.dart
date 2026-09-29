library;

class DriverVehicleUpdate {
  const DriverVehicleUpdate({
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.range,
    required this.airConditioning,
    this.sidUserId,
    this.vehicleStatus = 'PENDING_VALIDATION',
  });

  final String brand;
  final String model;
  final String year;
  final String color;
  final String licensePlate;
  final String range;
  final bool airConditioning;
  final int? sidUserId;
  final String vehicleStatus;

  Map<String, dynamic> toJson() {
    return {
      'brand': brand.trim(),
      'model': model.trim(),
      'year': int.tryParse(year.trim()) ?? year.trim(),
      'color': color.trim(),
      'licensePlate': licensePlate.trim(),
      'range': range.trim().toUpperCase(),
      'airConditioning': airConditioning,
      'vehicleStatus': vehicleStatus,
      if (sidUserId != null) 'sidUserId': sidUserId,
    };
  }
}
