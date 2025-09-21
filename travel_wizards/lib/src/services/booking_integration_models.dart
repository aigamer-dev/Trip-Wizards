// Models for comprehensive booking integration system

enum BookingType { flight, hotel, activity, transport }

enum BookingStatus {
  pending,
  processing,
  confirmed,
  failed,
  cancelled,
  refunded,
}

enum BookingModificationType { dateChange, nameChange, upgrade, cancellation }

/// Base class for all booking requests
abstract class BookingRequest {
  final BookingType type;
  final String requestId;
  final Map<String, dynamic> metadata;

  BookingRequest({
    required this.type,
    required this.requestId,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson();

  static BookingRequest fromJson(Map<String, dynamic> json) {
    final type = BookingType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type'],
    );

    switch (type) {
      case BookingType.flight:
        return FlightBookingRequest.fromJson(json);
      case BookingType.hotel:
        return HotelBookingRequest.fromJson(json);
      case BookingType.activity:
        return ActivityBookingRequest.fromJson(json);
      case BookingType.transport:
        return TransportBookingRequest.fromJson(json);
    }
  }
}

/// Flight booking request
class FlightBookingRequest extends BookingRequest {
  final String fromCode; // Airport code
  final String toCode; // Airport code
  final DateTime departureDate;
  final DateTime? returnDate; // null for one-way
  final int passengers;
  final String classType; // economy, business, first
  final List<PassengerInfo> passengerDetails;

  FlightBookingRequest({
    required String requestId,
    required this.fromCode,
    required this.toCode,
    required this.departureDate,
    this.returnDate,
    required this.passengers,
    required this.classType,
    required this.passengerDetails,
    Map<String, dynamic> metadata = const {},
  }) : super(
         type: BookingType.flight,
         requestId: requestId,
         metadata: metadata,
       );

  @override
  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'requestId': requestId,
    'fromCode': fromCode,
    'toCode': toCode,
    'departureDate': departureDate.toIso8601String(),
    'returnDate': returnDate?.toIso8601String(),
    'passengers': passengers,
    'classType': classType,
    'passengerDetails': passengerDetails.map((p) => p.toJson()).toList(),
    'metadata': metadata,
  };

