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
  DocumentSnapshot? auction;
  late TextEditingController bidController;
  late TextEditingController codeController;

  @override
  void initState() {
    super.initState();
    bidController = TextEditingController();
    codeController = TextEditingController();
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

  void _showCodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Introducir Código'),
          content: TextField(
            controller: codeController,
            decoration: InputDecoration(labelText: 'Código'),
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
                _verifyCode();
              },
              child: Text('Verificar'),
            ),
          ],
        );
      },
    );
  }

  void _verifyCode() async {
    final data = auction!.data() as Map<String, dynamic>;
    final code = data['code'];
    if (codeController.text == code) {
      Fluttertoast.showToast(
        msg: 'Código verificado. Subasta cobrada con éxito.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      Navigator.of(context).pop();
    } else {
      Fluttertoast.showToast(
        msg: 'Código incorrecto. Inténtalo de nuevo.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (auction == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Detalles de la Subasta')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = auction!.data() as Map<String, dynamic>;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = userId == data['userId'];
    final isWinner = userId == data['winnerId'];
    final currentPrice = data['currentPrice'] ?? data['initialPrice'];

    return Scaffold(
      appBar: AppBar(title: Text('Detalles de la Subasta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subasta de ${data['userId']}'),
            Text('Precio Inicial: \$${data['initialPrice']}'),
            Text('Precio Actual: \$${currentPrice}'),
            Text('Matrícula del Vehículo: ${data['plate']}'),
            if (isWinner) ...[
              Text('¡Felicidades! Has ganado la subasta.'),
              Text('Tu código es: ${data['code']}'),
            ],
            if (!isOwner && !isWinner) ...[
              TextField(
                controller: bidController,
                decoration: InputDecoration(labelText: 'Cantidad de la puja'),
                keyboardType: TextInputType.number,
              ),
              ElevatedButton(
                onPressed: () {
                  final double? bidAmount = double.tryParse(bidController.text);
                  if (bidAmount != null && bidAmount > currentPrice) {
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
            if (isOwner && data['active'] == false) ...[
              ElevatedButton(
                onPressed: _showCodeDialog,
                child: Text('Introducir Código para Cobrar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}