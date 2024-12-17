const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const cors = require('cors');
const { OAuth2Client } = require('google-auth-library');

// Configuración de CORS
const corsHandler = cors({ origin: 'https://my-test-auth-3b2be.web.app', credentials: true });

const client = new OAuth2Client('750135621005-akdhv1a9njtblhu962q9oppi4e253svo.apps.googleusercontent.com');

exports.signInWithGoogle = onRequest({ region: 'us-central1' }, (req, res) => {
    // Responder explícitamente a las solicitudes OPTIONS
    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Origin', 'https://my-test-auth-3b2be.web.app');
        res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
        res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        res.set('Access-Control-Allow-Credentials', 'true');
        res.status(204).send('');
        return;
    }

    corsHandler(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).send({ message: 'Método no permitido' });
        }

        const { token } = req.body;

        try {
            // Verificar el token de Google
            const ticket = await client.verifyIdToken({
                idToken: token,
                audience: "750135621005-akdhv1a9njtblhu962q9oppi4e253svo.apps.googleusercontent.com",
            });

            const payload = ticket.getPayload();
            const uid = payload.sub;

            let firebaseUser;
            try {
                firebaseUser = await admin.auth().getUser(uid);
            } catch (error) {
                if (error.code === 'auth/user-not-found') {
                    firebaseUser = await admin.auth().createUser({
                        uid,
                        email: payload.email,
                        displayName: payload.name,
                        photoURL: payload.picture,
                    });
                } else {
                    throw error;
                }
            }

            const customToken = await admin.auth().createCustomToken(uid);

            const idToken = await fetch(
                `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=AIzaSyDey9cyNvBBMVpeVQWgZChZDJPxbecapW8`,
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

            // Responder con las cabeceras CORS
            res.set('Access-Control-Allow-Origin', 'https://my-test-auth-3b2be.web.app');
            res.set('Access-Control-Allow-Credentials', 'true');
            res.status(200).send({ idToken });
        } catch (error) {
            console.error('Error en el proceso de autenticación:', error);
            res.set('Access-Control-Allow-Origin', 'https://my-test-auth-3b2be.web.app');
            res.set('Access-Control-Allow-Credentials', 'true');
            res.status(500).send({ error: 'Error en el proceso de autenticación' });
        }
    });
});
