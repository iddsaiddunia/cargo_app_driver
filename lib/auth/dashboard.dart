import 'dart:convert';

import 'package:cargo_app_driver/models/request.dart';
import 'package:cargo_app_driver/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController controller = TextEditingController();
  bool isOnline = true;
  double _distance = 0.0;

  bool isGeocodeSet = false;
  bool _isLoading = false;
  bool isDismissed = false;
  bool isRequestCanceled = false;
  bool isRequestAccepted = false;
  bool isPickedupConfirmed = true;
  LatLng? _currentLatLng;
  LatLng? _destinationLatLng;
  GeoPoint? clientCurrentLocation;
  late Position? _currentPosition;
  GoogleMapController? _mapController;
  late String _mapStyle;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Stream<QuerySnapshot>? _requestsStream;

  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _mapController;
    _currentLatLng ?? LatLng(0, 0);
    rootBundle.loadString('assets/map_style.txt').then((string) {
      _mapStyle = string;
    });

    _requestsStream = FirebaseFirestore.instance
        .collection('Requests')
        .where('driversRequested.${user!.uid}', isGreaterThan: 0)
        .snapshots();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (position.accuracy <= 20) {
          // Filtering out positions with low accuracy
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _currentLatLng = LatLng(position.latitude, position.longitude);
            });
            _mapController?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLatLng!,
                zoom: 15.0,
              ),
            ));
          }
        }
      });
    }
  }

  void acceptRequest(TextEditingController? amountController,
      double? estimatedPrice, String requestId) async {
    setState(() {
      _isLoading = true;
    });

    if (amountController != null) {
      var _parsedValue = int.tryParse(amountController.text);
      if (_parsedValue! < estimatedPrice!) {
        try {
          String driverId = user!.uid;
          DocumentReference requestRef =
              _firestore.collection('Requests').doc(requestId);

          await requestRef.update({
            'driversRequested.$driverId.bidPrice': _parsedValue,
            'driversRequested.$driverId.isSelected': true,
          });
          if (mounted) {
            setState(() {
              isRequestAccepted = true;
              _isLoading = false;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Bid price updated successfully'),
          ));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to update bid price: $e'),
          ));
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inserted amound is greater than estimated amount'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fill your bid amount please!'),
        ),
      );
    }
  }

  Future<void> cancelClientRequest() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    if (isDismissed) {
      if (mounted) {
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Verify Request action'),
              content:
                  const Text('Are you sure you want to cancel this request?'),
              actions: [
                GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        isRequestCanceled = true;
                        Navigator.of(context).pop();
                      });
                    }
                  },
                  child: Container(
                    width: 80.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                        child: Text(
                      "Yes",
                      style: TextStyle(color: Colors.white),
                    )),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 80.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                        child: Text(
                      "No",
                      style: TextStyle(color: Colors.white),
                    )),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Stream<Request?> _fetchCurrentRequestForDriver() {
    String driverId = user!.uid;

    // Timestamp for 5 minutes ago
    Timestamp fiveMinutesAgo = Timestamp.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch - 5 * 60 * 60 * 1000);

    return _firestore
        .collection('Requests')
        .where('requestTime', isGreaterThan: fiveMinutesAgo)
        .orderBy('requestTime', descending: true)
        .snapshots()
        .map((snapshot) {
      final relevantRequests = snapshot.docs.map((doc) {
        return Request.fromDocument(doc);
      }).where((request) {
        return request.driversRequested.containsKey(driverId);
        // return request.driversRequested.containsKey(driverId) &&
        //     request.driversRequested[driverId]['bidPrice'] == 0;
      }).toList();

      if (relevantRequests.isEmpty) {
        return null;
      }

      return relevantRequests.first;
    });
  }

  void _addClientMarker(LatLng clientLatLng) {
    final String markerId = 'client';
    if (!_markers.any((marker) => marker.markerId.value == markerId)) {
      _markers.add(Marker(
        markerId: MarkerId(markerId),
        position: clientLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Client'),
      ));
    }
  }

  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Radius of the Earth in kilometers
    final double dLat = _toRadians(end.latitude - start.latitude);
    final double dLng = _toRadians(end.longitude - start.longitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(start.latitude)) *
            math.cos(_toRadians(end.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  Future<void> _drawRoute(LatLng driverLatLng, GeoPoint? clientGeoPoint) async {
    final LatLng clientLatLng =
        LatLng(clientGeoPoint!.latitude, clientGeoPoint!.longitude);
    final String apiKey = 'AIzaSyAjsJbodhou5nNntMWPdhRsWqz2h1Tgzoc';
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLatLng.latitude},${driverLatLng.longitude}&destination=${clientLatLng.latitude},${clientLatLng.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final polylinePoints = data['routes'][0]['overview_polyline']['points'];
      PolylinePoints polylinePointsDecoder = PolylinePoints();
      List<PointLatLng> result =
          polylinePointsDecoder.decodePolyline(polylinePoints);

      if (result.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ));
        });
      }
    } else {
      throw Exception('Failed to load directions');
    }
  }

  // Future<void> _geocodeDestination(String? destinationAddress) async {
  //   if (destinationAddress == null) {
  //     print('No destination address provided.');
  //     return;
  //   }

  //   try {
  //     // print('Geocoding destination address: $destinationAddress');
  //     List<Location> locations = await locationFromAddress(destinationAddress);
  //     if (locations.isNotEmpty) {
  //       LatLng destinationLatLng = LatLng(
  //         locations.first.latitude,
  //         locations.first.longitude,
  //       );

  //       print('Geocoded destination location: $destinationLatLng');

  //       _markers.add(Marker(
  //         markerId: MarkerId('destination'),
  //         position: destinationLatLng,
  //         icon:
  //             BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  //         infoWindow: InfoWindow(title: 'Destination'),
  //       ));

  //       // Trigger a rebuild to update the map with the new marker
  //       setState(() {});
  //     }
  //   } catch (e) {
  //     print('Geocoding failed: $e');
  //   }
  // }

  Future<void> _geocodeDestination(
      String destination, LatLng driverLatLng) async {
    final String apiKey = 'AIzaSyAjsJbodhou5nNntMWPdhRsWqz2h1Tgzoc';
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(destination)}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final location = data['results'][0]['geometry']['location'];
      final LatLng destinationLatLng = LatLng(location['lat'], location['lng']);

      // Calculate the distance
      double distance = calculateDistance(driverLatLng, destinationLatLng);

      setState(() {
        _destinationLatLng = destinationLatLng;
        // Add the distance to the state
        _distance = distance;
        isGeocodeSet = true;
      });
    } else {
      throw Exception('Failed to geocode destination');
    }
  }

  _confirmRequest(String requestId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      DocumentReference requestRef =
          _firestore.collection('Requests').doc(requestId);

      await requestRef.update({'driverPickup': true}).then((value) => {
            setState(() {
              isPickedupConfirmed = true;
              _isLoading = false;
            })
          });

      print("updated successfully");
    } catch (e) {
      print("failed to update confirmPickup $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const Padding(
          padding: EdgeInsets.all(6.0),
          child: CircleAvatar(
            radius: 7,
          ),
        ),
        actions: [
          (isOnline) ? const Text("Online") : const Text("Offline"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Switch(
              value: isOnline,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    // Update the state of the switch
                    isOnline = value;
                  });
                }
              },
              // Optional: Customize the switch appearance
              activeColor: Colors.blue,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications,
              color: Colors.black45,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            child: (_currentLatLng != null)
                ? GoogleMap(
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _currentLatLng ?? const LatLng(0, 0),
                      zoom: 16.0,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      _mapController!.setMapStyle(_mapStyle);
                      _mapController!.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: _currentLatLng ?? const LatLng(0, 0),
                            zoom: 16,
                          ),
                        ),
                      );
                      _markers.add(
                        Marker(
                          markerId: MarkerId('driver'),
                          position: _currentLatLng!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueBlue),
                          infoWindow: InfoWindow(title: 'Driver'),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
          ),
          StreamBuilder<Request?>(
            stream: _fetchCurrentRequestForDriver(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center();
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: const Text('No current requests found'),
                  ),
                );
              } else {
                var request = snapshot.data!;
                var bidPrice = 0.0;
                var bidPriceValue =
                    request.driversRequested[user?.uid ?? '']['bidPrice'];
                bool isSelected =
                    request.driversRequested[user?.uid ?? '']['isSelected'];
                if (bidPriceValue is int) {
                  bidPrice = bidPriceValue.toDouble();
                } else if (bidPriceValue is double) {
                  bidPrice = bidPriceValue;
                }

                // Add client marker
                LatLng clientLatLng = LatLng(
                  request.clientCurrentLocation!.latitude,
                  request.clientCurrentLocation!.longitude,
                );

                // Call the _geocodeDestination function to add the destination marker
                if (isGeocodeSet == false) {
                  _geocodeDestination(request.destination, _currentLatLng!);
                } else {
                  print("problem in destination location ----------->");
                }
                // Draw polyline
                if (_currentLatLng != null &&
                    _polylines.isEmpty &&
                    isPickedupConfirmed == false) {
                  _drawRoute(_currentLatLng!, request.clientCurrentLocation);
                  print("heloo ==========>");
                } else if (_currentLatLng != null &&
                    _polylines.isEmpty &&
                    isPickedupConfirmed == true) {
                  _drawRoute(
                      _currentLatLng!,
                      GeoPoint(_destinationLatLng!.latitude,
                          _destinationLatLng!.longitude));
                }

                _markers.add(Marker(
                  markerId: MarkerId('client'),
                  position: clientLatLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(title: 'Client'),
                ));

                _markers.add(Marker(
                  markerId: MarkerId('destination'),
                  position: _destinationLatLng!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(title: 'Destination'),
                ));

                return DraggableScrollableSheet(
                  initialChildSize:
                      0.2, // Initial size of the sheet (30% of the screen)
                  minChildSize:
                      0.2, // Minimum size of the sheet (10% of the screen)
                  maxChildSize:
                      0.8, // Maximum size of the sheet (80% of the screen)
                  builder: (BuildContext context,
                      ScrollController scrollController) {
                    return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Allen Swai",
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              "Client",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  (isSelected)
                                      ? Container(
                                          width: 35,
                                          height: 35,
                                          decoration: const BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(35),
                                            ),
                                            color: Colors.blue,
                                          ),
                                          child: const Icon(
                                            Icons.phone,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              (!isSelected)
                                  ? Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  const Text("Package type"),
                                                  Text(request.packageType,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ]),
                                            Column(children: [
                                              const Text("Transport"),
                                              Text(
                                                '${request.packageSize} ',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ])
                                          ],
                                        ),
                                        const Divider(),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  const Text("Destination"),
                                                  Text(request.destination,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ]),
                                          ],
                                        ),
                                        Divider(),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("Bid Price"),
                                              Text(
                                                '${request.estimatedPrice.toStringAsFixed(1)} Tsh',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ]),
                                        Divider(),
                                        Column(
                                          children: [
                                            const Text("Distance (Kilometer)"),
                                            Text(
                                              '${_distance.toStringAsFixed(1)}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        Divider(),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        (request.pictureUrl == null)
                                            ? Text("Loading image...")
                                            : Image.network(
                                                "${request.pictureUrl}"),
                                        const SizedBox(height: 10),
                                        const SizedBox(height: 10),
                                        TextField(
                                          controller: controller,
                                          onTap: () {},
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.zero,
                                            // prefixIcon: const Icon(Icons.location_on),
                                            hintText:
                                                "Enter Bid price upto ${request.estimatedPrice.toString()}",
                                            hintStyle: TextStyle(fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    )
                                  : SizedBox(),
                              const SizedBox(height: 10),
                              (!isSelected)
                                  ? CustomePrimaryButton(
                                      title: "Accept Request",
                                      press: () {
                                        acceptRequest(controller,
                                            request.estimatedPrice, request.id);
                                      },
                                      isWithOnlyBorder: false,
                                      isLoading: _isLoading)
                                  : CustomePrimaryButton(
                                      title: (_isLoading)
                                          ? "wait..."
                                          : "Confirm Pickup",
                                      press: () {
                                        _confirmRequest(request.id);
                                      },
                                      isWithOnlyBorder: false,
                                      isLoading: false),
                              const SizedBox(
                                height: 5,
                              ),
                              Center(
                                child: isRequestCanceled
                                    ? const Text(
                                        'Request Canceled',
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.red),
                                      )
                                    : Dismissible(
                                        key: UniqueKey(),
                                        direction: DismissDirection.horizontal,
                                        onDismissed: (direction) {
                                          // Handle the dismissal action
                                          if (mounted) {
                                            setState(() {
                                              isDismissed = true;
                                              cancelClientRequest();
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          child: const Text(
                                            'Swipe to cancel!',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        // Customize the background and secondaryBackground
                                        background: Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: const Icon(
                                            Icons.cancel,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        secondaryBackground: Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: const Icon(
                                            Icons.cancel,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ));
                  },
                );
              }
            },
          )
        ],
      ),
    );
  }
}
