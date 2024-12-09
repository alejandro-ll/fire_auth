const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors');

const db = admin.firestore();

const corsHandler = cors({ origin: "https://my-test-auth-3b2be.web.app" });

exports.submitSurvey = functions.https.onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).send({ message: "Método no permitido" });
    }

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).send({ message: "No autorizado" });
    }

    const idToken = authHeader.split("Bearer ")[1];

    try {
      // Verificar el token personalizado con Firebase Admin
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const uid = decodedToken.uid;
      console.log("Token decodificado:", decodedToken);

      // Procesar datos de la encuesta
      const { frecuencia, tiempo, estres } = req.body;

      if (!frecuencia || !tiempo || !estres) {
        return res.status(400).send({ message: "Datos incompletos" });
      }

      const surveyData = { uid, frecuencia, tiempo, estres, timestamp: Date.now() };
      await admin.firestore().collection("surveys").add(surveyData);

      return res.status(200).send({ message: "Encuesta registrada con éxito" });
    } catch (error) {
      console.error("Error al verificar el token:", error);
      return res.status(403).send({ message: "Token inválido o expirado" });
    }
  });
});