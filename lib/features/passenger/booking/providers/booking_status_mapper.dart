import '../../../../domain/models/ride_status.dart';
import '../models/booking_flow_state.dart';

class BookingStatusMapper {
  static BookingFlowState mapBackendStatus(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return BookingFlowState.searching;
      case RideStatus.accepted:
        return BookingFlowState.driverAssigned;
      case RideStatus.arrived:
        return BookingFlowState.arrived;
      case RideStatus.inProgress:
        return BookingFlowState.inProgress;
      case RideStatus.completed:
        return BookingFlowState.completed;
      case RideStatus.cancelled:
        return BookingFlowState.routePreview;
    }
  }
}
