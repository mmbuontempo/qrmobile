# PromusLink Flutter App - API Audit & Requirements

**Fecha:** 27 de diciembre de 2025  
**Versión:** 1.0

---

## 1. Resumen Ejecutivo

La app Flutter actúa como dashboard nativo Android para PromusLink. Debe replicar **todas** las funcionalidades del panel web, respetando límites de plan y seguridad multi-tenant.

### Estado Actual del Backend

| Área | Estado | Notas |
|------|--------|-------|
| Auth móvil (JWT) | ✅ Implementado | Google Sign-In nativo + refresh tokens |
| CRUD QRs | ✅ Implementado | Soporta Bearer token |
| Validación de planes | ✅ Implementado | `/api/account/subscription` con features |
| Billing/Pagos | ⚠️ Web only | Usar deep link para pagar |
| Analytics | ✅ Implementado | `/api/qr/:id/analytics` |
| Settings usuario | ✅ Implementado | `/api/account/profile` |
| Folders | ✅ Implementado | CRUD completo |
| Acciones rápidas | ✅ Implementado | Toggle, duplicate, get by ID |

---

## 2. Endpoints Disponibles para Flutter

> **Todos los endpoints (excepto auth) soportan Bearer token:** `Authorization: Bearer <access_token>`

### 2.1 Autenticación (`/api/mobile/auth/*`)

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/api/mobile/auth/google` | POST | - | Login con Google ID Token (nativo) |
| `/api/mobile/auth/code` | POST | Cookie | Genera código para transferir sesión web→app |
| `/api/mobile/auth/token` | POST | - | Intercambia código por tokens |
| `/api/mobile/auth/refresh` | POST | - | Renueva access token (con rotación) |
| `/api/mobile/auth/me` | GET | Bearer | Info del usuario actual |
| `/api/mobile/auth/logout` | POST | - | Revoca refresh token |
| `/api/mobile/auth/devices` | GET | Bearer | Lista dispositivos activos |
| `/api/mobile/auth/devices/:id` | DELETE | Bearer | Revoca sesión de dispositivo |
| `/api/mobile/auth/logout-all` | POST | Bearer | Revoca todas las sesiones |

**Respuesta de login exitoso:**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "rt_...",
  "expiresIn": 900,
  "refreshExpiresAt": "2025-01-26T...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "User Name",
    "avatarUrl": "https://...",
    "role": "ADMIN",
    "companyId": "uuid",
    "company": { "id": "uuid", "name": "Company", "slug": "company-slug" }
  }
}
```

