# Guía de Despliegue Automático a Google Play

Este proyecto incluye un script automatizado para construir y subir la aplicación a Google Play Console (Track: Internal Testing).

## Requisitos Previos

### 1. Clave de Servicio de Google Play (JSON)
Para que el script pueda subir la app automáticamente, necesitas una **Service Account** de Google Cloud con permisos en Google Play Console.

1. Ve a **Google Cloud Console**.
2. Crea una **Service Account**.
3. Dale permisos de **Service Account User**.
4. Crea una **Key** tipo **JSON** y descárgala.
5. Ve a **Google Play Console** -> **Users & Permissions** -> **Invite new users** -> Agrega el email de la service account con permisos de "Admin" o "Release Manager".
6. **IMPORTANTE**: Renombra el archivo descargado a `google-play-json-key.json` y colócalo en:
   
   ```
   android/fastlane/google-play-json-key.json
   ```

### 2. Fastlane
El script utiliza **Fastlane** por debajo. Necesitas tener Ruby y Fastlane instalados en tu sistema.

**Instalación (si no lo tienes):**
```bash
gem install fastlane
```

## Cómo Usar

Simplemente ejecuta el siguiente comando en la raíz del proyecto:

```bash
npm run deploy:android
```

### ¿Qué hace este comando?
1. **Verifica** que tengas las llaves de firma (`key.properties`) y la llave de API de Google (`google-play-json-key.json`).
2. **Construye** la versión de producción (`flutter build appbundle --release`).
3. **Sube** el archivo `.aab` generado a Google Play Console (Internal Track) usando Fastlane.

## Solución de Problemas常见

- **Error: No se encontró key.properties**: Asegúrate de tener tu archivo de firma de Android configurado.
- **Error: Google Api Error: Invalid request**: Verifica que el `package_name` en `android/app/build.gradle.kts` y `android/fastlane/Appfile` coincidan con el de Google Play Console.
- **Fastlane not found**: Asegúrate de que `fastlane` esté en tu PATH (`fastlane --version`).
