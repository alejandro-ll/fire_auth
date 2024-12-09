const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors');
const { OAuth2Client } = require('google-auth-library');


const corsHandler = cors({ origin: "https://my-test-auth-3b2be.web.app" });

const client = new OAuth2Client('750135621005-db2iu5c8j134lh8vci7fgavjj48n4dvs.apps.googleusercontent.com');


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
      console.log('Token de ID recibido del cliente:', idToken);

      const ticket = await client.verifyIdToken({
        idToken: idToken,
        audience: '750135621005-db2iu5c8j134lh8vci7fgavjj48n4dvs.apps.googleusercontent.com',
      });

      const payload = ticket.getPayload();
      console.log('Token de ID decodificado:', payload);

      const user = await admin.auth().getUser(payload.sub);
      console.log('Información del usuario obtenida:', {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
      });

      return res.status(200).send({
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
      });
    } catch (error) {
      console.error('Error al obtener la información del usuario:', error);
      return res.status(500).send({ message: `Error interno del servidor: ${error.message}` });
    }
  });
});