### 2.2 QR CRUD (`/api/qr/*`)

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/api/qr` | GET | Bearer | Lista QRs del usuario |
| `/api/qr` | POST | Bearer | Crear QR (valida límite de plan) |
| `/api/qr/:id` | GET | Bearer | Obtener QR por ID (detalle) |
| `/api/qr/:id` | PATCH | Bearer | Actualizar QR |
| `/api/qr/:id` | DELETE | Bearer | Desactivar QR (soft delete) |
| `/api/qr/:id/toggle` | POST | Bearer | Toggle activo/pausado (acción rápida) |
| `/api/qr/:id/duplicate` | POST | Bearer | Duplicar QR (valida límite plan) |
| `/api/qr/:id/rules` | GET | Bearer | Obtener reglas de rotación |
| `/api/qr/:id/rules` | PUT | Bearer | Actualizar reglas de rotación |
| `/api/qr/:id/analytics` | GET | Bearer | Analytics del QR |
| `/api/qr/:id/report` | GET | Bearer | Reporte HTML (para PDF) |

**Respuesta de lista QRs:**
```json
{
  "data": [{
    "id": "uuid",
    "name": "QR01",
    "slug": "qr01",
    "shortCode": "ABC123",
    "targetUrl": "https://...",
    "isActive": true,
    "showInterstitial": false,
    "createdAt": "2025-01-01T...",
    "updatedAt": "2025-01-01T...",
    "microsite": null,
    "folderId": null,
    "folder": null,
    "utmSource": null,
    "utmMedium": null,
    "utmCampaign": null
  }],
  "isFirstQr": false
}
```

**Error de límite de plan (403):**
```json
{
  "error": "qr_limit_reached",
  "message": "Tu plan permite máximo 1 QR. Actualizá tu plan para crear más.",
  "limit": 1,
  "current": 1
}
```

### 2.3 Folders (`/api/folders/*`)

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/api/folders` | GET | Bearer | Lista folders |
| `/api/folders` | POST | Bearer | Crear folder |
| `/api/folders/:id` | PATCH | Bearer | Actualizar folder |
| `/api/folders/:id` | DELETE | Bearer | Eliminar folder |

### 2.4 Dashboard Stats (`/api/stats`)

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/api/stats` | GET | Bearer | Stats del dashboard |

**Respuesta:**
```json
{
  "data": {
    "activeQrs": 1,
    "scansToday": 5,
    "scansMonth": 120,
    "planName": "Starter",
    "qrLimit": 1,
    "qrUsed": 1,
    "qrRemaining": 0
  }
}
```

### 2.5 Billing (`/api/billing/*`)

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/api/billing/status` | GET | Bearer | Estado del plan actual |
| `/api/billing/create-intent` | POST | Bearer | Crear intento de pago (web only) |

**Respuesta de status:**
```json
{
  "planKey": "starter",
  "paidUntil": null,
  "isActive": false
}
```

### 2.6 Account (`/api/account/*`)

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/api/account/profile` | PATCH | Bearer | Actualizar perfil (nombre, avatar, idioma, timezone) |
| `/api/account/subscription` | GET | Bearer | Detalles del plan y features disponibles |
| `/api/account/delete` | DELETE | Bearer | Eliminar cuenta (GDPR) |
| `/api/account/accept-terms` | POST | Bearer | Aceptar términos |

**Actualizar perfil:**
```json
// PATCH /api/account/profile
{
  "name": "Nuevo Nombre",
  "avatarUrl": "https://...",
  "language": "es",  // es, en, pt
  "timezone": "America/Buenos_Aires"
}
```

**Respuesta subscription:**
```json
{
  "data": {
    "planKey": "free",
    "planName": "Starter",
    "isPaid": false,
    "paidUntil": null,
    "qrLimit": 1,
    "qrUsed": 1,
    "qrRemaining": 0,
    "features": {
      "microsites": false,
      "analytics": true,
      "folders": false,
      "export": false,
      "customDomain": false,
      "apiAccess": false
    }
  }
}
```

### 2.7 Analytics Avanzados (`/api/analytics`)

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/api/analytics` | GET | Bearer | Analytics Markov/Montecarlo |

### 2.8 Export (`/api/export/*`)

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/api/export/scans` | GET | Bearer | Exportar scans a CSV |

---

## 3. Endpoints Adicionales (NUEVOS)

### 3.1 ✅ IMPLEMENTADO: Endpoint de Subscription

**Endpoint:** `GET /api/account/subscription`

Devuelve información completa del plan, límites y features disponibles. La app Flutter debe:
1. Llamar a este endpoint al iniciar
2. Cachear `qrLimit` y `qrRemaining`
3. Deshabilitar botón "Crear QR" si `qrRemaining === 0`
4. Mostrar/ocultar features según `features.*`

### 3.2 ✅ IMPLEMENTADO: Endpoint de User Profile

**Endpoint:** `PATCH /api/account/profile`

Permite actualizar nombre, avatar, idioma y timezone del usuario.

### 3.3 ✅ IMPLEMENTADO: Acciones Rápidas de QR

- `POST /api/qr/:id/toggle` - Activar/pausar QR con un tap
- `POST /api/qr/:id/duplicate` - Duplicar QR (valida límite de plan)
- `GET /api/qr/:id` - Obtener detalle de un QR específico

### 3.4 🟡 MEDIO: Billing para Móvil

**Problema:** El flujo de pago usa redirect a Mercado Pago, no funciona en app nativa.

**Opciones:**
1. **WebView:** Abrir billing en WebView con sesión transferida
2. **Deep Link:** Abrir browser, completar pago, volver con deep link
3. **In-App Purchase:** Implementar Google Play Billing (más complejo)

**Recomendación:** Opción 2 (Deep Link) es la más simple:
1. App abre `https://promuslink.com/app/billing` en browser
2. Usuario paga en web
3. Callback redirige a `promuslink://billing-success`
4. App refresca estado de plan

### 3.4 🟢 BAJO: Notificaciones Push

**Problema:** No hay infraestructura para push notifications.

**Para futuro:** Agregar FCM token al usuario y endpoints de notificación.

---

## 4. Auditoría de Seguridad

### 4.1 ✅ Aspectos Correctos

| Aspecto | Estado | Implementación |
|---------|--------|----------------|
| JWT con expiración corta | ✅ | 15 min access token |
| Refresh token rotation | ✅ | Token rotado en cada refresh |
| Device binding | ✅ | deviceId verificado en refresh |
| Token hashing | ✅ | SHA-256 para almacenar tokens |
| Multi-tenancy | ✅ | companyId en todas las queries |
| Rate limiting | ✅ | 60 req/min por IP+path |
| Security headers | ✅ | HSTS, X-Frame-Options, etc. |

### 4.2 ⚠️ Puntos a Mejorar

| Aspecto | Riesgo | Recomendación |
|---------|--------|---------------|
| JWT_SECRET en env | Medio | Verificar que sea ≥32 chars en prod |
| Google token verification | Bajo | Ya implementado correctamente |
| CORS para móvil | Bajo | No aplica (no usa cookies) |
| Audit logging | Medio | Agregar logs de acciones críticas |

### 4.3 🔴 Vulnerabilidades Potenciales

#### 4.3.1 Falta validación de plan en UI móvil

**Problema:** La app Flutter permite intentar crear QR sin verificar el plan primero.

**Impacto:** UX pobre (error después de llenar formulario).

**Solución:**
```dart
// En Flutter, antes de mostrar botón "Crear QR"
final stats = await api.getStats();
final canCreate = stats.qrRemaining > 0;

if (!canCreate) {
  showUpgradeDialog();
  return;
}
```

#### 4.3.2 El backend SÍ valida (es seguro)

El endpoint `POST /api/qr` valida el límite server-side:
```typescript
const qrLimit = await getCompanyQrLimit(companyId)
const currentQrCount = await prisma.qrCode.count({ where: { companyId } })
if (currentQrCount >= qrLimit) {
  return res.status(403).json({ error: 'qr_limit_reached', ... })
}
```

**Conclusión:** El backend es seguro, pero la app debe validar en UI para mejor UX.

---

## 5. Arquitectura Recomendada para Flutter

### 5.1 Estructura de Carpetas

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart       # HTTP client con interceptors
│   │   ├── auth_interceptor.dart # Manejo de tokens
│   │   └── endpoints.dart        # Constantes de URLs
│   ├── models/
│   │   ├── user.dart
│   │   ├── qr_code.dart
│   │   ├── folder.dart
│   │   └── plan.dart
│   └── services/
│       ├── auth_service.dart
│       ├── storage_service.dart  # Secure storage para tokens
│       └── analytics_service.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── providers/
│   │   └── widgets/
│   ├── dashboard/
│   │   ├── screens/
│   │   ├── providers/
│   │   └── widgets/
│   ├── qr/
│   │   ├── screens/
│   │   ├── providers/
│   │   └── widgets/
│   ├── billing/
│   │   ├── screens/
│   │   └── providers/
│   └── settings/
│       ├── screens/
│       └── providers/
└── main.dart
```

### 5.2 Flujo de Autenticación

```
┌─────────────────────────────────────────────────────────────┐
│                    App Launch                                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Check Secure Storage for Refresh Token                     │
└─────────────────────────────────────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
              ▼                           ▼
┌─────────────────────┐     ┌─────────────────────────────────┐
│  No Token Found     │     │  Token Found                    │
│  → Show Login       │     │  → Call /auth/refresh           │
└─────────────────────┘     └─────────────────────────────────┘
              │                           │
              ▼                           ▼
┌─────────────────────┐     ┌─────────────────────────────────┐
│  Google Sign-In     │     │  Refresh Success?               │
│  → Get ID Token     │     │  Yes → Go to Dashboard          │
│  → POST /auth/google│     │  No → Show Login                │
└─────────────────────┘     └─────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│  Store Tokens in Secure Storage                             │
│  → Go to Dashboard                                          │
└─────────────────────────────────────────────────────────────┘
```

### 5.3 Manejo de Tokens

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Intentar refresh
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Reintentar request original
        final response = await _retry(err.requestOptions);
        return handler.resolve(response);
      }
      // Refresh falló → logout
      _authService.logout();
    }
    handler.next(err);
  }
}
```

---

## 6. Checklist de Implementación Flutter

### 6.1 Fase 1: Core (Semana 1)

- [ ] Setup proyecto Flutter con arquitectura limpia
- [ ] Implementar `ApiClient` con Dio + interceptors
- [ ] Implementar `AuthService` con Google Sign-In
- [ ] Secure storage para tokens (flutter_secure_storage)
- [ ] Pantalla de login con Google Sign-In
- [ ] Auto-refresh de tokens

### 6.2 Fase 2: Dashboard (Semana 2)

- [ ] Pantalla principal con stats (`/api/stats`)
- [ ] Lista de QRs (`/api/qr`)
- [ ] Mostrar límite de plan y QRs usados
- [ ] Banner de upgrade si plan lleno

### 6.3 Fase 3: CRUD QRs (Semana 3)

- [ ] Crear QR (con validación de plan en UI)
- [ ] Editar QR
- [ ] Eliminar QR (confirmación)
- [ ] Ver analytics de QR
- [ ] Generar imagen QR (local con qr_flutter)

### 6.4 Fase 4: Extras (Semana 4)

- [ ] Folders (CRUD)
- [ ] Settings de usuario
- [ ] Billing (WebView o deep link)
- [ ] Eliminar cuenta
- [ ] Gestión de dispositivos

---

## 7. URLs para Google Play

### Privacy Policy
```
https://promuslink.com/privacidad
```

### Terms of Service
```
https://promuslink.com/terminos
```

---

## 8. Conclusiones

### ✅ El backend está preparado para Flutter
- Autenticación JWT implementada
- Endpoints CRUD funcionan con Bearer token
- Validación de planes server-side

### ⚠️ Mejoras necesarias en Flutter
1. **Validar plan en UI** antes de mostrar "Crear QR"
2. **Usar `/api/stats`** para obtener límites de plan
3. **Implementar billing** via WebView o deep link

### 🔒 Seguridad
- El sistema es seguro: validación server-side
- Tokens con rotación y binding a dispositivo
- Multi-tenancy correctamente implementado

---

## Apéndice A: Códigos de Error

| Código | HTTP | Descripción |
|--------|------|-------------|
| `unauthorized` | 401 | Sin autenticación |
| `invalid_token` | 401 | Token JWT inválido/expirado |
| `user_inactive` | 401 | Usuario desactivado |
| `qr_limit_reached` | 403 | Límite de plan alcanzado |
| `slug_exists` | 409 | Slug ya existe |
| `not_found` | 404 | Recurso no encontrado |
| `rate_limited` | 429 | Demasiadas requests |

## Apéndice B: Headers Requeridos

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

## Apéndice C: Base URLs

| Entorno | URL |
|---------|-----|
| Producción | `https://promuslink.com` |
| Desarrollo | `http://localhost:4000` |
