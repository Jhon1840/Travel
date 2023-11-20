import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=tourist+attractions+in+${widget.ciudad}&key=AIzaSyBdFXxgKsFAkdxB5fFhraxnDRkWlYshK3s'),
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
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(places[index]['icon']),
              ),
              title: Text(places[index]['name']),
              subtitle: Text('Rating: ${places[index]['rating']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      favorite[index] ? Icons.favorite : Icons.favorite_border,
                      color: favorite[index] ? Colors.red : null,
                    ),
                    onPressed: () async {
                      setState(() {
                        favorite[index] = !favorite[index];
                      });
                      // Implementar lógica para añadir a favoritos en Firebase
                      if (favorite[index]) {
                        firestore.collection('favoritos').add({
                          'user': auth.currentUser!.email,
                          'place': places[index]['name'],
                        });
                      } else {
                        // Implementar lógica para eliminar de favoritos en Firebase
                        QuerySnapshot snapshot = await firestore
                            .collection('favoritos')
                            .where('user', isEqualTo: auth.currentUser!.email)
                            .where('place', isEqualTo: places[index]['name'])
                            .get();
                        snapshot.docs.forEach((document) {
                          document.reference.delete();
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      // Implementar lógica para añadir a rutas en Firebase
                      //savedPlaces.add(places[index]);
                      firestore.collection('rutas').add({
                        'user': auth.currentUser!.email,
                        'place': places[index]['name'],
                        'location': places[index]['geometry']['location'],
                        'id': counter,
                      });
                      counter++;
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String routeName = '';
              return AlertDialog(
                title: Text('Guardar ruta'),
                content: TextField(
                  onChanged: (value) {
                    routeName = value;
                  },
                  decoration: InputDecoration(hintText: "Nombre de la ruta"),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Guardar'),
                    onPressed: () {
                      firestore.collection('rutas').doc(routeName).set({
                        'user': auth.currentUser!.email,
                        'places': savedPlaces,
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
