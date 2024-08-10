import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapPagez extends StatefulWidget {
  // static const routeName = '/gps_trz';
  const MapPagez({super.key});

  @override
  State<MapPagez> createState() => _MapPageState();
}

class _MapPageState extends State<MapPagez> {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
  Completer<GoogleMapController>();
  LatLng auca = LatLng(-1.9559108004325798, 30.10410700070383);

  static const LatLng _pGooglePlex = LatLng(37.4223, -122.0848);
  static const LatLng _pApplePark = LatLng(37.3346, -122.0090);
  LatLng? _currentP;
  Map<PolylineId, Polyline> polylines = {};
  Map<PolygonId, Polygon> _polygons = {};
  StreamSubscription<LocationData>? _locationSubscription;
  bool _notificationSentOutSide = false;
  bool _notificationSentInSide = false;

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then(
          (_) => {
        getPolylinePoints().then((coordinates) => {
          generatePolyLineFromPoints(coordinates),
        }),
      },
    );
    _createGeofence();
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  @override
  void dispose() {
    _locationSubscription?.cancel(); // Cancel location updates subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          'Your Location',
          style: TextStyle(color: theme.primaryColor),
        ),
        iconTheme: IconThemeData(
          color: theme.primaryColor,
        ),
      ),
      body: _currentP == null
          ? const Center(
        child: Text("Loading..."),
      )
          : GoogleMap(
        onMapCreated: ((GoogleMapController controller) =>
            _mapController.complete(controller)),
        initialCameraPosition: CameraPosition(
          target: auca,
          zoom: 13.0,
        ),
        polygons: Set<Polygon>.of(_polygons.values),
        markers: {
          Marker(
            markerId: MarkerId("_currentLocation"),
            icon: BitmapDescriptor.defaultMarker,
            position: _currentP!,
          ),
          Marker(
              markerId: MarkerId("_sourceLocation"),
              icon: BitmapDescriptor.defaultMarker,
              position: _pGooglePlex),
          Marker(
              markerId: MarkerId("_destionationLocation"),
              icon: BitmapDescriptor.defaultMarker,
              position: _pApplePark)
        },
        polylines: Set<Polyline>.of(polylines.values),
      ),
    );
  }

  void _triggerInSideNotification() async {
    if (!_notificationSentInSide) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'Map_channel',
        'Map Notifications', // Replace with your own channel name
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Inside',
        'Inside Geographical Boundaries of Auca',
        platformChannelSpecifics,
      );
      print('Inside geofence notification sent');
      _notificationSentInSide = true;
      _notificationSentOutSide = false;
    }
  }

  void _triggerOutSideNotification() async {
    if (!_notificationSentOutSide) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'Map_channel',
        'Map Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Outside',
        'Geographical Boundaries of Auca',
        platformChannelSpecifics,
      );
      print('Outside geofence notification sent');
      _notificationSentOutSide = true;
      _notificationSentInSide = false;
    }
  }

  void _createGeofence() {
    List<LatLng> aucaBoundaries = [
      const LatLng(-1.9538248388462212, 30.105851228738512),
      const LatLng(-1.956926751441857, 30.10683695947351),
      const LatLng(-1.9588171846308653, 30.102507736650878),
      const LatLng(-1.9552493230247774, 30.10150868523027),
    ];

    // Create a polygon to represent the geofence boundaries
    PolygonId polygonId = PolygonId('AUCA');
    Polygon polygon = Polygon(
      polygonId: polygonId,
      points: aucaBoundaries,
      strokeWidth: 2,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.3),
    );

    // Add the polygon to the map
    setState(() {
      _polygons[polygonId] = polygon;
    });

    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    _locationSubscription = _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      bool insideGeofence = _isLocationInsideGeofence(
          currentLocation.latitude!, currentLocation.longitude!);

      if (insideGeofence && !_notificationSentInSide) {
        _triggerInSideNotification();
        _notificationSentInSide = true;
        _notificationSentOutSide = false;
      } else if (!insideGeofence && !_notificationSentOutSide) {
        _triggerOutSideNotification();
        _notificationSentOutSide = true;
        _notificationSentInSide = false;
      }
    });
  }

  bool _isLocationInsideGeofence(double latitude, double longitude) {
    bool isInside = false;

    List<LatLng> homeBoundaries = [
      const LatLng(-1.916783, 30.076337),
      const LatLng(-1.916783, 30.079929),
      const LatLng(-1.920375, 30.076337),
      const LatLng(-1.920375, 30.079929),
    ];

    List<LatLng> aucaBoundaries = [
      const LatLng(-1.9538248388462212, 30.105851228738512),
      const LatLng(-1.956926751441857, 30.10683695947351),
      const LatLng(-1.9588171846308653, 30.102507736650878),
      const LatLng(-1.9552493230247774, 30.10150868523027),
    ];

    // Algorithm to determine if a point is inside a polygon
    int i, j = aucaBoundaries.length - 1;
    for (i = 0; i < aucaBoundaries.length; i++) {
      if ((aucaBoundaries[i].latitude < latitude &&
          aucaBoundaries[j].latitude >= latitude ||
          aucaBoundaries[j].latitude < latitude &&
              aucaBoundaries[i].latitude >= latitude) &&
          (aucaBoundaries[i].longitude <= longitude ||
              aucaBoundaries[j].longitude <= longitude)) {
        if (aucaBoundaries[i].longitude +
            (latitude - aucaBoundaries[i].latitude) /
                (aucaBoundaries[j].latitude - aucaBoundaries[i].latitude) *
                (aucaBoundaries[j].longitude -
                    aucaBoundaries[i].longitude) <
            longitude) {
          isInside = !isInside;
        }
      }
      j = i;
    }
    return isInside;
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: await controller.getZoomLevel(), // Keep the current zoom level
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationSubscription = _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        LatLng newLocation =
        LatLng(currentLocation.latitude!, currentLocation.longitude!);

        // Update the marker to the new location
        updateMarkerAndCircle(newLocation);

        // Optionally, keep track of the path by adding to your polyline
        addLocationToPolyline(newLocation);

        _cameraToPosition(newLocation);
      }
    });
  }

  void updateMarkerAndCircle(LatLng newLocation) {
    setState(() {
      _currentP = newLocation;
      // Update your marker or create a new one if needed
    });
  }

  void addLocationToPolyline(LatLng newLocation) {
    setState(() {
      // Check if polyline exists, if not create one
      if (polylines.containsKey(PolylineId("path"))) {
        final polyline = polylines[PolylineId("path")]!;
        final updatedPoints = List<LatLng>.from(polyline.points)
          ..add(newLocation);
        polylines[PolylineId("path")] =
            polyline.copyWith(pointsParam: updatedPoints);
      } else {
        // Create new polyline if it doesn't exist
        polylines[PolylineId("path")] = Polyline(
          polylineId: PolylineId("path"),
          color: Colors.blue,
          points: [newLocation],
          width: 5,
        );
      }
    });
  }

  static const String GOOGLE_MAPS_API_KEY =
      "AIzaSyDFNXP5T7xgH6z0E5_BjuCYwBoiSJjLZzE";

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_MAPS_API_KEY,

          PointLatLng(_pGooglePlex.latitude, _pGooglePlex.longitude),
           PointLatLng(_pApplePark.latitude, _pApplePark.longitude),
          travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.black,
        points: polylineCoordinates,
        width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }
}

// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:geofence_service/geofence_service.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
//
// class ExampleApp extends StatefulWidget {
//   const ExampleApp({Key? key}) : super(key: key);
//
//   @override
//   State<StatefulWidget> createState() => _ExampleAppState();
// }
//
// class _ExampleAppState extends State<ExampleApp> {
//   final _activityStreamController = StreamController<Activity>();
//   final _geofenceStreamController = StreamController<Geofence>();
//   final _locationStreamController = StreamController<Location>();
//
//   final _geofenceService = GeofenceService.instance.setup(
//     interval: 5000,
//     accuracy: 100,
//     loiteringDelayMs: 60000,
//     statusChangeDelayMs: 10000,
//     useActivityRecognition: true,
//     allowMockLocations: false,
//     printDevLog: false,
//     geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
//   );
//
//   final _geofenceList = <Geofence>[
//     Geofence(
//       id: 'place_1',
//       latitude: 35.103422,
//       longitude: 129.036023,
//       radius: [
//         GeofenceRadius(id: 'radius_100m', length: 100),
//         GeofenceRadius(id: 'radius_25m', length: 25),
//         GeofenceRadius(id: 'radius_250m', length: 250),
//         GeofenceRadius(id: 'radius_200m', length: 200),
//       ],
//     ),
//     Geofence(
//       id: 'place_2',
//       latitude: 35.104971,
//       longitude: 129.034851,
//       radius: [
//         GeofenceRadius(id: 'radius_25m', length: 25),
//         GeofenceRadius(id: 'radius_100m', length: 100),
//         GeofenceRadius(id: 'radius_200m', length: 200),
//       ],
//     ),
//   ];
//
//   late GoogleMapController _mapController;
//   LatLng _currentLocation = const LatLng(35.103422, 129.036023);
//
//   Future<void> _onGeofenceStatusChanged(
//       Geofence geofence,
//       GeofenceRadius geofenceRadius,
//       GeofenceStatus geofenceStatus,
//       Location location) async {
//     print('geofence: ${geofence.toJson()}');
//     print('geofenceRadius: ${geofenceRadius.toJson()}');
//     print('geofenceStatus: ${geofenceStatus.toString()}');
//     _geofenceStreamController.sink.add(geofence);
//   }
//
//   void _onActivityChanged(Activity prevActivity, Activity currActivity) {
//     print('prevActivity: ${prevActivity.toJson()}');
//     print('currActivity: ${currActivity.toJson()}');
//     _activityStreamController.sink.add(currActivity);
//   }
//
//   void _onLocationChanged(Location location) {
//     print('location: ${location.toJson()}');
//     setState(() {
//       _currentLocation = LatLng(location.latitude, location.longitude);
//     });
//     _locationStreamController.sink.add(location);
//     _mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
//   }
//
//   void _onLocationServicesStatusChanged(bool status) {
//     print('isLocationServicesEnabled: $status');
//   }
//
//   void _onError(error) {
//     final errorCode = getErrorCodesFromError(error);
//     if (errorCode == null) {
//       print('Undefined error: $error');
//       return;
//     }
//
//     print('ErrorCode: $errorCode');
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _geofenceService
//           .addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
//       _geofenceService.addLocationChangeListener(_onLocationChanged);
//       _geofenceService.addLocationServicesStatusChangeListener(
//           _onLocationServicesStatusChanged);
//       _geofenceService.addActivityChangeListener(_onActivityChanged);
//       _geofenceService.addStreamErrorListener(_onError);
//       _geofenceService.start(_geofenceList).catchError(_onError);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Geofence Service'),
//           centerTitle: true,
//         ),
//         body: _buildContentView(),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _activityStreamController.close();
//     _geofenceStreamController.close();
//     _locationStreamController.close();
//     super.dispose();
//   }
//
//   Widget _buildContentView() {
//     return Column(
//       children: [
//         Expanded(
//           flex: 3,
//           child: GoogleMap(
//             onMapCreated: (controller) {
//               _mapController = controller;
//             },
//             initialCameraPosition: CameraPosition(
//               target: _currentLocation,
//               zoom: 15,
//             ),
//             markers: _buildMarkers(),
//           ),
//         ),
//         Expanded(
//           flex: 2,
//           child: ListView(
//             physics: const BouncingScrollPhysics(),
//             padding: const EdgeInsets.all(8.0),
//             children: [
//               _buildActivityMonitor(),
//               const SizedBox(height: 20.0),
//               _buildGeofenceMonitor(),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Set<Marker> _buildMarkers() {
//     return {
//       Marker(
//         markerId: const MarkerId('current_location'),
//         position: _currentLocation,
//         infoWindow: const InfoWindow(title: 'Current Location'),
//       ),
//     };
//   }
//
//   Widget _buildActivityMonitor() {
//     return StreamBuilder<Activity>(
//       stream: _activityStreamController.stream,
//       builder: (context, snapshot) {
//         final updatedDateTime = DateTime.now();
//         final content = snapshot.data?.toJson().toString() ?? '';
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('•\t\tActivity (updated: $updatedDateTime)'),
//             const SizedBox(height: 10.0),
//             Text(content),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildGeofenceMonitor() {
//     return StreamBuilder<Geofence>(
//       stream: _geofenceStreamController.stream,
//       builder: (context, snapshot) {
//         final updatedDateTime = DateTime.now();
//         final content = snapshot.data?.toJson().toString() ?? '';
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('•\t\tGeofence (updated: $updatedDateTime)'),
//             const SizedBox(height: 10.0),
//             Text(content),
//           ],
//         );
//       },
//     );
//   }
// }