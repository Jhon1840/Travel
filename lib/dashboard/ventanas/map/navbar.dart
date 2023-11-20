import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Navbar extends StatelessWidget {
  final Function(LatLng) onLocationSelected;

  const Navbar({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Mi Aplicación'),
      actions: <Widget>[
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'Santa Cruz':
                onLocationSelected(const LatLng(-17.780579, -63.177035));
                break;
              case 'Cochabamba':
                onLocationSelected(const LatLng(-17.390438, -66.166971));
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Santa Cruz',
              child: Text('Santa Cruz'),
            ),
            const PopupMenuItem<String>(
              value: 'Cochabamba',
              child: Text('Cochabamba'),
            ),
          ],
        ),
      ],
    );
  }
}
