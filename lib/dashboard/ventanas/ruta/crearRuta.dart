import 'package:flutter/material.dart';
import 'package:flutter_travel/dashboard/ventanas/Ruta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CrearRuta extends StatefulWidget {
  final String ciudad;

  const CrearRuta({Key? key, required this.ciudad}) : super(key: key);

  @override
  State<CrearRuta> createState() => _CrearRutaState();
}

class _CrearRutaState extends State<CrearRuta> {
  late final String ciudad;
  int counter = 0;
  List<dynamic> places = [];
  List<bool> favorite = [];
  List<dynamic> savedPlaces = [];
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    final response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=tourist+attractions+in+${widget.ciudad}&language=es&key=AIzaSyDyT3GTnOOvYx5EJQe2B6lV4WjbXaoKUDY'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        places = data['results'];
        places.sort((a, b) => b['rating'].compareTo(a['rating']));
        favorite = List.filled(places.length, false);
      });
      checkFavorites();
    } else {
      throw Exception('Failed to load places');
    }
  }

  Future<void> checkFavorites() async {
    for (int i = 0; i < places.length; i++) {
      final snapshot = await firestore
          .collection('favoritos')
          .where('user', isEqualTo: auth.currentUser!.email)
          .where('place', isEqualTo: places[i]['name'])
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          favorite[i] = true;
        });
      }
    }
  }

  void toggleFavorite(int index) async {
    setState(() {
      favorite[index] = !favorite[index];
    });

    if (favorite[index]) {
      // Añadir a favoritos en Firebase
      firestore.collection('favoritos').add({
        'user': auth.currentUser!.email,
        'place': places[index]['name'],
      });
    } else {
      // Eliminar de favoritos en Firebase
      final snapshot = await firestore
          .collection('favoritos')
          .where('user', isEqualTo: auth.currentUser!.email)
          .where('place', isEqualTo: places[index]['name'])
          .get();

      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    }
  }

  void addToSavedPlaces(int index) {
    final place = places[index];
    setState(() {
      savedPlaces.add({
        'user': auth.currentUser!.email,
        'place': place['name'],
        'location': place['geometry']['location'],
        'id': counter,
      });
      counter++;
    });

    // Opcional: mostrar un mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${place['name']} añadido a rutas guardadas')),
    );
  }

  void showRouteDialog() {
    if (savedPlaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay lugares guardados en la ruta')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        Set<Marker> markers = {};
        Set<Polyline> polylines = {};
        List<LatLng> routePoints = [];

        for (var place in savedPlaces) {
          LatLng location =
              LatLng(place['location']['lat'], place['location']['lng']);
          routePoints.add(location);
          markers.add(
            Marker(
              markerId: MarkerId(place['place']),
              position: location,
            ),
          );
        }

        if (routePoints.length > 1) {
          polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              points: routePoints,
              color: Colors.blue,
              width: 5,
            ),
          );
        }

        return AlertDialog(
          title: Text('Ruta Planeada'),
          content: Container(
            height: 300,
            width: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: routePoints[0],
                zoom: 12,
              ),
              markers: markers,
              polylines: polylines,
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
                Navigator.of(context).pop();
                promptRouteName();
              },
            ),
          ],
        );
      },
    );
  }

  void promptRouteName() {
    showDialog(
      context: context,
      builder: (context) {
        String routeName = '';
        return AlertDialog(
          title: Text('Guardar ruta'),
          content: TextField(
            onChanged: (value) => routeName = value,
            decoration: InputDecoration(hintText: "Nombre de la ruta"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Guardar'),
              onPressed: () {
                Navigator.of(context).pop();
                createRoute(
                    routeName); // Espera a que se complete la operación de crear la ruta
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) =>
                          Rutas()), // Navega a la nueva pantalla
                );
              },
            ),
          ],
        );
      },
    );
  }

  void showMapDialog(BuildContext context, int index) {
    final place = places[index];
    final location = place['geometry']['location'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(place['name']),
          content: Container(
            height: 300,
            width: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(location['lat'], location['lng']),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(place['place_id']),
                  position: LatLng(location['lat'], location['lng']),
                ),
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cerrar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void createRoute(String routeName) {
    firestore.collection('rutas').add({
      'user': auth.currentUser!.email,
      'places': savedPlaces,
      'routeName': routeName,
    });

    savedPlaces.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lugares turísticos en ${widget.ciudad}'),
      ),
      body: ListView.builder(
        itemCount: places.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 5,
            margin: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(places[index]['icon']),
                  ),
                  title: Text(places[index]['name']),
                  subtitle: Text('Rating: ${places[index]['rating']}'),
                  onTap: () => showMapDialog(context, index),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        favorite[index]
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: favorite[index] ? Colors.red : null,
                      ),
                      onPressed: () => toggleFavorite(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => addToSavedPlaces(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.map),
                      onPressed: () => showMapDialog(context, index),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showRouteDialog,
        child: Icon(Icons.map),
      ),
    );
  }
}
