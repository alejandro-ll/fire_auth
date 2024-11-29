const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors');

const db = admin.firestore();

const corsHandler = cors({ origin: "http://127.0.0.1:5000" });

exports.submitSurvey = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send({ message: 'Método no permitido' });
    }

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).send({ message: 'No autorizado' });
    }

    const idToken = authHeader.split('Bearer ')[1];

    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const uid = decodedToken.uid;

      const { frecuencia, tiempo, estres } = req.body;

      if (!frecuencia || !tiempo || !estres) {
        return res.status(400).send({ message: 'Datos incompletos' });
      }

      const surveyData = {
        frecuencia,
        tiempo,
        estres,
        userId: uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      };

      await db.collection('surveys').add(surveyData);
      return res.status(200).send({ message: 'Encuesta enviada exitosamente' });
    } catch (error) {
      console.error('Error al enviar la encuesta:', error);
      return res.status(500).send({ message: 'Error interno del servidor' });
    }
  });
});