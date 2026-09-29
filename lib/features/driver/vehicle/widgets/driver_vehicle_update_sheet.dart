library;

import 'package:flutter/material.dart';

import '../../profile/providers/driver_kyc_update_state.dart';
import '../../profile/widgets/driver_kyc_update_sheet.dart';

class DriverVehicleUpdateSheet extends StatelessWidget {
  const DriverVehicleUpdateSheet({super.key, required this.kycId});

  final int kycId;

  @override
  Widget build(BuildContext context) {
    return DriverKycUpdateSheet(
      kycId: kycId,
      documentGroup: DriverKycUpdateDocumentGroup.vehicle,
    );
  }
}
