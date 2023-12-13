import 'package:flutter/material.dart';

class PlaceCard extends StatelessWidget {
  final dynamic place;
  final VoidCallback onFavoritePressed;
  final VoidCallback onAddPressed;
  final VoidCallback onMapPressed;

  const PlaceCard({
    Key? key,
    required this.place,
    required this.onFavoritePressed,
    required this.onAddPressed,
    required this.onMapPressed,
    required bool isFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(place['icon']),
            ),
            title: Text(place['name']),
            subtitle: Text('Rating: ${place['rating']}'),
            onTap: onMapPressed,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.favorite_border,
                ),
                onPressed: onFavoritePressed,
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: onAddPressed,
              ),
              IconButton(
                icon: Icon(Icons.map),
                onPressed: onMapPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
