import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id;
  final GeoPoint? clientCurrentLocation;
  final String destination;
  final Map<String, dynamic> driversRequested;
  final double estimatedPrice;
  final bool isPickedUp;
  final String packageSize;
  final String packageType;
  final String pictureUrl;
  final Timestamp requestTime;
  final String userId;

  Request({
    required this.id,
    required this.clientCurrentLocation,
    required this.destination,
    required this.driversRequested,
    required this.estimatedPrice,
    required this.isPickedUp,
    required this.packageSize,
    required this.packageType,
    required this.pictureUrl,
    required this.requestTime,
    required this.userId,
  });

  factory Request.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Request(
      id: doc.id,
      clientCurrentLocation: data['clientCurrentLocation'] as GeoPoint?,
      destination: data['destination'],
      driversRequested: data['driversRequested'],
      estimatedPrice: data['estimatedPrice'],
      isPickedUp: data['isPickedUp'],
      packageSize: data['packageSize'],
      packageType: data['packageType'],
      pictureUrl: data['pictureUrl'],
      requestTime: data['requestTime'],
      userId: data['userId'],
    );
  }
}







