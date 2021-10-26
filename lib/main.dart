import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import "package:latlong2/latlong.dart" as latLng;
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

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
  TextEditingController _currentLocationTextController =
      TextEditingController();
  List<String> _localOptions = <String>[];
  String country = "123";
  late Position _currentPosition, _destinationPosition;
  double latitude = 21.0277644;
  double long_latitude = 105.8341598;

  double des_latitude = 21.0277644;
  double des_long_latitude = 105.8341598;

  String distance = "0";

  late List<MapLatLng> polyline = <MapLatLng>[];
  late List<List<MapLatLng>> polylines = <List<MapLatLng>>[polyline];

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

  searchNomitim(String query) async {
    final searchResult = await Nominatim.searchByName(
      query: query,
      limit: 1,
      addressDetails: true,
      extraTags: true,
      nameDetails: true,
    );
    print("SearchNomitim: ${searchResult.single.nameDetails}");
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

        distance = (Geolocator.distanceBetween(
                    _currentPosition.latitude,
                    _currentPosition.longitude,
                    _destinationPosition.latitude,
                    _destinationPosition.longitude) /
                1000)
            .toStringAsFixed(2);
      });
      //_zoomPanBehavior.zoomLevel = 15;
      _zoomPanBehavior.focalLatLng = MapLatLng(des_latitude, des_long_latitude);
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
    _currentLocationTextController.text = (addresses[0] as Placemark).name;
    setState(() {
      country = (addresses[0] as Placemark).name;
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
                        markerTooltipBuilder: (context, index) {
                          if (index == 1) {
                            return Text(_destinationLocationTextController.text,
                                style: TextStyle(color: Colors.white));
                          } else {
                            return Text(_currentLocationTextController.text,
                                style: TextStyle(color: Colors.white));
                          }
                        },
                        sublayers: [
                          MapPolylineLayer(
                            polylines: List<MapPolyline>.generate(
                              polylines.length,
                              (int index) {
                                return MapPolyline(
                                  points: polylines[index],
                                );
                              },
                            ).toSet(),
                          )
                        ],
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
                          child: Text(distance + " km"),
                        ),
                        Container(
                          child: TextField(
                            controller: _currentLocationTextController,
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
                                hintText: "destination location",
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(width: 1),
                                    borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ElevatedButton(
                                  child: Text('Search'),
                                  onPressed: () {
                                    searchDestination();
                                  },
                                ),
                                ElevatedButton(
                                  child: Text('My location'),
                                  onPressed: () {
                                    getCurrentPosition();
                                  },
                                ),
                              ],
                            ),
                            ElevatedButton(
                              child: Text('Get Direction'),
                              onPressed: () {
                                getDirection();
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

  Future<void> searchDestination() async {
    await searchNomitim(_destinationLocationTextController.text);
    await searchDestinationPosition();
  }

  Future<void> getDirection() async {
    Map<String, String> queryParams = {
      "geometries": "geojson",
    };
    try {
      var url = Uri.https(
          "router.project-osrm.org",
          "route/v1/driving" +
              "/$long_latitude,$latitude" +
              ";$des_long_latitude,$des_latitude",
          queryParams);
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var body = response.body;
        var data = jsonDecode(body);
        var feature = (data as Map)["routes"];
        // print("Feature: ${data["feature"]}");
        var coordinates = feature[0]["geometry"]["coordinates"];
        List<MapLatLng> test_polyline = [];
        (coordinates as List).forEach((coordinate) {
          test_polyline.add(MapLatLng(coordinate[1], coordinate[0]));
        });
        setState(() {
          polyline = test_polyline;
          polylines = <List<MapLatLng>>[test_polyline];
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> getDirectionByThirdParty() async {
    String originalUrl =
        "https://api.openrouteservice.org/v2/directions/driving-car";
    String token = "5b3ce3597851110001cf6248ca55d66f8a924baf9d3aed717e90360f";
    String start = "8.681495,49.41461";
    String end = "8.687872,49.420318";
    Map<String, String> queryParams = {
      "api_key": token,
      "start": start,
      "end": end
    };
    try {
      var url = Uri.https(
          "api.openrouteservice.org", "v2/directions/driving-car", queryParams);
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var body = response.body;
        var data = jsonDecode(body);
        var feature = (data as Map)["features"];
        // print("Feature: ${data["feature"]}");
        var coordinates = feature[0]["geometry"]["coordinates"];
        List<MapLatLng> test_polyline = [];
        (coordinates as List).forEach((coordinate) {
          test_polyline.add(MapLatLng(coordinate[0], coordinate[1]));
        });
        setState(() {
          polyline = test_polyline;
          polylines = <List<MapLatLng>>[test_polyline];
          latitude = 8.681495;
          long_latitude = 49.41461;
          des_latitude = 8.687872;
          des_long_latitude = 49.420318;
        });
        _destinationLocationTextController.text = "";
        _currentLocationTextController.text = "";
        _zoomPanBehavior.focalLatLng = MapLatLng(8.681495, 49.41461);
        _zoomPanBehavior.zoomLevel = 15;
        _layerController.clearMarkers();
        _layerController.insertMarker(0);
        _layerController.insertMarker(1);
      }
    } catch (e) {
      print(e.toString());
    }
  }
}

class Model {
  const Model(this.country, this.latitude, this.longitude);

  final String country;
  final double latitude;
  final double longitude;
}

class PolylineModel {
  PolylineModel(this.points);
  final List<MapLatLng> points;
}
