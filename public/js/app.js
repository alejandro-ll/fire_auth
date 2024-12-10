// Importa las bibliotecas de Firebase
import { getAuth, signInWithPopup, GoogleAuthProvider } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-auth.js';
const backendUrl = 'https://us-central1-my-test-auth-3b2be.cloudfunctions.net';
/*

// Función para manejar la respuesta de credenciales de 
  async function handleCredentialResponse(response) {
    console.log('Iniciando sesión con Google...');
    try {
      const token = response.credential;
      console.log('Token de Google recibido:', token);
  
      const res = await fetch('https://us-central1-my-test-auth-3b2be.cloudfunctions.net/signInWithGoogle', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ token })
      });
  
      if (!res.ok) {
        throw new Error('Error al iniciar sesión');
      }
  
      const userData = await res.json();
      console.log('Datos del usuario recibidos del servidor:', userData);
      console.log('Custom Token recibido del servidor:', userData.idToken);
      localStorage.setItem('customToken', userData.idToken);
      console.log('Custom Token guardado en localStorage:', localStorage.getItem('idToken'));
  
      alert(`¡Bienvenido ${userData.displayName}!`);
    } catch (error) {
      console.error('Error al iniciar sesión:', error);
      alert('Hubo un error al iniciar sesión. Inténtalo de nuevo.');
    }
  }

  
  // Función para manejar el envío del formulario
  async function submitSurvey(data) {
    try {
      const token = localStorage.getItem('idToken');
      if (!token) {
        throw new Error('Usuario no autenticado');
      }
  
      const response = await fetch('https://us-central1-my-test-auth-3b2be.cloudfunctions.net/submitSurvey', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(data)
      });
  
      if (!response.ok) {
        throw new Error('Error al enviar la encuesta');
      }
  
      const result = await response.json();
      console.log('Documento añadido con ID:', result.id);
      alert('¡Encuesta enviada exitosamente!');
    } catch (e) {
      console.error('Error al agregar el documento:', e);
      alert('Hubo un error al enviar la encuesta. Inténtalo de nuevo.');
    }
  }
  
  // Función para obtener la información del usuario

  async function getUserInfo() {
    const token = localStorage.getItem('idToken');
    if (!token) return null;
  
    const response = await fetch('https://us-central1-my-test-auth-3b2be.cloudfunctions.net/getUserInfo', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    });
  
    if (!response.ok) {
      throw new Error('Error al obtener la información del usuario');
    }
  
    return await response.json();
  }
  
  // Función para actualizar la información del usuario en la UI
  async function updateUserInfo() {
    const user = await getUserInfo();
    if (user) {
      document.getElementById("user-info").innerText = `Usuario: ${user.displayName || user.email}`;
    }
  }
  // Exporta las funciones para usarlas en otros scripts
  export { handleCredentialResponse, submitSurvey, getUserInfo };*/
  
  async function handleCredentialResponse(response) {
    try {
      const token = response.credential;
      // Enviar el token de Google al backend
      const res = await fetch(`${backendUrl}/signInWithGoogle`, {
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
  
  async function submitSurvey(data) {
    const token = localStorage.getItem("idToken");
    if (!token) {
      console.error("No hay un token JWT disponible. El usuario debe iniciar sesión.");
      alert("Inicia sesión antes de enviar la encuesta.");
      return;
    }
  
    try {
      const response = await fetch(`${backendUrl}/submitSurvey`, {
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
  
  async function getUserInfo() {
    const token = localStorage.getItem("firebaseToken");
    if (!token) {
      console.error("No hay un token JWT disponible. El usuario debe iniciar sesión.");
      return null;
    }
  
    try {
      const response = await fetch(`${backendUrl}/getUserInfo`, {
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
      return userInfo;
    } catch (error) {
      console.error("Error al obtener la información del usuario:", error);
      return null;
    }
  }
  
  // Exporta las funciones para usarlas en otros scripts
  export { handleCredentialResponse, submitSurvey, getUserInfo };
