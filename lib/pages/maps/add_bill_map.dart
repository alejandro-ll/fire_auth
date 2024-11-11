import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
    _loadUserAuction();
    _loadAllAuctions();
  }

  Future<void> _loadUserAuction() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final auction = await FirebaseFirestore.instance
        .collection('auctions')
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .get();

    if (auction.docs.isNotEmpty) {
      final doc = auction.docs.first;
      final data = doc.data();
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['latitude'], data['longitude']),
            infoWindow: InfoWindow(
              title: 'Subasta Activa',
              snippet: 'Precio: \$${data['price']}',
            ),
          ),
        );
      });
    }
  }

  Future<void> _loadAllAuctions() async {
    final auctions = await FirebaseFirestore.instance
        .collection('auctions')
        .where('active', isEqualTo: true)
        .get();

    setState(() {
      _markers.addAll(auctions.docs.map((doc) {
        final data = doc.data();
        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(data['latitude'], data['longitude']),
          infoWindow: InfoWindow(
            title: 'Subasta Activa',
            snippet: 'Precio: \$${data['price']}',
          ),
        );
      }).toSet());
    });
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

  void _handleTap(LatLng tappedPoint) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final auction = await FirebaseFirestore.instance
        .collection('auctions')
        .where('userId', isEqualTo: userId)
        .where('active', isEqualTo: true)
        .get();

    if (auction.docs.isNotEmpty) {
      Fluttertoast.showToast(
        msg: 'Ya tienes una subasta activa.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return;
    }

    _showAuctionDialog(tappedPoint);
  }

  void _showAuctionDialog(LatLng tappedPoint) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController plateController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Iniciar Subasta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Precio Inicial'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: plateController,
                decoration: InputDecoration(labelText: 'Matrícula del Vehículo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? price = double.tryParse(priceController.text);
                final String plate = plateController.text;

                if (price != null && plate.isNotEmpty) {
                  _startAuction(tappedPoint, price, plate);
                  Navigator.of(context).pop();
                } else {
                  Fluttertoast.showToast(
                    msg: 'Por favor, ingrese todos los datos.',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.SNACKBAR,
                    backgroundColor: Colors.black54,
                    textColor: Colors.white,
                    fontSize: 14.0,
                  );
                }
              },
              child: Text('Iniciar Subasta'),
            ),
          ],
        );
      },
    );
  }

  void _startAuction(LatLng tappedPoint, double price, String plate) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(tappedPoint.toString()),
          position: tappedPoint,
          infoWindow: InfoWindow(
            title: 'Nueva Subasta',
            snippet: 'Lat: ${tappedPoint.latitude}, Lng: ${tappedPoint.longitude}',
          ),
        ),
      );
    });

    final docRef = await FirebaseFirestore.instance.collection('auctions').add({
      'userId': userId,
      'latitude': tappedPoint.latitude,
      'longitude': tappedPoint.longitude,
      'price': price,
      'plate': plate,
      'active': true,
      'startTime': FieldValue.serverTimestamp(),
    });

    // Establecer un temporizador de 5 minutos para la subasta
    Future.delayed(Duration(minutes: 5), () async {
      await FirebaseFirestore.instance.collection('auctions').doc(docRef.id).update({
        'active': false,
      });
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == docRef.id);
      });
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