import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import "package:latlong2/latlong.dart" as latLng;
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String country = "123";
  late Position _currentPosition, _destinationPosition;
  double latitude = 20;
  double long_latitude = -50;
  final MapTileLayerController _layerController = MapTileLayerController();
  late MapZoomPanBehavior _zoomPanBehavior;
  @override
  void initState() {
    _zoomPanBehavior = MapZoomPanBehavior();
    super.initState();
  }

  @override
  void dispose() {
    _layerController.dispose();
    super.dispose();
  }

  getCurrentPosition() async {
    _layerController.insertMarker(0);
    _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List addresses = await placemarkFromCoordinates(
        _currentPosition.latitude, _currentPosition.longitude);
    print(addresses[0].country);
    setState(() {
      country = addresses[0].country;
      latitude = _currentPosition.latitude;
      long_latitude = _currentPosition.longitude;
    });
    _layerController.updateMarkers([0]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SfMaps(
                  layers: [
                    MapTileLayer(
                      controller: _layerController,
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      initialZoomLevel: 2,
                      initialFocalLatLng: MapLatLng(28.644800, 77.216721),
                      initialMarkersCount: 0,
                      zoomPanBehavior: _zoomPanBehavior,
                      markerBuilder: (BuildContext context, int index) {
                        return MapMarker(
                          latitude: latitude,
                          longitude: long_latitude,
                          iconColor: Colors.white,
                          iconStrokeColor: Colors.black,
                          iconStrokeWidth: 2,
                        );
                      },
                    ),
                  ],
                ),
                ElevatedButton(
                  child: Text('Add marker'),
                  onPressed: () async {
                    await getCurrentPosition();
                  },
                ),
                Text(country)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Model {
  const Model(this.country, this.latitude, this.longitude);

  final String country;
  final double latitude;
  final double longitude;
}
