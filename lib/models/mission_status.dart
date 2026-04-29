class MissionStatus {
  static const String requested = 'requested';
  static const String assigned = 'assigned';
  static const String onTheWay = 'on_the_way';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String draft = 'draft';

  static const List<String> values = [
    requested,
    assigned,
    onTheWay,
    inProgress,
    completed,
  ];

  static String normalize(String? status) {
    if (status == null || status.trim().isEmpty) {
      return requested;
    }

    final value = status.trim().toLowerCase();

    switch (value) {
      case 'requested':
      case 'solicitado':
        return requested;

      case 'assigned':
      case 'asignado':
        return assigned;

      case 'on_the_way':
      case 'on the way':
      case 'en_camino':
      case 'en camino':
        return onTheWay;

      case 'in_progress':
      case 'in progress':
      case 'en_ejecucion':
      case 'en ejecución':
      case 'en ejecucion':
        return inProgress;

      case 'completed':
      case 'finished':
      case 'finalizado':
      case 'finalizada':
        return completed;

      case 'cancelled':
      case 'canceled':
      case 'cancelado':
      case 'cancelada':
        return cancelled;

      case 'draft':
      case 'borrador':
        return draft;

      default:
        return requested;
    }
  }

  static String label(String? status) {
    final normalized = normalize(status);

    switch (normalized) {
      case requested:
        return 'Solicitado';
      case assigned:
        return 'Asignado';
      case onTheWay:
        return 'En camino';
      case inProgress:
        return 'En ejecución';
      case completed:
        return 'Finalizado';
      case cancelled:
        return 'Cancelado';
      case draft:
        return 'Borrador';
      default:
        return 'Solicitado';
    }
  }

  static int stepIndex(String? status) {
    final normalized = normalize(status);

    switch (normalized) {
      case requested:
        return 0;
      case assigned:
        return 1;
      case onTheWay:
        return 2;
      case inProgress:
        return 3;
      case completed:
        return 4;
      default:
        return 0;
    }
  }

  static String nextStatus(String? status) {
    final normalized = normalize(status);

    switch (normalized) {
      case requested:
        return assigned;
      case assigned:
        return onTheWay;
      case onTheWay:
        return inProgress;
      case inProgress:
        return completed;
      case completed:
        return completed;
      default:
        return requested;
    }
  }

  static bool isFinished(String? status) {
    return normalize(status) == completed;
  }
}