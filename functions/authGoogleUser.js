const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require("cors");
const { OAuth2Client } = require('google-auth-library');

const corsHandler = cors({ origin: "http://127.0.0.1:5000" });

const client = new OAuth2Client('750135621005-db2iu5c8j134lh8vci7fgavjj48n4dvs.apps.googleusercontent.com');

exports.signInWithGoogle = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).send({ message: 'Método no permitido. Usa POST.' });
        }
  
        try {
            const { token } = req.body;
  
            if (!token) {
                return res.status(400).send({ message: 'Token no proporcionado' });
            }
  
            // Verifica el token de Google
            const ticket = await client.verifyIdToken({
                idToken: token,
                audience: '750135621005-db2iu5c8j134lh8vci7fgavjj48n4dvs.apps.googleusercontent.com',
            });
  
            const payload = ticket.getPayload();
            console.log('Payload del token de Google:', payload);
  
            // Revisa si el usuario ya existe en Firebase Authentication
            let firebaseUser;
            try {
                firebaseUser = await admin.auth().getUser(payload.sub);
                console.log('Usuario ya registrado en Firebase:', firebaseUser);
            } catch (error) {
                if (error.code === 'auth/user-not-found') {
                    // Si el usuario no existe, regístralo
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
  
            // Devuelve la información del usuario al cliente
            return res.status(200).send({
                uid: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName,
                photoURL: firebaseUser.photoURL,
            });
        } catch (error) {
            console.error('Error al verificar el token de Google o crear el usuario:', error);
            return res.status(500).send({ message: 'Error al iniciar sesión', details: error.message });
        }
    });
  });
  