import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'place_service.dart';
import 'favorites_service.dart';

class FavoritesService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Función para alternar el estado de favorito de un lugar
  Future<void> toggleFavorite(String placeName, bool isFavorite) async {
    if (isFavorite) {
      // Añadir a favoritos en Firebase
      await firestore.collection('favoritos').add({
        'user': auth.currentUser!.email,
        'place': placeName,
      });
    } else {
      // Eliminar de favoritos en Firebase
      final snapshot = await firestore
          .collection('favoritos')
          .where('user', isEqualTo: auth.currentUser!.email)
          .where('place', isEqualTo: placeName)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  // Función para comprobar si los lugares están en favoritos
  Future<List<bool>> checkFavorites(List<dynamic> places) async {
    // Obtener todos los favoritos del usuario actual una sola vez
    final userFavoritesSnapshot = await firestore
        .collection('favoritos')
        .where('user', isEqualTo: auth.currentUser!.email)
        .get();

    // Crear un conjunto con los nombres de los lugares favoritos
    final Set<String> userFavoritePlaces = userFavoritesSnapshot.docs
        .map((doc) => doc.data()['place'] as String)
        .toSet();

    // Comprobar si cada lugar está en el conjunto de favoritos
    List<bool> favorites = [];
    for (var place in places) {
      favorites.add(userFavoritePlaces.contains(place['name']));
    }

    return favorites;
  }
}
