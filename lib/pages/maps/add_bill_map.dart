import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_andorid_firebase/services/map_service.dart';
import 'package:test_andorid_firebase/main.dart';
import 'package:test_andorid_firebase/pages/auction/auction_details.dart';
import 'package:test_andorid_firebase/pages/auction/auction_menu.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class BillMap extends StatefulWidget {
  @override
  _BillMap createState() => _BillMap();
}

class _BillMap extends State<BillMap> with RouteAware {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _loadUserAuction();
    _loadAllAuctions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      MyApp.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    MyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Se llama cuando se vuelve a esta página desde otra página
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
            snippet: 'Precio: \$${data['currentPrice']}',
          ),
          onTap: () {
            final userId = FirebaseAuth.instance.currentUser!.uid;
            if (userId != data['userId']) {
              _showBidDialog(doc.id);
            }
          },
        );
      }).toSet());
    });
  }

  void _placeBid(String auctionId, double bidAmount) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('auctions')
        .doc(auctionId)
        .collection('bids')
        .doc(userId)
        .set({
      'userId': userId,
      'bidAmount': bidAmount,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('auctions')
        .doc(auctionId)
        .update({
      'currentPrice': bidAmount,
    });

    setState(() {
      _markers = _markers.map((marker) {
        if (marker.markerId.value == auctionId) {
          return marker.copyWith(
            infoWindowParam: InfoWindow(
              title: 'Subasta Activa',
              snippet: 'Precio: \$${bidAmount}',
            ),
          );
        }
        return marker;
      }).toSet();
    });

    Fluttertoast.showToast(
      msg: 'Puja realizada con éxito.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa con Marcadores'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AuctionMenu(),
                ),
              );
            },
            child: Text('Menú de Subastas'),
          ),
        ],
      ),
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
            snippet: 'Precio: \$${price.toString()}',
          ),
        ),
      );
    });

    final docRef = await FirebaseFirestore.instance.collection('auctions').add({
      'userId': userId,
      'latitude': tappedPoint.latitude,
      'longitude': tappedPoint.longitude,
      'price': price,
      'initialPrice': price,
      'currentPrice': price,
      'plate': plate,
      'active': true,
      'startTime': FieldValue.serverTimestamp(),
    });

    // Establecer un temporizador de 5 minutos para la subasta
    Future.delayed(Duration(minutes: 5), () async {
      final highestBid = await getHighestBid(docRef.id);
      if (highestBid != null) {
        final highestBidderId = highestBid['userId'];
        final highestBidAmount = highestBid['bidAmount'];
        final code = _generateCode();

        try {
          await FirebaseFirestore.instance.collection('auctions').doc(docRef.id).update({
            'active': false,
            'winnerId': highestBidderId,
            'code': code,
          });

          Fluttertoast.showToast(
            msg: 'La subasta ha finalizado. El ganador ha pagado \$${highestBidAmount}.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 14.0,
          );

          // Mostrar el código al ganador
          if (FirebaseAuth.instance.currentUser!.uid == highestBidderId) {
            _showWinnerCodeDialog(code);
          }
        } catch (e) {
          Fluttertoast.showToast(
            msg: 'Error al actualizar la subasta: ${e.toString()}',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'La subasta ha finalizado sin pujas.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0,
        );

        await FirebaseFirestore.instance.collection('auctions').doc(docRef.id).update({
          'active': false,
        });
      }

      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == docRef.id);
      });
    });
  }

  Future<Map<String, dynamic>?> getHighestBid(String auctionId) async {
    final bids = await FirebaseFirestore.instance
        .collection('auctions')
        .doc(auctionId)
        .collection('bids')
        .orderBy('bidAmount', descending: true)
        .limit(1)
        .get();

    if (bids.docs.isNotEmpty) {
      return bids.docs.first.data();
    } else {
      return null;
    }
  }

  String _generateCode() {
    final random = Random();
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(6, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }

  void _showWinnerCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Código de Ganador'),
          content: Text('Tu código es: $code'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showBidDialog(String auctionId) async {
    final doc = await FirebaseFirestore.instance.collection('auctions').doc(auctionId).get();
    final data = doc.data();
    final double currentPrice = data?['currentPrice'] ?? 0.0; 
    
    final TextEditingController bidController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pujar'),
          content: TextField(
            controller: bidController,
            decoration: InputDecoration(labelText: 'Cantidad de la puja'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuctionDetails(auctionId: auctionId),
                      ),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final double? bidAmount = double.tryParse(bidController.text);
                    if (bidAmount != null && bidAmount > currentPrice) {
                      _placeBid(auctionId, bidAmount);
                      Navigator.of(context).pop();
                    } else {
                      Fluttertoast.showToast(
                        msg: 'Por favor, ingrese una cantidad válida mayor al precio actual.',
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.SNACKBAR,
                        backgroundColor: Colors.black54,
                        textColor: Colors.white,
                        fontSize: 14.0,
                      );
                    }
                  },
                  child: Text('Pujar'),
                ),
              ],
            ),
          ],
        );
      },
    );
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