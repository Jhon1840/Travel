import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_travel/dashboard/ventanas/map/viaje.dart';
import 'package:flutter_travel/dashboard/ventanas/ruta/crearRuta.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class Rutas extends StatefulWidget {
  const Rutas({Key? key}) : super(key: key);

  @override
  State<Rutas> createState() => _RutasState();
}

class _RutasState extends State<Rutas> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser; // Obtiene el usuario actual
    String userEmail = currentUser?.email ?? '';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Tus rutas'),
          backgroundColor: Colors.deepPurple,
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('rutas')
              .where('user',
                  isEqualTo:
                      userEmail) // Filtra las rutas por el email del usuario
              .get(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Algo salió mal'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No tienes rutas'));
            }

            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(data['routeName']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(
                                      'Editar lugares en ${data['routeName']}'),
                                  content: Container(
                                    height: 400,
                                    width: 300,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 200,
                                            width: double.infinity,
                                            child: FutureBuilder<Widget>(
                                              future: _buildMap(data[
                                                  'places']), // La función _buildMap ahora devuelve un Future<Widget>
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<Widget>
                                                      snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  // Muestra un indicador de carga mientras esperas
                                                  return Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                } else if (snapshot.hasError) {
                                                  // Puedes manejar errores aquí si lo deseas
                                                  return Center(
                                                      child: Text(
                                                          'Error al cargar el mapa'));
                                                } else {
                                                  // Cuando el Future se completa, muestra el widget del mapa
                                                  return snapshot.data!;
                                                }
                                              },
                                            ),
                                          ),
                                          ...data['places']
                                              .map<Widget>((placeData) {
                                            return Card(
                                              child: ListTile(
                                                title: Text(
                                                    'Lugar: ${placeData['place']}'),
                                                subtitle: Text(
                                                    'Usuario: ${placeData['user']}'),
                                                trailing: IconButton(
                                                  icon: Icon(Icons.delete),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          title: Text(
                                                              'Confirmación'),
                                                          content: Text(
                                                              '¿Estás seguro de que quieres eliminar este lugar?'),
                                                          actions: <Widget>[
                                                            TextButton(
                                                              child: Text(
                                                                  'Cancelar'),
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                            ),
                                                            TextButton(
                                                              child: Text(
                                                                  'Eliminar'),
                                                              onPressed:
                                                                  () async {
                                                                // Obtener el índice del lugar que quieres eliminar
                                                                int index = data[
                                                                        'places']
                                                                    .indexWhere((place) =>
                                                                        place ==
                                                                        placeData);

                                                                // Crear una nueva lista que contenga todos los lugares excepto el que quieres eliminar
                                                                List<dynamic>
                                                                    newPlaces =
                                                                    List.from(data[
                                                                        'places']);
                                                                newPlaces.removeAt(
                                                                    index); // Asegúrate de tener el índice correcto del lugar que quieres eliminar

                                                                // Actualizar el documento en Firebase con la nueva lista
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'rutas')
                                                                    .doc(
                                                                        document
                                                                            .id)
                                                                    .update({
                                                                  'places':
                                                                      newPlaces
                                                                });

                                                                // Cerrar el diálogo de alerta
                                                                Navigator.pop(
                                                                    context);

                                                                // Actualizar la interfaz de usuario
                                                                setState(() {
                                                                  _buildMap(
                                                                      newPlaces);
                                                                });
                                                              },
                                                            )
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () {
                            if (data['routeName'] != null &&
                                data['user'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Viaje(
                                      routeName: data['routeName'],
                                      user: data['user']),
                                ),
                              );
                            } else {
                              // Manejar el caso en que los datos son null
                              print('Los datos de routeName o user son null');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CrearRuta(ciudad: 'Santa Cruz de la Sierra'),
              ),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.deepPurple,
        ),
      ),
    );
  }

  Future<Widget> _buildMap(List<dynamic> places) async {
    List<LatLng> routePoints = [];
    Set<Marker> markers = {};
    Set<Polyline> polylines = {};

    // Añadir marcadores para cada lugar
    for (var placeData in places) {
      var location = placeData['location'];
      double lat = location['lat'];
      double lng = location['lng'];
      LatLng point = LatLng(lat, lng);
      routePoints.add(point);

      markers.add(Marker(
        markerId: MarkerId(placeData['place']),
        position: point,
        infoWindow: InfoWindow(title: placeData['place']),
      ));
    }

    // Obtener la ruta entre los puntos que sigue calles y carreteras
    for (int i = 0; i < routePoints.length - 1; i++) {
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${routePoints[i].latitude},${routePoints[i].longitude}&destination=${routePoints[i + 1].latitude},${routePoints[i + 1].longitude}&key=AIzaSyDyT3GTnOOvYx5EJQe2B6lV4WjbXaoKUDY";
      http.Response response = await http.get(Uri.parse(url));
      Map values = jsonDecode(response.body);
      if (values['routes'].isNotEmpty) {
        List<LatLng> routeCoords =
            _decodePoly(values["routes"][0]["overview_polyline"]["points"]);
        polylines.add(Polyline(
          polylineId: PolylineId('route$i'),
          visible: true,
          points: routeCoords,
          width: 5,
          color: Colors.blue,
        ));
      }
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: routePoints.isNotEmpty ? routePoints.first : LatLng(0, 0),
        zoom: 14.0,
      ),
      markers: markers,
      polylines: polylines,
    );
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
}
