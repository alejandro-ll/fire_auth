const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const cors = require('cors');

const db = admin.firestore();
const corsHandler = cors({ origin: 'https://my-test-auth-3b2be.web.app', credentials: true });

exports.submitSurvey = onRequest({ region: 'us-central1' }, (req, res) => {
  corsHandler(req, res, async () => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(403).send({ message: 'Falta el token de autorización' });
    }

    const idToken = authHeader.split('Bearer ')[1];

    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const surveyData = { ...req.body, uid: decodedToken.uid, timestamp: Date.now() };
      await db.collection('surveys').add(surveyData);

      res.status(200).send({ message: 'Encuesta recibida correctamente' });
    } catch (error) {
      console.error('Error al procesar la encuesta:', error);
      res.status(403).send({ message: 'Token inválido o expirado' });
    }
  });
});
