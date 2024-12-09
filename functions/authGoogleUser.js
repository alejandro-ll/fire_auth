const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require("cors");

const { OAuth2Client } = require('google-auth-library');

const corsHandler = cors({ origin: "https://my-test-auth-3b2be.web.app" });

const client = new OAuth2Client('750135621005-db2iu5c8j134lh8vci7fgavjj48n4dvs.apps.googleusercontent.com');
/*
exports.signInWithGoogle = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
      if (req.method !== 'POST') {
        return res.status(405).send({ message: 'Método no permitido' });
      }
  
      const { token } = req.body;
  
      try {
        console.log('Token de Google recibido:', token);
  
        const ticket = await client.verifyIdToken({
          idToken: token,
          audience: '750135621005-db2iu5c8j134lh8vci7fgavjj48n4dvs.apps.googleusercontent.com',
        });
  
        const payload = ticket.getPayload();
        console.log('Payload del token de Google:', payload);
  
        let firebaseUser;
        try {
          firebaseUser = await admin.auth().getUser(payload.sub);
          console.log('Usuario ya registrado en Firebase:', firebaseUser);
        } catch (error) {
          if (error.code === 'auth/user-not-found') {
            firebaseUser = await admin.auth().createUser({
              uid: payload.sub,
              email: payload.email,
              displayName: payload.name,
              photoURL: payload.picture,
            });
            console.log('Nuevo usuario creado en Firebase:', firebaseUser);
          } else {
            throw error;
          }
        }
  
        return res.status(200).send({ idToken: token, displayName: firebaseUser.displayName });
      } catch (error) {
        console.error('Error al verificar el token de Google o crear el usuario:', error);
        return res.status(500).send({ message: 'Error al iniciar sesión', details: error.message });
      }
    });
  });
*/
  exports.signInWithGoogle = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
      if (req.method !== 'POST') {
        return res.status(405).send({ message: 'Método no permitido' });
      }
  
      const { token } = req.body;
  
      try {
        // Verificar el token de Google
        const ticket = await client.verifyIdToken({
          idToken: token,
          audience: '750135621005-db2iu5c8j134lh8vci7fgavjj48n4dvs.apps.googleusercontent.com',
        });
  
        const payload = ticket.getPayload();
        const uid = payload['sub']; // ID único de Google
  
        // Crear un JWT personalizado con Firebase Admin
        const customToken = await admin.auth().createCustomToken(uid);
  
        res.status(200).send({
          message: 'Inicio de sesión exitoso',
          firebaseToken: customToken, // Este es el JWT generado para el cliente
        });
      } catch (error) {
        console.error('Error al autenticar con Google:', error);
        res.status(401).send({ message: 'Autenticación fallida', error });
      }
    });
  });
  