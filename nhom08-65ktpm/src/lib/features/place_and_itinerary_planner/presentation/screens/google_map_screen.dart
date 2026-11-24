import 'package:flutter/material.dart';

import 'open_street_map_screen.dart';

/// Keeps the feature's original entry point while rendering the OSM version.
class GoogleMapScreen extends StatelessWidget {
  const GoogleMapScreen({super.key});

  @override
  Widget build(BuildContext context) => const OpenStreetMapScreen();
}
