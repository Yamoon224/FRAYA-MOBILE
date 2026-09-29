library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../auth/providers/driver_admin_status_gate.dart';

class DriverVehicleStatusViewData {
  const DriverVehicleStatusViewData({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isEditable,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isEditable;
}

abstract final class DriverVehicleStatusResolver {
  static DriverVehicleStatusViewData resolve(
    BuildContext context,
    DriverAdminStatusResult gate, {
    String? vehicleRejectionReason,
  }) {
    if (gate.needsKycSubmission) {
      return DriverVehicleStatusViewData(
        title: 'Soumettez d abord votre KYC',
        message:
            'Le dossier chauffeur doit être envoyé avant de renseigner le véhicule.',
        buttonLabel: 'Retour au KYC',
        icon: Icons.assignment_late_outlined,
        backgroundColor: context.colors.infoBackground,
        foregroundColor: AppColors.infoText,
        isEditable: false,
      );
    }

    if (gate.isKycPending && !gate.hasVehicleId) {
      return DriverVehicleStatusViewData(
        title: 'KYC envoyé, véhicule à compléter',
        message:
            'Votre dossier KYC est en attente. Vous pouvez déjà terminer l\'étape véhicule pendant la vérification admin.',
        buttonLabel: 'Enregistrer le véhicule',
        icon: Icons.directions_car_outlined,
        backgroundColor: context.colors.infoBackground,
        foregroundColor: AppColors.infoText,
        isEditable: true,
      );
    }

    if (gate.vehicleState == DriverAdminApprovalState.rejected) {
      return DriverVehicleStatusViewData(
        title: 'Véhicule à renvoyer',
        message: vehicleRejectionReason?.trim().isNotEmpty == true
            ? vehicleRejectionReason!.trim()
            : 'Votre précédent dossier véhicule a été rejeté. Merci de remplacer les informations ou documents concernés.',
        buttonLabel: 'Renvoyer le dossier',
        icon: Icons.error_outline_rounded,
        backgroundColor: AppColors.error.withValues(alpha: 0.12),
        foregroundColor: AppColors.error,
        isEditable: true,
      );
    }

    if (gate.vehicleState == DriverAdminApprovalState.pending) {
      return DriverVehicleStatusViewData(
        title: 'Validation admin en cours',
        message:
            'Votre véhicule a bien été soumis. Un administrateur doit encore le valider.',
        buttonLabel: 'Actualiser le statut',
        icon: Icons.directions_car_filled_outlined,
        backgroundColor: context.colors.infoBackground,
        foregroundColor: AppColors.infoText,
        isEditable: false,
      );
    }

    return DriverVehicleStatusViewData(
      title: 'Enregistrement obligatoire',
      message:
          'Le volet chauffeur reste bloqué tant que le véhicule n\'a pas été enregistré puis validé.',
      buttonLabel: 'Enregistrer le véhicule',
      icon: Icons.badge_outlined,
      backgroundColor: context.colors.greyExtraLight,
      foregroundColor: context.colors.textPrimary,
      isEditable: true,
    );
  }
}
