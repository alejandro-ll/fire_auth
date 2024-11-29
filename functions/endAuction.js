const functions = require('firebase-functions');
const admin = require('firebase-admin');
const db = admin.firestore();

exports.endAuction = functions.firestore
  .document('auctions/{auctionId}')
  .onCreate(async (snap, context) => {
    const auctionId = context.params.auctionId;
    const auctionData = snap.data();

    // Programa la finalización de la subasta después de 5 minutos
    setTimeout(async () => {
      try {
        const auctionRef = db.collection('auctions').doc(auctionId);
        const auctionDoc = await auctionRef.get();

        if (!auctionDoc.exists) {
          console.log('Auction not found');
          return;
        }

        const auctionData = auctionDoc.data();
        const highestBid = await getHighestBid(auctionId);

        if (highestBid) {
          const highestBidderId = highestBid.userId;
          const highestBidAmount = highestBid.bidAmount;
          const code = generateCode();

          await auctionRef.update({
            active: false,
            winnerId: highestBidderId,
            code: code,
          });

          console.log('Auction ended successfully', code);
        } else {
          await auctionRef.update({
            active: false,
          });

          console.log('Auction ended with no bids');
        }
      } catch (error) {
        console.error('Error ending auction:', error);
      }
    }, 5 * 60 * 1000); // 5 minutos en milisegundos
  });

async function getHighestBid(auctionId) {
  const bids = await db.collection('auctions').doc(auctionId).collection('bids').orderBy('bidAmount', 'desc').limit(1).get();
  if (!bids.empty) {
    return bids.docs[0].data();
  } else {
    return null;
  }
}

function generateCode() {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return code;
}