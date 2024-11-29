const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require("cors");
const { OAuth2Client } = require('google-auth-library');

const corsHandler = cors({ origin: "http://127.0.0.1:5000"});

const client = new OAuth2Client('750135621005-db2iu5c8j134lh8vci7fgavjj48n4dvs.apps.googleusercontent.com');

exports.signInWithGoogle = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send({ message: 'Método no permitido' });
    }

    const { token } = req.body;

    try {
      const ticket = await client.verifyIdToken({
        idToken: token,
        audience: '750135621005-db2iu5c8j134lh8vci7fgavjj48n4dvs.apps.googleusercontent.com',
      });

      const payload = ticket.getPayload();
      const userid = payload['sub'];

      const user = await admin.auth().getUser(userid).catch(async (error) => {
        if (error.code === 'auth/user-not-found') {
          return await admin.auth().createUser({
            uid: userid,
            email: payload.email,
            displayName: payload.name,
            photoURL: payload.picture,
          });
        }
        throw error;
      });

      const customToken = await admin.auth().createCustomToken(user.uid);
      res.status(200).send({ token: customToken });
    } catch (error) {
      console.error('Error al autenticar el usuario:', error);
      res.status(500).send({ message: 'Error interno del servidor' });
    }
  });
});