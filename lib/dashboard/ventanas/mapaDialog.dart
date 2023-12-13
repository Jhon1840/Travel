import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaRutas extends StatelessWidget {
  final List<dynamic> places;

  MapaRutas({required this.places});

  @override
  Widget build(BuildContext context) {
    List<LatLng> routePoints = [];
    for (var placeData in places) {
      double lat = placeData['latitude'];
      double lng = placeData['longitude'];
      routePoints.add(LatLng(lat, lng));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Ruta'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: routePoints.isNotEmpty ? routePoints.first : LatLng(0, 0),
          zoom: 10.0,
        ),
        markers: Set<Marker>.from(routePoints.map((point) => Marker(
              markerId: MarkerId(point.toString()),
              position: point,
            ))),
        polylines: {
          Polyline(
            polylineId: PolylineId('ruta'),
            color: Colors.blue,
            points: routePoints,
          ),
        },
      ),
    );
  }
}
