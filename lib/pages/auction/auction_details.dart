import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuctionDetails extends StatefulWidget {
  final String auctionId;

  AuctionDetails({required this.auctionId});

  @override
  _AuctionDetailsState createState() => _AuctionDetailsState();
}

class _AuctionDetailsState extends State<AuctionDetails> {
  late DocumentSnapshot auction;
  late TextEditingController bidController;

  @override
  void initState() {
    super.initState();
    bidController = TextEditingController();
    _loadAuctionDetails();
  }

  Future<void> _loadAuctionDetails() async {
    auction = await FirebaseFirestore.instance
        .collection('auctions')
        .doc(widget.auctionId)
        .get();
    setState(() {});
  }

  void _placeBid(double bidAmount) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('auctions')
        .doc(widget.auctionId)
        .collection('bids')
        .doc(userId)
        .set({
      'userId': userId,
      'bidAmount': bidAmount,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Actualizar el campo currentPrice en la colección de subastas
    await FirebaseFirestore.instance
        .collection('auctions')
        .doc(widget.auctionId)
        .update({
      'currentPrice': bidAmount,
    });

    Fluttertoast.showToast(
      msg: 'Puja realizada con éxito.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 14.0,
    );

    _loadAuctionDetails(); // Recargar los detalles de la subasta
  }

  @override
  Widget build(BuildContext context) {
    if (auction == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Detalles de la Subasta')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = auction.data() as Map<String, dynamic>;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = userId == data['userId'];

    return Scaffold(
      appBar: AppBar(title: Text('Detalles de la Subasta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subasta de ${data['userId']}'),
            Text('Precio Inicial: \$${data['initialPrice']}'),
            Text('Precio Actual: \$${data['currentPrice']}'),
            Text('Matrícula del Vehículo: ${data['plate']}'),
            if (!isOwner) ...[
              TextField(
                controller: bidController,
                decoration: InputDecoration(labelText: 'Cantidad de la puja'),
                keyboardType: TextInputType.number,
              ),
              ElevatedButton(
                onPressed: () {
                  final double? bidAmount = double.tryParse(bidController.text);
                  if (bidAmount != null && bidAmount > data['currentPrice']) {
                    _placeBid(bidAmount);
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
          ],
        ),
      ),
    );
  }
}