  factory FlightBookingRequest.fromJson(Map<String, dynamic> json) {
    return FlightBookingRequest(
      requestId: json['requestId'],
      fromCode: json['fromCode'],
      toCode: json['toCode'],
      departureDate: DateTime.parse(json['departureDate']),
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'])
          : null,
      passengers: json['passengers'],
      classType: json['classType'],
      passengerDetails: (json['passengerDetails'] as List)
          .map((p) => PassengerInfo.fromJson(p))
          .toList(),
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Hotel booking request
class HotelBookingRequest extends BookingRequest {
  final String hotelId;
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nights;
  final int rooms;
  final int adults;
  final int children;
  final String roomType;
  final List<String> amenities;

  HotelBookingRequest({
    required String requestId,
    required this.hotelId,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.rooms,
    required this.adults,
    required this.children,
    required this.roomType,
    required this.amenities,
    Map<String, dynamic> metadata = const {},
  }) : super(type: BookingType.hotel, requestId: requestId, metadata: metadata);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'requestId': requestId,
    'hotelId': hotelId,
    'location': location,
    'checkInDate': checkInDate.toIso8601String(),
    'checkOutDate': checkOutDate.toIso8601String(),
    'nights': nights,
    'rooms': rooms,
    'adults': adults,
    'children': children,
    'roomType': roomType,
    'amenities': amenities,
    'metadata': metadata,
  };

  factory HotelBookingRequest.fromJson(Map<String, dynamic> json) {
    return HotelBookingRequest(
      requestId: json['requestId'],
      hotelId: json['hotelId'],
      location: json['location'],
      checkInDate: DateTime.parse(json['checkInDate']),
      checkOutDate: DateTime.parse(json['checkOutDate']),
      nights: json['nights'],
      rooms: json['rooms'],
      adults: json['adults'],
      children: json['children'],
      roomType: json['roomType'],
      amenities: List<String>.from(json['amenities']),
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Activity booking request
class ActivityBookingRequest extends BookingRequest {
  final String activityId;
  final String activityName;
  final String location;
  final DateTime activityDate;
  final String timeSlot;
  final int participants;
  final List<String> requirements;
  final Map<String, dynamic> options;

  ActivityBookingRequest({
    required String requestId,
    required this.activityId,
    required this.activityName,
    required this.location,
    required this.activityDate,
    required this.timeSlot,
    required this.participants,
    required this.requirements,
    required this.options,
    Map<String, dynamic> metadata = const {},
  }) : super(
         type: BookingType.activity,
         requestId: requestId,
         metadata: metadata,
       );

  @override
  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'requestId': requestId,
    'activityId': activityId,
    'activityName': activityName,
    'location': location,
    'activityDate': activityDate.toIso8601String(),
    'timeSlot': timeSlot,
    'participants': participants,
    'requirements': requirements,
    'options': options,
    'metadata': metadata,
  };

  factory ActivityBookingRequest.fromJson(Map<String, dynamic> json) {
    return ActivityBookingRequest(
      requestId: json['requestId'],
      activityId: json['activityId'],
      activityName: json['activityName'],
      location: json['location'],
      activityDate: DateTime.parse(json['activityDate']),
      timeSlot: json['timeSlot'],
      participants: json['participants'],
      requirements: List<String>.from(json['requirements']),
      options: json['options'],
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Transport booking request
class TransportBookingRequest extends BookingRequest {
  final String transportType; // taxi, bus, train, rental
  final String fromLocation;
  final String toLocation;
  final DateTime scheduledTime;
  final int passengers;
  final String vehicleType;
  final bool returnTrip;
  final DateTime? returnTime;

  TransportBookingRequest({
    required String requestId,
    required this.transportType,
    required this.fromLocation,
    required this.toLocation,
    required this.scheduledTime,
    required this.passengers,
    required this.vehicleType,
    required this.returnTrip,
    this.returnTime,
    Map<String, dynamic> metadata = const {},
  }) : super(
         type: BookingType.transport,
         requestId: requestId,
         metadata: metadata,
       );

  @override
  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'requestId': requestId,
    'transportType': transportType,
    'fromLocation': fromLocation,
    'toLocation': toLocation,
    'scheduledTime': scheduledTime.toIso8601String(),
    'passengers': passengers,
    'vehicleType': vehicleType,
    'returnTrip': returnTrip,
    'returnTime': returnTime?.toIso8601String(),
    'metadata': metadata,
  };

  factory TransportBookingRequest.fromJson(Map<String, dynamic> json) {
    return TransportBookingRequest(
      requestId: json['requestId'],
      transportType: json['transportType'],
      fromLocation: json['fromLocation'],
      toLocation: json['toLocation'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      passengers: json['passengers'],
      vehicleType: json['vehicleType'],
      returnTrip: json['returnTrip'],
      returnTime: json['returnTime'] != null
          ? DateTime.parse(json['returnTime'])
          : null,
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Passenger information for bookings
class PassengerInfo {
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? passportNumber;
  final String? nationality;
  final String passengerType; // adult, child, infant

  PassengerInfo({
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.passportNumber,
    this.nationality,
    required this.passengerType,
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'passportNumber': passportNumber,
    'nationality': nationality,
    'passengerType': passengerType,
  };

  factory PassengerInfo.fromJson(Map<String, dynamic> json) {
    return PassengerInfo(
      firstName: json['firstName'],
      lastName: json['lastName'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      passportNumber: json['passportNumber'],
      nationality: json['nationality'],
      passengerType: json['passengerType'],
    );
  }
}

/// Booking progress tracking
class BookingProgress {
  final String bookingId;
  final String currentStep;
  final int stepIndex;
  final int totalSteps;
  final BookingStatus status;
  final String? error;
  final DateTime timestamp;

  BookingProgress({
    required this.bookingId,
    required this.currentStep,
    required this.stepIndex,
    required this.totalSteps,
    required this.status,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'currentStep': currentStep,
    'stepIndex': stepIndex,
    'totalSteps': totalSteps,
    'status': status.toString().split('.').last,
    'error': error,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BookingProgress.fromJson(Map<String, dynamic> json) {
    return BookingProgress(
      bookingId: json['bookingId'],
      currentStep: json['currentStep'],
      stepIndex: json['stepIndex'],
      totalSteps: json['totalSteps'],
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      error: json['error'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Availability check result
class AvailabilityResult {
  final bool isAvailable;
  final String? reason;
  final DateTime? availableUntil;
  final Map<String, dynamic>? alternatives;

  AvailabilityResult({
    required this.isAvailable,
    this.reason,
    this.availableUntil,
    this.alternatives,
  });

  Map<String, dynamic> toJson() => {
    'isAvailable': isAvailable,
    'reason': reason,
    'availableUntil': availableUntil?.toIso8601String(),
    'alternatives': alternatives,
  };

  factory AvailabilityResult.fromJson(Map<String, dynamic> json) {
    return AvailabilityResult(
      isAvailable: json['isAvailable'],
      reason: json['reason'],
      availableUntil: json['availableUntil'] != null
          ? DateTime.parse(json['availableUntil'])
          : null,
      alternatives: json['alternatives'],
    );
  }
}

/// Vendor reservation result
class VendorReservationResult {
  final bool success;
  final String? reservationId;
  final String? vendorId;
  final DateTime? expiresAt;
  final int? holdAmountCents;
  final String? currency;
  final String? error;
  final Map<String, dynamic>? details;

  VendorReservationResult({
    required this.success,
    this.reservationId,
    this.vendorId,
    this.expiresAt,
    this.holdAmountCents,
    this.currency,
    this.error,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'reservationId': reservationId,
    'vendorId': vendorId,
    'expiresAt': expiresAt?.toIso8601String(),
    'holdAmountCents': holdAmountCents,
    'currency': currency,
    'error': error,
    'details': details,
  };

  factory VendorReservationResult.fromJson(Map<String, dynamic> json) {
    return VendorReservationResult(
      success: json['success'],
      reservationId: json['reservationId'],
      vendorId: json['vendorId'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      holdAmountCents: json['holdAmountCents'],
      currency: json['currency'],
      error: json['error'],
      details: json['details'],
    );
  }
}

/// Payment processing result
class PaymentResult {
  final bool success;
  final String? paymentId;
  final int? amountCents;
  final String? currency;
  final String? paymentMethod;
  final DateTime? processedAt;
  final String? error;
  final Map<String, dynamic>? paymentDetails;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.amountCents,
    this.currency,
    this.paymentMethod,
    this.processedAt,
    this.error,
    this.paymentDetails,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'paymentId': paymentId,
    'amountCents': amountCents,
    'currency': currency,
    'paymentMethod': paymentMethod,
    'processedAt': processedAt?.toIso8601String(),
    'error': error,
    'paymentDetails': paymentDetails,
  };

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'],
      paymentId: json['paymentId'],
      amountCents: json['amountCents'],
      currency: json['currency'],
      paymentMethod: json['paymentMethod'],
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      error: json['error'],
      paymentDetails: json['paymentDetails'],
    );
  }
}

/// Final booking confirmation
class BookingConfirmation {
  final String confirmationCode;
  final String vendorBookingId;
  final String vendorId;
  final int totalAmountCents;
  final String currency;
  final DateTime confirmedAt;
  final Map<String, dynamic> details;

  BookingConfirmation({
    required this.confirmationCode,
    required this.vendorBookingId,
    required this.vendorId,
    required this.totalAmountCents,
    required this.currency,
    required this.confirmedAt,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
    'confirmationCode': confirmationCode,
    'vendorBookingId': vendorBookingId,
    'vendorId': vendorId,
    'totalAmountCents': totalAmountCents,
    'currency': currency,
    'confirmedAt': confirmedAt.toIso8601String(),
    'details': details,
  };

  factory BookingConfirmation.fromJson(Map<String, dynamic> json) {
    return BookingConfirmation(
      confirmationCode: json['confirmationCode'],
      vendorBookingId: json['vendorBookingId'],
      vendorId: json['vendorId'],
      totalAmountCents: json['totalAmountCents'],
      currency: json['currency'],
      confirmedAt: DateTime.parse(json['confirmedAt']),
      details: json['details'],
    );
  }
}

/// Comprehensive booking result
class ComprehensiveBookingResult {
  final bool success;
  final String bookingId;
  final String? confirmationCode;
  final String? vendorBookingId;
  final BookingStatus status;
  final int? totalAmountCents;
  final String? currency;
  final String? error;
  final Map<String, dynamic>? details;

  ComprehensiveBookingResult({
    required this.success,
    required this.bookingId,
    this.confirmationCode,
    this.vendorBookingId,
    required this.status,
    this.totalAmountCents,
    this.currency,
    this.error,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'bookingId': bookingId,
    'confirmationCode': confirmationCode,
    'vendorBookingId': vendorBookingId,
    'status': status.toString().split('.').last,
    'totalAmountCents': totalAmountCents,
    'currency': currency,
    'error': error,
    'details': details,
  };

  factory ComprehensiveBookingResult.fromJson(Map<String, dynamic> json) {
    return ComprehensiveBookingResult(
      success: json['success'],
      bookingId: json['bookingId'],
      confirmationCode: json['confirmationCode'],
      vendorBookingId: json['vendorBookingId'],
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      totalAmountCents: json['totalAmountCents'],
      currency: json['currency'],
      error: json['error'],
      details: json['details'],
    );
  }
}

/// Booking modification request
class BookingModificationRequest {
  final BookingModificationType type;
  final String reason;
  final Map<String, dynamic> changes;
  final DateTime requestedAt;

  BookingModificationRequest({
    required this.type,
    required this.reason,
    required this.changes,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'reason': reason,
    'changes': changes,
    'requestedAt': requestedAt.toIso8601String(),
  };

  factory BookingModificationRequest.fromJson(Map<String, dynamic> json) {
    return BookingModificationRequest(
      type: BookingModificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      reason: json['reason'],
      changes: json['changes'],
      requestedAt: DateTime.parse(json['requestedAt']),
    );
  }
}

/// Booking modification result
class BookingModificationResult {
  final bool success;
  final String? modificationId;
  final int? feeCents;
  final Map<String, dynamic>? newDetails;
  final String? error;

  BookingModificationResult({
    required this.success,
    this.modificationId,
    this.feeCents,
    this.newDetails,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'modificationId': modificationId,
    'feeCents': feeCents,
    'newDetails': newDetails,
    'error': error,
  };

  factory BookingModificationResult.fromJson(Map<String, dynamic> json) {
    return BookingModificationResult(
      success: json['success'],
      modificationId: json['modificationId'],
      feeCents: json['feeCents'],
      newDetails: json['newDetails'],
      error: json['error'],
    );
  }
}

/// Booking cancellation result
class BookingCancellationResult {
  final bool success;
  final String? cancellationId;
  final int? refundAmountCents;
  final int? refundPercentage;
  final int? processingDays;
  final String? reason;
  final String? error;

  BookingCancellationResult({
    required this.success,
    this.cancellationId,
    this.refundAmountCents,
    this.refundPercentage,
    this.processingDays,
    this.reason,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'cancellationId': cancellationId,
    'refundAmountCents': refundAmountCents,
    'refundPercentage': refundPercentage,
    'processingDays': processingDays,
    'reason': reason,
    'error': error,
  };

  factory BookingCancellationResult.fromJson(Map<String, dynamic> json) {
    return BookingCancellationResult(
      success: json['success'],
      cancellationId: json['cancellationId'],
      refundAmountCents: json['refundAmountCents'],
      refundPercentage: json['refundPercentage'],
      processingDays: json['processingDays'],
      reason: json['reason'],
      error: json['error'],
    );
  }
}

/// Complete booking details
class BookingDetails {
  final String id;
  final String tripId;
  final String userId;
  final BookingType type;
  final BookingStatus status;
  final BookingRequest request;
  final String? confirmationCode;
  final String? vendorBookingId;
  final String? vendorId;
  final int? totalAmountCents;
  final String? currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VendorReservationResult? reservation;
  final PaymentResult? payment;
  final BookingConfirmation? confirmation;
  final List<BookingModificationRequest>? modifications;
  final BookingCancellationResult? cancellation;
  final String? error;

  BookingDetails({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.type,
    required this.status,
    required this.request,
    this.confirmationCode,
    this.vendorBookingId,
    this.vendorId,
    this.totalAmountCents,
    this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.reservation,
    this.payment,
    this.confirmation,
    this.modifications,
    this.cancellation,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'userId': userId,
    'type': type.toString().split('.').last,
    'status': status.toString().split('.').last,
    'request': request.toJson(),
    'confirmationCode': confirmationCode,
    'vendorBookingId': vendorBookingId,
    'vendorId': vendorId,
    'totalAmountCents': totalAmountCents,
    'currency': currency,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'reservation': reservation?.toJson(),
    'payment': payment?.toJson(),
    'confirmation': confirmation?.toJson(),
    'modifications': modifications?.map((m) => m.toJson()).toList(),
    'cancellation': cancellation?.toJson(),
    'error': error,
  };

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    final type = BookingType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type'],
    );
    final status = BookingStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json['status'],
    );

    return BookingDetails(
      id: json['id'],
      tripId: json['tripId'],
      userId: json['userId'],
      type: type,
      status: status,
      request: BookingRequest.fromJson(json['request']),
      confirmationCode: json['confirmationCode'],
      vendorBookingId: json['vendorBookingId'],
      vendorId: json['vendorId'],
      totalAmountCents: json['totalAmountCents'],
      currency: json['currency'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      reservation: json['reservation'] != null
          ? VendorReservationResult.fromJson(json['reservation'])
          : null,
      payment: json['payment'] != null
          ? PaymentResult.fromJson(json['payment'])
          : null,
      confirmation: json['confirmation'] != null
          ? BookingConfirmation.fromJson(json['confirmation'])
          : null,
      modifications: json['modifications'] != null
          ? (json['modifications'] as List)
                .map((m) => BookingModificationRequest.fromJson(m))
                .toList()
          : null,
      cancellation: json['cancellation'] != null
          ? BookingCancellationResult.fromJson(json['cancellation'])
          : null,
      error: json['error'],
    );
  }
}
