import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Mapa extends StatefulWidget {
  const Mapa({Key? key}) : super(key: key);

  @override
  State<Mapa> createState() => _MapaState();
}

final TextEditingController _searchController = TextEditingController();

class _MapaState extends State<Mapa> {
  final Set<Marker> _markers = {};
  late GoogleMapController _googleMapController;
  LatLng _currentLocation = const LatLng(0, 0);

  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;
  }

  void _updateLocation(LatLng newLocation) {
    setState(() {
      _currentLocation = newLocation;
      _googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation, zoom: 16),
        ),
      );
    });
  }

  void _handleSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      return;
    }

    // Reemplaza 'YOUR_API_KEY' con tu clave de API de Google Places
    final response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$query&inputtype=textquery&fields=geometry&key=AIzaSyBdFXxgKsFAkdxB5fFhraxnDRkWlYshK3s'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final location = data['candidates'][0]['geometry']['location'];
        _updateLocation(LatLng(location['lat'], location['lng']));
      } else {
        print('No se encontraron lugares');
      }
    } else {
      print('Falló la solicitud: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            markers: _markers,
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 2,
            ),
          ),
          Positioned(
            top: 50.0,
            left: 15.0,
            right: 15.0,
            child: Container(
              height: 50.0,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(left: 15.0, top: 15.0),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _handleSearch,
                    iconSize: 30.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
