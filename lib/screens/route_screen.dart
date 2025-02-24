import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class RouteScreen extends StatefulWidget {
  final String latitude;
  final String longitude;
  const RouteScreen(
      {super.key, required this.latitude, required this.longitude});
  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  GoogleMapController? _mapController;
  final Location _location = Location();
  LatLng? _currentLocation;
  late final LatLng _destination;
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];
  final PolylinePoints _polylinePoints = PolylinePoints();
  final String _googleAPIKey = 'AIzaSyDLcwxUggpPZo8lcbH0TB4Crq5SJjtj4ag';
  @override
  void initState() {
    super.initState();
    _destination =
        LatLng(double.parse(widget.latitude), double.parse(widget.longitude));
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    LocationData locationData = await _location.getLocation();
    setState(() {
      _currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 14.0),
        );
      }
    });
  }

  void _drawRoute() async {
    if (_currentLocation == null) return;
    PolylineRequest request = PolylineRequest(
      origin:
          PointLatLng(_currentLocation!.latitude, _currentLocation!.longitude),
      destination: PointLatLng(_destination.latitude, _destination.longitude),
      mode: TravelMode.driving,
    );
    PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: _googleAPIKey,
      request: request,
    );
    if (result.points.isNotEmpty) {
      setState(() {
        _polylineCoordinates.clear();
        for (var point in result.points) {
          _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ),
        );
      });
    } else {
      print('Error fetching route: ${result.errorMessage}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route to Destination'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? LatLng(0, 0),
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation!, 14.0),
                );
              }
            },
            myLocationEnabled: true,
            markers: {
              if (_currentLocation != null)
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: _currentLocation!,
                  infoWindow: const InfoWindow(title: 'Current Location'),
                ),
              Marker(
                markerId: const MarkerId('destination'),
                position: _destination,
                infoWindow: const InfoWindow(title: 'Destination'),
              ),
            },
            polylines: _polylines,
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _drawRoute,
              child: const Icon(Icons.location_on),
            ),
          ),
        ],
      ),
    );
  }
}
