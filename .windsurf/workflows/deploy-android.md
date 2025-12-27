# /deploy-android

> **Propósito**: Automatizar la compilación y subida de la aplicación a Google Play Console (Track: Internal Testing).

---

## 📋 Requisitos Previos

1. **Credenciales de Google Play**:
   - Archivo: `android/fastlane/google-play-json-key.json`
   - Debe ser una Service Account con permisos de "Release Manager" o "Admin".

2. **Firma de Android**:
   - Archivo: `android/key.properties`
   - Debe contener las credenciales del Keystore de producción.

3. **Herramientas**:
   - Node.js instalado.
   - Ruby y Fastlane instalados (`gem install fastlane`).

---

## 🚀 Ejecución

El proceso es "One-Click". Ejecuta el siguiente comando y sigue las instrucciones en pantalla:

// turbo
```powershell
npm run deploy:android
```

---

## 🔍 ¿Qué hace este proceso?

1. **Verifica credenciales**: Comprueba que existan los archivos de llave necesarios.
2. **Compila (Build)**: Genera el App Bundle (`.aab`) en modo Release optimizado.
3. **Sube (Upload)**: Utiliza Fastlane para enviar el archivo a **Google Play Console** en el canal **Internal Testing** (Pruebas Internas).
4. **Omitir Metadatos**: No sobrescribe descripciones ni imágenes de la tienda, solo actualiza el binario.
