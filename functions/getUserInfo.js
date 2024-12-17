const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const cors = require('cors');
const { OAuth2Client } = require('google-auth-library');

const corsHandler = cors({ origin: 'https://my-test-auth-3b2be.web.app', credentials: true });
const client = new OAuth2Client('750135621005-akdhv1a9njtblhu962q9oppi4e253svo.apps.googleusercontent.com');

exports.getUserInfo = onRequest({ region: 'us-central1' }, (req, res) => {
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
      const ticket = await client.verifyIdToken({
        idToken,
        audience: '750135621005-akdhv1a9njtblhu962q9oppi4e253svo.apps.googleusercontent.com',
      });

      const payload = ticket.getPayload();
      const user = await admin.auth().getUser(payload.sub);

      return res.status(200).send({
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
      });
    } catch (error) {
      console.error('Error al obtener la información del usuario:', error);
      return res.status(500).send({ message: `Error interno: ${error.message}` });
    }
  });
});
