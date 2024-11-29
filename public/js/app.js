// Función para manejar la respuesta de credenciales de Google
async function handleCredentialResponse(response) {
    console.log('Iniciando sesión con Google...');
    try {
      const token = response.credential;
  
      const res = await fetch('http://127.0.0.1:5001/my-test-auth-3b2be/us-central1/signInWithGoogle', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ token })
      });
  
      if (!res.ok) {
        throw new Error('Error al iniciar sesión');
      }
  
      const data = await res.json();
      localStorage.setItem('customToken', data.token);
      alert('¡Inicio de sesión exitoso!');
      updateUserInfo();
    } catch (error) {
      console.error('Error al iniciar sesión:', error);
      alert('Hubo un error al iniciar sesión. Inténtalo de nuevo.');
    }
  }
  
  // Función para manejar el envío del formulario
  async function submitSurvey(data) {
    try {
      const token = localStorage.getItem('customToken');
      if (!token) {
        throw new Error('Usuario no autenticado');
      }
  
      const response = await fetch('http://127.0.0.1:5001/my-test-auth-3b2be/us-central1/submitSurvey', {
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
    const token = localStorage.getItem('customToken');
    if (!token) return null;
  
    const response = await fetch('http://127.0.0.1:5001/my-test-auth-3b2be/us-central1/getUserInfo', {
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
  export { handleCredentialResponse, submitSurvey, getUserInfo };