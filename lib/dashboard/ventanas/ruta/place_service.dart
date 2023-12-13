import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaceService {
  Future<List<dynamic>> fetchPlaces(String ciudad) async {
    final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=tourist+attractions+in+$ciudad&language=es&key=AIzaSyDyT3GTnOOvYx5EJQe2B6lV4WjbXaoKUDY'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load places');
    }
  }
}
