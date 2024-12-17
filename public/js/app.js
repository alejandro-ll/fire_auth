// Importa las bibliotecas de Firebase
import { getAuth, signInWithPopup, GoogleAuthProvider } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-auth.js';

// Variables estáticas con los nuevos endpoints
const backendUrl = 'https://signinwithgoogle-mwusx267ta-uc.a.run.app';
const submitSurveyUrl = 'https://submitsurvey-mwusx267ta-uc.a.run.app';
const getUserInfoUrl = 'https://getuserinfo-mwusx267ta-uc.a.run.app';

// Función para manejar la respuesta de credenciales de Google
async function handleCredentialResponse(response) {
  try {
    const token = response.credential;

    // Enviar el token de Google al nuevo endpoint
    const res = await fetch(`${backendUrl}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token }),
    });

    const { idToken } = await res.json(); // Recibir el idToken del backend
    console.log('IdToken recibido del backend:', idToken);

    if (idToken) {
      localStorage.setItem('idToken', idToken); // Guardar en localStorage
      console.log('IdToken guardado en localStorage:', idToken);
      alert('Inicio de sesión exitoso');
    } else {
      console.error('IdToken no recibido del backend');
      alert('Hubo un error al iniciar sesión.');
    }
  } catch (error) {
    console.error('Error al manejar la autenticación:', error);
    alert('Hubo un error al iniciar sesión.');
  }
}

// Función para enviar la encuesta
async function submitSurvey(data) {
  const token = localStorage.getItem("idToken");
  if (!token) {
    console.error("No hay un token JWT disponible. El usuario debe iniciar sesión.");
    alert("Inicia sesión antes de enviar la encuesta.");
    return;
  }

  try {
    const response = await fetch(`${submitSurveyUrl}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      throw new Error("Error al enviar la encuesta");
    }

    const result = await response.json();
    console.log("Respuesta del backend:", result);
    alert("¡Encuesta enviada exitosamente!");
  } catch (error) {
    console.error("Error al enviar datos al backend:", error);
    alert("Hubo un error al enviar la encuesta. Inténtalo de nuevo.");
  }
}

// Función para obtener la información del usuario
async function getUserInfo() {
  const token = localStorage.getItem("idToken");
  if (!token) {
    console.error("No hay un token JWT disponible. El usuario debe iniciar sesión.");
    return null;
  }

  try {
    const response = await fetch(`${getUserInfoUrl}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error("Error al obtener la información del usuario");
    }

    const userInfo = await response.json();
    console.log("Información del usuario recibida:", userInfo);
    return userInfo;
  } catch (error) {
    console.error("Error al obtener la información del usuario:", error);
    return null;
  }
}

// Exporta las funciones para usarlas en otros scripts
export { handleCredentialResponse, submitSurvey, getUserInfo };
