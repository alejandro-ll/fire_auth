const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors');

const corsHandler = cors({ origin: "http://127.0.0.1:5000" });

exports.getUserInfo = functions.https.onRequest((req, res) => {
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

      const user = await admin.auth().getUser(uid);
      return res.status(200).send(user);
    } catch (error) {
      console.error('Error al obtener la información del usuario:', error);
      return res.status(500).send({ message: `Error interno del servidor: ${error.message}` });
    }
  });
});