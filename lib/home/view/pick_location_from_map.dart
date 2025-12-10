import 'package:flutter/material.dart';
import 'package:here_sdk/mapview.dart';

class PickLocationFromMap extends StatefulWidget {
  const PickLocationFromMap({super.key});

  @override
  State<PickLocationFromMap> createState() => _PickLocationFromMapState();
}

class _PickLocationFromMapState extends State<PickLocationFromMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // HereMap(onMapCreated: _onMapCreated),

          // fixed pin in center
          Align(
            alignment: Alignment.center,
            child: Icon(Icons.location_pin, size: 40, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
