const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

const db = admin.firestore();

setGlobalOptions({ region: 'us-central1' });

exports.endAuction = onDocumentCreated('auctions/{auctionId}', async (event) => {
  const auctionId = event.params.auctionId;

  // Lógica de procesamiento
  try {
    const auctionRef = db.collection('auctions').doc(auctionId);
    await auctionRef.update({ active: false }); // Marcamos la subasta como finalizada

    console.log(`Subasta ${auctionId} finalizada correctamente.`);
  } catch (error) {
    console.error('Error finalizando la subasta:', error);
  }
});
