import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart' as loc;

class Viaje extends StatefulWidget {
  final String routeName;
  final String user;

  const Viaje({
    Key? key,
    required this.routeName,
    required this.user,
  }) : super(key: key);

  @override
  State<Viaje> createState() => _ViajeState();
}

class _ViajeState extends State<Viaje> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  loc.LocationData? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getRouteData();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    var location = loc.Location();
    try {
      _currentLocation = await location.getLocation();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getRouteData() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('rutas')
        .where('routeName', isEqualTo: widget.routeName)
        .where('user', isEqualTo: widget.user)
        .get();

    List<dynamic> places = snapshot.docs.first.data()['places'];

    for (int i = 0; i < places.length - 1; i++) {
      Map<String, dynamic> startLocation = places[i]['location'];
      Map<String, dynamic> destinationLocation = places[i + 1]['location'];
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${startLocation['lat']},${startLocation['lng']}&destination=${destinationLocation['lat']},${destinationLocation['lng']}&key=AIzaSyDyT3GTnOOvYx5EJQe2B6lV4WjbXaoKUDY";
      http.Response response = await http.get(Uri.parse(url));
      Map values = jsonDecode(response.body);
      if (values['status'] == 'OK') {
        List<LatLng> routeCoords =
            _decodePoly(values["routes"][0]["overview_polyline"]["points"]);
        _polylines.add(Polyline(
          polylineId: PolylineId('route$i'),
          visible: true,
          points: routeCoords,
          width: 5,
          color: Colors.blue,
        ));
      }
    }

    for (int i = 0; i < places.length; i++) {
      Map<String, dynamic> location = places[i]['location'];
      _markers.add(Marker(
        markerId: MarkerId(places[i]['place']),
        position: LatLng(location['lat'], location['lng']),
        infoWindow: InfoWindow(title: places[i]['place']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }

    return poly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Viaje'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation != null
                    ? LatLng(
                        _currentLocation!.latitude!,
                        _currentLocation!.longitude!,
                      )
                    : _markers.isNotEmpty
                        ? _markers.first.position
                        : LatLng(0, 0),
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
