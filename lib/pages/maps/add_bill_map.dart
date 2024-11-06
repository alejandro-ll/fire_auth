import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_andorid_firebase/services/map_service.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class BillMap extends StatefulWidget {
  @override
  _BillMap createState() => _BillMap();
}

class _BillMap extends State<BillMap> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mapa con Marcadores')),
      body: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(40.416775, -3.703790), // Posición inicial del mapa
          zoom: 14.0,
        ),
        markers: _markers,
        onTap: _handleTap,
      ),
    );
  }

    void _handleTap(LatLng tappedPoint) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(tappedPoint.toString()),
          position: tappedPoint,
          infoWindow: InfoWindow(
            title: 'Nueva Ubicación',
            snippet: 'Lat: ${tappedPoint.latitude}, Lng: ${tappedPoint.longitude}',
          ),
        ),
      );
    });
  }

    _requestPermission() async {
    var status = await Permission.locationAlways.request();
    if (status.isGranted) {
      print('done');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}