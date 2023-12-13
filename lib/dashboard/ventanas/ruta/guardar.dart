import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaRutaDialog extends StatefulWidget {
  final List<dynamic> savedPlaces;
  final Function onAccept;

  const MapaRutaDialog({
    Key? key,
    required this.savedPlaces,
    required this.onAccept,
  }) : super(key: key);

  @override
  _MapaRutaDialogState createState() => _MapaRutaDialogState();
}

class _MapaRutaDialogState extends State<MapaRutaDialog> {
  Set<Polyline> _polylines = Set<Polyline>();
  Set<Marker> _markers = Set<Marker>(); // Conjunto de marcadores
  List<LatLng> _routeCoordinates = [];

  @override
  void initState() {
    super.initState();
    _createRoute();
  }

  void _createRoute() {
    widget.savedPlaces.asMap().forEach((index, place) {
      final location = place['location'];
      final latLng = LatLng(location['lat'], location['lng']);
      _routeCoordinates.add(latLng);

      // Añadir marcador por cada lugar
      _markers.add(Marker(
        markerId: MarkerId('marker_$index'),
        position: latLng,
        infoWindow:
            InfoWindow(title: place['name']), // Opcional: título del marcador
      ));
    });

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('ruta'),
        visible: true,
        points: _routeCoordinates,
        color: Colors.blue,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirmar Ruta'),
      content: Container(
        height: 400,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _routeCoordinates.first,
            zoom: 12,
          ),
          polylines: _polylines,
          markers: _markers, // Añadir marcadores al mapa
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancelar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Aceptar'),
          onPressed: () {
            Navigator.of(context).pop(); // Cierra el diálogo del mapa
            widget.onAccept(); // Llama al diálogo para guardar la ruta
          },
        ),
      ],
    );
  }
}
