enum RideStatus {
  pending, // PENDING, SEARCHING, REQUESTED — en attente de chauffeur
  accepted, // ACCEPTED, ASSIGNED — chauffeur en route
  arrived, // ARRIVED, DRIVER_ARRIVED, WAITING_FOR_PASSENGER
  inProgress, // ONGOING, STARTED, IN_PROGRESS, ON_TRIP, PICKED_UP
  completed, // COMPLETED, FINISHED
  cancelled; // CANCELLED, CANCELED

  static RideStatus fromBackend(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'WAITING':
      case 'WAITING_DRIVER':
      case 'SEARCHING':
      case 'SEARCHING_DRIVER':
      case 'REQUESTED':
        return RideStatus.pending;
      case 'AT_PICKUP':
      case 'ARRIVED':
      case 'DRIVER_ARRIVED':
      case 'WAITING_FOR_PASSENGER':
        return RideStatus.arrived;
      case 'ONGOING':
      case 'TRIP_STARTED':
      case 'STARTED':
      case 'IN_PROGRESS':
      case 'TRIP_IN_PROGRESS':
      case 'ON_TRIP':
      case 'PICKED_UP':
        return RideStatus.inProgress;
      case 'DONE':
      case 'COMPLETED':
      case 'FINISHED':
        return RideStatus.completed;
      case 'ABORTED':
      case 'CANCELLED':
      case 'CANCELED':
      case 'CANCELLED_PASSENGER':
      case 'CANCELLED_DRIVER':
        return RideStatus.cancelled;
      case 'CONFIRMED':
      case 'ACCEPTED':
      case 'ASSIGNED':
      case 'DRIVER_ASSIGNED':
      case 'DRIVER_EN_ROUTE':
        return RideStatus.accepted;
      default:
        return RideStatus.pending;
    }
  }

  String get title {
    switch (this) {
      case RideStatus.pending:
        return 'Recherche d\'un chauffeur';
      case RideStatus.accepted:
        return 'Votre chauffeur arrive';
      case RideStatus.arrived:
        return 'Le chauffeur est arrivé';
      case RideStatus.inProgress:
        return 'En route vers votre destination';
      case RideStatus.completed:
        return 'Course terminée';
      case RideStatus.cancelled:
        return 'Course annulée';
    }
  }

  String get subtitle {
    switch (this) {
      case RideStatus.pending:
        return 'Veuillez patienter...';
      case RideStatus.accepted:
        return 'Arrivée prévue dans quelques minutes';
      case RideStatus.arrived:
        return 'Veuillez rejoindre le véhicule';
      case RideStatus.inProgress:
        return 'Profitez de votre trajet';
      case RideStatus.completed:
        return 'Merci d\'avoir choisi Fraya';
      case RideStatus.cancelled:
        return 'La course a été annulée';
    }
  }
}
