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
  TextEditingController _destinationLocationTextController =
      TextEditingController();
  String country = "123";
  late Position _currentPosition, _destinationPosition;
  double latitude = 21.0277644;
  double long_latitude = 105.8341598;

  double des_latitude = 21.0277644;
  double des_long_latitude = 105.8341598;

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

  searchDestinationPosition() async {
    try {
      if (_layerController.markersCount == 2) {
        _layerController.removeMarkerAt(1);
      }
      _layerController.insertMarker(1);
      List places =
          await locationFromAddress(_destinationLocationTextController.text);
      _destinationPosition = Position(
          longitude: places[0].longitude, latitude: places[0].latitude);
      _layerController.updateMarkers([1]);
      print(_destinationPosition);
      print("set State");
      setState(() {
        des_latitude = _destinationPosition.latitude;
        des_long_latitude = _destinationPosition.longitude;
      });
      _layerController.updateMarkers([1]);
    } catch (e) {
      print("Khong tim thay");
    }

    //1 mile = 0.000621371 * meters
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
          child: Container(
            color: Colors.blue.shade200,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: SfMaps(
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
                          if (index == 1) {
                            return MapMarker(
                              latitude: des_latitude,
                              longitude: des_long_latitude,
                              iconColor: Colors.white,
                              iconStrokeColor: Colors.black,
                              iconStrokeWidth: 2,
                              child: Icon(Icons.location_on),
                            );
                          } else {
                            return MapMarker(
                              latitude: latitude,
                              longitude: long_latitude,
                              iconColor: Colors.white,
                              iconStrokeColor: Colors.black,
                              iconStrokeWidth: 2,
                              child: Icon(Icons.home),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Container(
                          child: TextField(
                            decoration: InputDecoration(
                                hintText: "current location",
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        Container(
                          child: TextField(
                            controller: _destinationLocationTextController,
                            decoration: InputDecoration(
                                hintText: "destination",
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              child: Text('Search'),
                              onPressed: () async {
                                await searchDestinationPosition();
                              },
                            ),
                            ElevatedButton(
                              child: Text('My location'),
                              onPressed: () async {
                                await getCurrentPosition();
                              },
                            ),
                          ],
                        ),
                      ],
                    )),
                Text(country),
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
