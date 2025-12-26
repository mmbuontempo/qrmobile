# qrmobile – PromusLink Mobile App

Frontend Flutter (Android/iOS/Web) para la plataforma de QRs dinámicos PromusLink.

## Capacidades actuales
- Login con Google OAuth (abre navegador externo).
- Dashboard con métricas de scans y resumen de QRs.
- Lista de QRs con acciones de compartir, activar/pausar y refresco.
- Detalle de QR con edición básica, compartir y eliminar.
- Creación de QR desde diálogo modal.
- Modo demo con datos mock si la API responde 401.
- Soporte multi-plataforma: Android, iOS, Web (Flutter).

## Tecnologías
- Flutter 3.x, Dart
- Estado: Provider
- HTTP: dio
- Almacenamiento seguro: flutter_secure_storage
- UI: Material 3, google_fonts

## Configuración
1) Requisitos: Flutter SDK instalado y dispositivo/emulador.
2) Instalar dependencias:
```bash
flutter pub get
```
3) Ejecutar en emulador Android:
```bash
flutter run -d emulator-5554
```

## API / Entornos
- Producción (por defecto): `https://promuslink.com`
- Desarrollo local (emulador Android): `http://10.0.2.2:4000`

Endpoints usados:
- Auth: `/auth/google` (OAuth vía navegador)
- QRs: `/api/qr`
- Stats: `/api/stats`

## Flujo de autenticación (estado actual)
1. Tocar “Continuar con Google” abre navegador externo.
2. Usuario inicia sesión en Google y obtiene cookie de sesión en el navegador.
3. Volver a la app y tocar “Ya me autentiqué”.
4. Si no hay cookie compartida, la app entra en modo demo (mock) para no romper UX.

> Próximo paso recomendado: implementar el flujo móvil con tokens (access/refresh + deep link) según `MOBILE_AUTH_SPEC.md` en el backend.

## Builds
- Web: `flutter build web`
- Android APK debug: `flutter build apk`
- Android APK release: `flutter build apk --release`

## Estructura relevante
- `lib/app/` – configuración de MaterialApp y temas.
- `lib/core/` – API client, modelos y servicios.
- `lib/features/auth/` – login y provider de auth.
- `lib/features/dashboard/` – dashboard y métricas.
- `lib/features/qr/` – lista, detalle y creación de QRs.
- `lib/main.dart` – punto de entrada con MultiProvider.

## Notas
- No se almacena ninguna clave secreta en el cliente.
- Usa cookies HttpOnly del backend; en móvil no se comparten con la app (de ahí el modo demo).
- Para pruebas reales en móvil, actualizar backend con el flujo de tokens y deep links descrito en `MOBILE_AUTH_SPEC.md`.
