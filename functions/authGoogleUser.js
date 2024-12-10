const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require("cors");

const { OAuth2Client } = require('google-auth-library');

const corsHandler = cors({ origin: 'https://my-test-auth-3b2be.web.app' });

const client = new OAuth2Client('750135621005-akdhv1a9njtblhu962q9oppi4e253svo.apps.googleusercontent.com');

exports.signInWithGoogle = functions.https.onRequest((req, res) => {
    corsHandler(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).send({ message: 'Método no permitido' });
        }

        const { token } = req.body;
        console.log('Token de Google recibido:', token);

        try {
            // Verificar el token de Google
            const ticket = await client.verifyIdToken({
                idToken: token,
                audience: "750135621005-akdhv1a9njtblhu962q9oppi4e253svo.apps.googleusercontent.com",
            });
            console.log('Token de Google verificado:', ticket);

            const payload = ticket.getPayload();
            const uid = payload.sub; // El UID único del usuario

            let firebaseUser;
            try {
                // Obtener o crear el usuario en Firebase
                firebaseUser = await admin.auth().getUser(uid);
                console.log('Usuario ya registrado en Firebase:', firebaseUser);
            } catch (error) {
                if (error.code === 'auth/user-not-found') {
                    firebaseUser = await admin.auth().createUser({
                        uid,
                        email: payload.email,
                        displayName: payload.name,
                        photoURL: payload.picture,
                    });
                    console.log('Nuevo usuario creado en Firebase:', firebaseUser);
                } else {
                    throw error;
                }
            }

            // Generar un custom token
            const customToken = await admin.auth().createCustomToken(uid);
            console.log('Custom token generado:', customToken);

            // Usar el custom token para autenticar y obtener el ID token
            const idToken = await fetch(
                `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=`,
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ token: customToken, returnSecureToken: true }),
                }
            )
                .then(response => response.json())
                .then(data => data.idToken);

            if (!idToken) {
                throw new Error('No se pudo generar el ID token');
            }

            res.status(200).send({ idToken });
        } catch (error) {
            console.error('Error en el proceso de autenticación:', error);
            res.status(500).send({ error: 'Error en el proceso de autenticación' });
        }
    });
});