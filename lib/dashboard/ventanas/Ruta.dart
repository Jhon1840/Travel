import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_travel/dashboard/ventanas/crear%20ruta/crearRuta.dart';

class Rutas extends StatefulWidget {
  const Rutas({Key? key}) : super(key: key);

  @override
  State<Rutas> createState() => _RutasState();
}

class _RutasState extends State<Rutas> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Tus rutas'),
          backgroundColor: Colors.deepPurple,
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: _firestore.collection('rutas').get(),
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
                    title: Text(document.id),
                    onTap: () async {
                      QuerySnapshot placesSnapshot = await _firestore
                          .collection('rutas')
                          .doc(document.id)
                          .collection('places')
                          .get();
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Lugares en ${document.id}'),
                            content: Column(
                              children: placesSnapshot.docs.map((doc) {
                                return Text(doc['place']);
                              }).toList(),
                            ),
                          );
                        },
                      );
                    },
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
                    builder: (context) => const CrearRuta(
                          ciudad: 'Santa Cruz',
                        )));
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.deepPurple,
        ),
      ),
    );
  }
}
