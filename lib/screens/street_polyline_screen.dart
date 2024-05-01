import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../config/all_config.dart';


class StreetPolylineMap extends StatefulWidget {
  const StreetPolylineMap({super.key});

  @override
  _StreetPolylineMapState createState() {
    return _StreetPolylineMapState();
  }
}

class _StreetPolylineMapState extends State<StreetPolylineMap> {
  late String getRouteURL;
  late String mapboxURL;
  late List<LatLng> _routeCoordinates;
  final List<LatLng> _emptyRouteCoordinates = [];
  LatLng startDestination = const LatLng(28.7041, 77.1025);
  LatLng endDestination = const LatLng(28.6139, 77.2090);
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _routeCoordinates = [];
    mapboxURL = '${constants.mapboxURL}${constants.mapboxPublicAccessToken}';
    getRouteURL =
    '${constants.getRouteURL}${startDestination.longitude},${startDestination.latitude};${endDestination.longitude},${endDestination.latitude}?overview=full&geometries=geojson';
    _fetchRoute();
    _startDriverSimulation();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    final url = getRouteURL;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final geometry = decoded['routes'][0]['geometry']['coordinates'] as List;
      setState(() {
        _routeCoordinates =
            geometry.map((coords) => LatLng(coords[1], coords[0])).toList();
      });
    } else {
    }
  }

  void _startDriverSimulation() {
    const duration = Duration(seconds: 3);
    _timer = Timer.periodic(duration, (_) {
      setState(() {
        if (_routeCoordinates.isNotEmpty) {
          _routeCoordinates.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          center: _routeCoordinates.isNotEmpty
              ? _routeCoordinates[((_routeCoordinates.length) / 2).ceil()]
              : startDestination,
          zoom: 11.5,
        ),
        children: [
          TileLayer(
            urlTemplate: mapboxURL,
            additionalOptions: {'accessToken': constants.mapboxPublicAccessToken},
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routeCoordinates.isNotEmpty
                    ? _routeCoordinates
                    : _emptyRouteCoordinates,
                color: Colors.blue,
                strokeWidth: 5.0,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _routeCoordinates.isNotEmpty
                    ? _routeCoordinates[0]
                    : endDestination,
                width: 24.0,
                height: 24.0,
                child: Image.asset(deliveryManIcon),
              ),
              Marker(
                point: endDestination,
                width: 24.0,
                height: 24.0,
                child: Image.asset(deliveryLocationIcon),
              ),
            ],
          ),
        ],
      ),
    );
  }
}