import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_andorid_firebase/pages/auction/auction_details.dart';

class AuctionMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Menú de Subastas')),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Subastas Iniciadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('auctions')
                        .where('userId', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No se encontraron subastas iniciadas.'));
                      }

                      final auctions = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: auctions.length,
                        itemBuilder: (context, index) {
                          final data = auctions[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text('Subasta: ${data['plate']}'),
                            subtitle: Text('Precio Actual: \$${data['currentPrice']}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AuctionDetails(auctionId: auctions[index].id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('Pujas Ganadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('auctions')
                        .where('winnerId', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final bids = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: bids.length,
                        itemBuilder: (context, index) {
                          final data = bids[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text('Puja Ganada: \$${data['currentPrice']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Subasta: ${bids[index].id}'),
                                Text('Código: ${data['code']}'),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AuctionDetails(auctionId: bids[index].id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}