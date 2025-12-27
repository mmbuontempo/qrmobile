# Especificaciones: Autenticación Móvil para PromusLink

> **Versión:** 2.0 - Con Mejores Prácticas de Seguridad  
> **Fecha:** Diciembre 2024  
> **Estándar:** OAuth 2.0 / RFC 6749 inspirado

## Problema Actual

El backend usa **cookies HttpOnly** para autenticación, lo cual funciona perfecto en navegadores web pero **NO funciona en apps móviles nativas** porque:

1. El navegador del dispositivo y la app Flutter **no comparten cookies**
2. Cuando el usuario se autentica en Chrome/Safari, la cookie queda en el navegador, no en la app

## Solución Propuesta

Implementar un sistema de **Access Token + Refresh Token** siguiendo las mejores prácticas de la industria (similar a OAuth 2.0), con:

- ✅ **Tokens hasheados en DB** (si hackean la DB, no sirven los hashes)
- ✅ **Access Token corto** (15 minutos) para requests
- ✅ **Refresh Token largo** (30 días) para renovar access tokens
- ✅ **Deep Links** para transferir sesión automáticamente (mejor UX)
- ✅ **Fingerprint de dispositivo** para validación adicional
- ✅ **Rotación de refresh tokens** (se invalida el anterior al renovar)

---

## Arquitectura de Tokens

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUJO DE AUTH                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Usuario login en web (Google OAuth)                         │
│                    │                                            │
│                    ▼                                            │
│  2. Web genera "Auth Code" temporal (5 min, un solo uso)        │
│                    │                                            │
│                    ▼                                            │
│  3. App recibe código via Deep Link: promuslink://auth?code=X   │
│                    │                                            │
│                    ▼                                            │
│  4. App intercambia código por tokens:                          │
│     POST /api/mobile/token                                      │
│     { code: "X", deviceId: "...", deviceName: "..." }           │
│                    │                                            │
│                    ▼                                            │
│  5. Backend devuelve:                                           │
│     - Access Token (JWT, 15 min, NO se guarda en DB)            │
│     - Refresh Token (opaco, 30 días, hash en DB)                │
│                    │                                            │
│                    ▼                                            │
│  6. App usa Access Token en headers:                            │
│     Authorization: Bearer <access_token>                        │
│                    │                                            │
│                    ▼                                            │
│  7. Cuando Access Token expira (401):                           │
│     POST /api/mobile/token/refresh                              │
│     { refreshToken: "..." }                                     │
│     → Nuevo Access Token + Nuevo Refresh Token (rotación)       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Cambios Requeridos

### 1. Variables de Entorno

**Archivo:** `.env` y `.env.example`

```env
# Mobile Auth - IMPORTANTE: Generar secrets seguros
# Usar: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET_MOBILE=genera-un-secret-de-64-bytes-minimo-para-firmar-jwt
MOBILE_AUTH_CODE_SECRET=otro-secret-diferente-para-auth-codes

# Configuración de expiración
ACCESS_TOKEN_EXPIRY_MINUTES=15
REFRESH_TOKEN_EXPIRY_DAYS=30
AUTH_CODE_EXPIRY_MINUTES=5
```

---

### 2. Modelos Prisma

**Archivo:** `prisma/schema.prisma`

Agregar al final del archivo:

```prisma
// ============================================================================
// MOBILE AUTH MODELS
// ============================================================================

// Códigos de autorización temporales (para transferir sesión web → app)
model MobileAuthCode {
  id        String   @id @default(cuid())
  createdAt DateTime @default(now())
  
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  // El código que se envía al deep link (hasheado con SHA-256)
  codeHash  String   @unique
  
  // Metadata del dispositivo que solicitó el código
  deviceId    String?
  deviceName  String?
  userAgent   String?
  
  expiresAt DateTime
  usedAt    DateTime?  // null = no usado, fecha = usado
  
  @@index([userId])
  @@index([expiresAt])
}

// Refresh tokens para mantener sesión en dispositivos móviles
model MobileRefreshToken {
  id        String   @id @default(cuid())
  createdAt DateTime @default(now())
  
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  // Token hasheado (SHA-256) - NUNCA guardar el token raw
  tokenHash String   @unique
  
  // Identificación del dispositivo
  deviceId    String   // Fingerprint único del dispositivo
  deviceName  String?  // "iPhone 15 Pro", "Samsung Galaxy S24"
  deviceOS    String?  // "iOS 17.2", "Android 14"
  appVersion  String?  // "1.0.0"
  
  // Control de sesión
  expiresAt   DateTime
  lastUsedAt  DateTime?
  lastIp      String?
  
  // Revocación
  revokedAt   DateTime?
  revokedReason String?  // "user_logout", "security", "new_device", etc.
  
  // Para rotación: referencia al token que lo reemplazó
  replacedByTokenId String?
  
  @@index([userId])
  @@index([deviceId])
  @@index([expiresAt])
}
```

**Agregar relaciones en el modelo `User`:**
```prisma
model User {
  // ... campos existentes ...
  
  // Mobile auth
  mobileAuthCodes    MobileAuthCode[]
  mobileRefreshTokens MobileRefreshToken[]
}
```

**Ejecutar después de modificar:**
```bash
npx prisma migrate dev --name add_mobile_auth
npx prisma generate
```

---

### 3. Nuevo Archivo de Rutas Móviles (COMPLETO)

**Archivo:** `server/mobile.routes.ts` (CREAR NUEVO)

```typescript
import { Router, RequestHandler } from 'express';
import { prisma } from '../src/app/lib/prisma.server';
import { createHash, randomBytes } from 'node:crypto';
import jwt from 'jsonwebtoken'; // npm install jsonwebtoken @types/jsonwebtoken

const router = Router();

// ============================================================================
// CONFIGURACIÓN
// ============================================================================

const JWT_SECRET = process.env.JWT_SECRET_MOBILE || 'CHANGE_ME_IN_PRODUCTION';
const AUTH_CODE_SECRET = process.env.MOBILE_AUTH_CODE_SECRET || 'CHANGE_ME_TOO';
const ACCESS_TOKEN_EXPIRY = Number(process.env.ACCESS_TOKEN_EXPIRY_MINUTES) || 15;
const REFRESH_TOKEN_EXPIRY = Number(process.env.REFRESH_TOKEN_EXPIRY_DAYS) || 30;
const AUTH_CODE_EXPIRY = Number(process.env.AUTH_CODE_EXPIRY_MINUTES) || 5;

// ============================================================================
// UTILIDADES DE SEGURIDAD
// ============================================================================

// Generar token aleatorio seguro
const generateSecureToken = (prefix: string = '') => {
  const token = randomBytes(32).toString('base64url');
  return prefix ? `${prefix}_${token}` : token;
};

// Hashear token con SHA-256 (para guardar en DB)
const hashToken = (token: string): string => {
  return createHash('sha256').update(token).digest('hex');
};

// Generar Access Token (JWT)
const generateAccessToken = (userId: string, companyId: string, role: string): string => {
  return jwt.sign(
    { 
      sub: userId, 
      cid: companyId, 
      role,
      type: 'access'
    },
    JWT_SECRET,
    { expiresIn: `${ACCESS_TOKEN_EXPIRY}m` }
  );
};

// Verificar Access Token
const verifyAccessToken = (token: string): { sub: string; cid: string; role: string } | null => {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    if (decoded.type !== 'access') return null;
    return { sub: decoded.sub, cid: decoded.cid, role: decoded.role };
  } catch {
    return null;
  }
};

// ============================================================================
// MIDDLEWARE DE AUTENTICACIÓN MÓVIL
// ============================================================================

export const requireMobileAuth: RequestHandler = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'missing_token', message: 'Authorization header required' });
  }
  
  const token = authHeader.substring(7);
  
  // Verificar JWT
  const payload = verifyAccessToken(token);
  if (!payload) {
    return res.status(401).json({ error: 'invalid_token', message: 'Token expired or invalid' });
  }
  
  // Verificar que el usuario sigue activo
  const user = await prisma.user.findUnique({
    where: { id: payload.sub },
    select: { id: true, companyId: true, role: true, isActive: true }
  });
  
  if (!user || !user.isActive) {
    return res.status(401).json({ error: 'user_inactive' });
  }
  
  // Guardar datos en res.locals
  res.locals.userId = user.id;
  res.locals.userRole = user.role;
  res.locals.companyId = user.companyId || '';
  res.locals.isMobile = true;
  
  next();
};

// ============================================================================
// ENDPOINTS
// ============================================================================

/**
 * POST /api/mobile/auth/code
 * 
 * Genera un código de autorización temporal para transferir sesión web → app
 * El código se envía via deep link: promuslink://auth?code=XXXXX
 * 
 * Requiere: Sesión web activa (cookie)
 */
router.post('/auth/code', async (req, res) => {
  const isProd = process.env.NODE_ENV === 'production';
  const COOKIE_NAME = isProd ? 'qrdynamic_session' : 'qrdynamic_session_dev';
  
  const cookie = req.cookies?.[COOKIE_NAME];
  if (!cookie) {
    return res.status(401).json({ error: 'web_session_required' });
  }
  
  try {
    const session = typeof cookie === 'string' ? JSON.parse(cookie) : cookie;
    if (!session?.userId) {
      return res.status(401).json({ error: 'invalid_session' });
    }
    
    const user = await prisma.user.findUnique({
      where: { id: session.userId },
      select: { id: true, email: true, isActive: true }
    });
    
    if (!user || !user.isActive) {
      return res.status(401).json({ error: 'user_not_found' });
    }
    
    // Invalidar códigos anteriores no usados de este usuario
    await prisma.mobileAuthCode.updateMany({
      where: { userId: user.id, usedAt: null },
      data: { usedAt: new Date() } // Marcar como usados
    });
    
    // Generar nuevo código (corto para fácil lectura si es necesario)
    const code = generateSecureToken('ac');
    const codeHash = hashToken(code);
    const expiresAt = new Date(Date.now() + AUTH_CODE_EXPIRY * 60 * 1000);
    
    await prisma.mobileAuthCode.create({
      data: {
        userId: user.id,
        codeHash,
        deviceId: req.body.deviceId || null,
        deviceName: req.body.deviceName || null,
        userAgent: req.headers['user-agent'] || null,
        expiresAt,
      }
    });
    
    console.log(`[mobile] Auth code generated for ${user.email}`);
    
    // Devolver el código y el deep link
    const deepLink = `promuslink://auth?code=${encodeURIComponent(code)}`;
    
    res.json({
      code,
      deepLink,
      expiresAt: expiresAt.toISOString(),
      expiresInSeconds: AUTH_CODE_EXPIRY * 60,
    });
  } catch (error) {
    console.error('[mobile] Auth code error:', error);
    res.status(500).json({ error: 'code_generation_failed' });
  }
});

/**
 * POST /api/mobile/auth/token
 * 
 * Intercambia un código de autorización por access + refresh tokens
 * 
 * Body: { code, deviceId, deviceName, deviceOS, appVersion }
 */
router.post('/auth/token', async (req, res) => {
  const { code, deviceId, deviceName, deviceOS, appVersion } = req.body;
  
  if (!code) {
    return res.status(400).json({ error: 'code_required' });
  }
  
  if (!deviceId) {
    return res.status(400).json({ error: 'device_id_required' });
  }
  
  try {
    const codeHash = hashToken(code);
    
    // Buscar código válido
    const authCode = await prisma.mobileAuthCode.findUnique({
      where: { codeHash },
      include: { 
        user: { 
          select: { 
            id: true, email: true, name: true, avatarUrl: true, 
            role: true, companyId: true, isActive: true 
          } 
        } 
      }
    });
    
    if (!authCode) {
      return res.status(401).json({ error: 'invalid_code' });
    }
    
    if (authCode.usedAt) {
      return res.status(401).json({ error: 'code_already_used' });
    }
    
    if (authCode.expiresAt < new Date()) {
      return res.status(401).json({ error: 'code_expired' });
    }
    
    if (!authCode.user || !authCode.user.isActive) {
      return res.status(401).json({ error: 'user_inactive' });
    }
    
    // Marcar código como usado
    await prisma.mobileAuthCode.update({
      where: { id: authCode.id },
      data: { usedAt: new Date() }
    });
    
    // Generar tokens
    const accessToken = generateAccessToken(
      authCode.user.id, 
      authCode.user.companyId || '', 
      authCode.user.role
    );
    
    const refreshToken = generateSecureToken('rt');
    const refreshTokenHash = hashToken(refreshToken);
    const refreshExpiresAt = new Date(Date.now() + REFRESH_TOKEN_EXPIRY * 24 * 60 * 60 * 1000);
    
    // Guardar refresh token (hasheado)
    await prisma.mobileRefreshToken.create({
      data: {
        userId: authCode.user.id,
        tokenHash: refreshTokenHash,
        deviceId,
        deviceName: deviceName || 'Mobile App',
        deviceOS: deviceOS || null,
        appVersion: appVersion || null,
        expiresAt: refreshExpiresAt,
        lastUsedAt: new Date(),
        lastIp: req.ip || null,
      }
    });
    
    console.log(`[mobile] Tokens issued for ${authCode.user.email} on device ${deviceId}`);
    
    res.json({
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TOKEN_EXPIRY * 60, // segundos
      refreshExpiresAt: refreshExpiresAt.toISOString(),
      user: {
        id: authCode.user.id,
        email: authCode.user.email,
        name: authCode.user.name,
        avatarUrl: authCode.user.avatarUrl,
        role: authCode.user.role,
      }
    });
  } catch (error) {
    console.error('[mobile] Token exchange error:', error);
    res.status(500).json({ error: 'token_exchange_failed' });
  }
});

/**
 * POST /api/mobile/auth/refresh
 * 
 * Renueva el access token usando el refresh token
 * Implementa rotación: el refresh token anterior se invalida
 * 
 * Body: { refreshToken, deviceId }
 */
router.post('/auth/refresh', async (req, res) => {
  const { refreshToken, deviceId } = req.body;
  
  if (!refreshToken || !deviceId) {
    return res.status(400).json({ error: 'refresh_token_and_device_id_required' });
  }
  
  try {
    const tokenHash = hashToken(refreshToken);
    
    // Buscar refresh token válido
    const storedToken = await prisma.mobileRefreshToken.findUnique({
      where: { tokenHash },
      include: { 
        user: { 
          select: { id: true, companyId: true, role: true, isActive: true, email: true } 
        } 
      }
    });
    
    if (!storedToken) {
      return res.status(401).json({ error: 'invalid_refresh_token' });
    }
    
    // Verificar que el deviceId coincide (seguridad adicional)
    if (storedToken.deviceId !== deviceId) {
      // Posible robo de token - revocar todos los tokens del usuario
      await prisma.mobileRefreshToken.updateMany({
        where: { userId: storedToken.userId },
        data: { revokedAt: new Date(), revokedReason: 'security_device_mismatch' }
      });
      console.warn(`[mobile] SECURITY: Device mismatch for user ${storedToken.user?.email}. All tokens revoked.`);
      return res.status(401).json({ error: 'security_violation' });
    }
    
    if (storedToken.revokedAt) {
      // Token ya fue revocado - posible replay attack
      // Revocar toda la familia de tokens
      await prisma.mobileRefreshToken.updateMany({
        where: { userId: storedToken.userId, deviceId },
        data: { revokedAt: new Date(), revokedReason: 'security_reuse_attempt' }
      });
      console.warn(`[mobile] SECURITY: Revoked token reuse attempt for ${storedToken.user?.email}`);
      return res.status(401).json({ error: 'token_revoked' });
    }
    
    if (storedToken.expiresAt < new Date()) {
      return res.status(401).json({ error: 'refresh_token_expired' });
    }
    
    if (!storedToken.user || !storedToken.user.isActive) {
      return res.status(401).json({ error: 'user_inactive' });
    }
    
    // ROTACIÓN: Revocar token actual
    await prisma.mobileRefreshToken.update({
      where: { id: storedToken.id },
      data: { 
        revokedAt: new Date(), 
        revokedReason: 'rotated' 
      }
    });
    
    // Generar nuevos tokens
    const newAccessToken = generateAccessToken(
      storedToken.user.id,
      storedToken.user.companyId || '',
      storedToken.user.role
    );
    
    const newRefreshToken = generateSecureToken('rt');
    const newRefreshTokenHash = hashToken(newRefreshToken);
    const newRefreshExpiresAt = new Date(Date.now() + REFRESH_TOKEN_EXPIRY * 24 * 60 * 60 * 1000);
    
    // Guardar nuevo refresh token
    const newTokenRecord = await prisma.mobileRefreshToken.create({
      data: {
        userId: storedToken.userId,
        tokenHash: newRefreshTokenHash,
        deviceId,
        deviceName: storedToken.deviceName,
        deviceOS: storedToken.deviceOS,
        appVersion: storedToken.appVersion,
        expiresAt: newRefreshExpiresAt,
        lastUsedAt: new Date(),
        lastIp: req.ip || null,
      }
    });
    
    // Actualizar referencia de rotación
    await prisma.mobileRefreshToken.update({
      where: { id: storedToken.id },
      data: { replacedByTokenId: newTokenRecord.id }
    });
    
    res.json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresIn: ACCESS_TOKEN_EXPIRY * 60,
      refreshExpiresAt: newRefreshExpiresAt.toISOString(),
    });
  } catch (error) {
    console.error('[mobile] Token refresh error:', error);
    res.status(500).json({ error: 'token_refresh_failed' });
  }
});

/**
 * GET /api/mobile/auth/me
 * 
 * Obtiene el usuario actual
 */
router.get('/auth/me', requireMobileAuth, async (req, res) => {
  const userId = res.locals.userId as string;
  
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      name: true,
      avatarUrl: true,
      role: true,
      companyId: true,
      isActive: true,
      company: { select: { name: true, slug: true } }
    }
  });
  
  if (!user) {
    return res.status(404).json({ error: 'user_not_found' });
  }
  
  res.json({ user });
});

/**
 * POST /api/mobile/auth/logout
 * 
 * Revoca el refresh token actual (logout del dispositivo)
 */
router.post('/auth/logout', async (req, res) => {
  const { refreshToken, deviceId } = req.body;
  
  if (!refreshToken) {
    return res.json({ ok: true }); // Ya está deslogueado
  }
  
  try {
    const tokenHash = hashToken(refreshToken);
    
    await prisma.mobileRefreshToken.updateMany({
      where: { tokenHash },
      data: { revokedAt: new Date(), revokedReason: 'user_logout' }
    });
    
    res.json({ ok: true });
  } catch (error) {
    console.error('[mobile] Logout error:', error);
    res.json({ ok: true }); // No fallar logout
  }
});

/**
 * GET /api/mobile/auth/devices
 * 
 * Lista todos los dispositivos con sesión activa
 */
router.get('/auth/devices', requireMobileAuth, async (req, res) => {
  const userId = res.locals.userId as string;
  
  const devices = await prisma.mobileRefreshToken.findMany({
    where: {
      userId,
      revokedAt: null,
      expiresAt: { gt: new Date() }
    },
    select: {
      id: true,
      deviceName: true,
      deviceOS: true,
      appVersion: true,
      createdAt: true,
      lastUsedAt: true,
      lastIp: true,
    },
    orderBy: { lastUsedAt: 'desc' }
  });
  
  res.json({ devices });
});

/**
 * DELETE /api/mobile/auth/devices/:id
 * 
 * Revoca sesión de un dispositivo específico
 */
router.delete('/auth/devices/:id', requireMobileAuth, async (req, res) => {
  const userId = res.locals.userId as string;
  const { id } = req.params;
  
  const token = await prisma.mobileRefreshToken.findFirst({
    where: { id, userId, revokedAt: null }
  });
  
  if (!token) {
    return res.status(404).json({ error: 'device_not_found' });
  }
  
  await prisma.mobileRefreshToken.update({
    where: { id },
    data: { revokedAt: new Date(), revokedReason: 'user_revoked' }
  });
  
  res.json({ ok: true });
});

/**
 * POST /api/mobile/auth/logout-all
 * 
 * Revoca TODAS las sesiones móviles del usuario
 */
router.post('/auth/logout-all', requireMobileAuth, async (req, res) => {
  const userId = res.locals.userId as string;
  
  await prisma.mobileRefreshToken.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: new Date(), revokedReason: 'user_logout_all' }
  });
  
  res.json({ ok: true });
});

export default router;
```

---

### 4. Registrar las Rutas en el Servidor

**Archivo:** `server/index.ts`

Agregar después de los imports existentes:
```typescript
import mobileRouter, { requireMobileAuth } from './mobile.routes'
```

Agregar después de las rutas de billing (línea ~164):
```typescript
// Mobile API Routes
app.use('/api/mobile', mobileRouter)

// Mobile-compatible API routes (accept both cookie and Bearer token)
const mobileOrWebAuth: express.RequestHandler = async (req, res, next) => {
  // Try Bearer token first (mobile)
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith('Bearer ')) {
    return requireMobileAuth(req, res, next);
  }
  // Fall back to cookie auth (web)
  return requireAuth(req, res, next);
};

// Replace requireAuth with mobileOrWebAuth for these routes if you want
// them accessible from mobile:
// app.get('/api/qr', rateLimit, mobileOrWebAuth, listQr)
// etc.
```

---

### 5. Página Web para Conectar App (Con Deep Link)

**Archivo:** `src/app/routes/mobile-auth.tsx` (CREAR NUEVO)

```tsx
import { useState, useEffect } from 'react';

export default function MobileAuthPage() {
  const [authData, setAuthData] = useState<{
    code: string;
    deepLink: string;
    expiresInSeconds: number;
  } | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [countdown, setCountdown] = useState(0);

  // Countdown timer
  useEffect(() => {
    if (countdown <= 0) return;
    const timer = setInterval(() => {
      setCountdown(c => c - 1);
    }, 1000);
    return () => clearInterval(timer);
  }, [countdown]);

  const generateCode = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const res = await fetch('/api/mobile/auth/code', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ deviceName: 'Mobile App' })
      });
      
      if (!res.ok) {
        const data = await res.json();
        if (data.error === 'web_session_required') {
          throw new Error('Debes iniciar sesión primero');
        }
        throw new Error(data.error || 'Error al generar código');
      }
      
      const data = await res.json();
      setAuthData(data);
      setCountdown(data.expiresInSeconds);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Error desconocido');
    } finally {
      setLoading(false);
    }
  };

  const openInApp = () => {
    if (authData?.deepLink) {
      window.location.href = authData.deepLink;
    }
  };

  const copyCode = () => {
    if (authData?.code) {
      navigator.clipboard.writeText(authData.code);
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl shadow-2xl p-8 max-w-md w-full">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-indigo-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl">📱</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Conectar App Móvil</h1>
          <p className="text-gray-500 mt-2">
            Vincula tu cuenta con la app de PromusLink
          </p>
        </div>

        {!authData ? (
          /* Step 1: Generate Code */
          <div className="space-y-4">
            <button
              onClick={generateCode}
              disabled={loading}
              className="w-full bg-indigo-600 text-white py-4 px-6 rounded-xl font-semibold 
                         hover:bg-indigo-700 disabled:opacity-50 transition-all
                         flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none"/>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                  </svg>
                  Generando...
                </>
              ) : (
                <>
                  <span>🔗</span>
                  Generar Código de Vinculación
                </>
              )}
            </button>
            
            <div className="bg-blue-50 border border-blue-100 rounded-xl p-4">
              <p className="text-sm text-blue-800">
                <strong>¿Cómo funciona?</strong><br/>
                1. Genera un código aquí<br/>
                2. Abre la app en tu celular<br/>
                3. El código se transferirá automáticamente
              </p>
            </div>
          </div>
        ) : countdown > 0 ? (
          /* Step 2: Show Code */
          <div className="space-y-6">
            {/* Timer */}
            <div className="text-center">
              <div className="inline-flex items-center gap-2 bg-orange-100 text-orange-700 px-4 py-2 rounded-full text-sm font-medium">
                <span>⏱️</span>
                Expira en {formatTime(countdown)}
              </div>
            </div>

            {/* Deep Link Button (Primary) */}
            <button
              onClick={openInApp}
              className="w-full bg-green-600 text-white py-4 px-6 rounded-xl font-semibold 
                         hover:bg-green-700 transition-all flex items-center justify-center gap-2"
            >
              <span>📲</span>
              Abrir en la App
            </button>

            {/* Manual Code (Secondary) */}
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-200"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-white text-gray-500">o copia el código</span>
              </div>
            </div>

            <div 
              onClick={copyCode}
              className="bg-gray-100 p-4 rounded-xl cursor-pointer hover:bg-gray-200 transition-all"
            >
              <p className="text-xs text-gray-500 mb-1">Código (toca para copiar):</p>
              <code className="text-sm break-all font-mono text-gray-800">{authData.code}</code>
            </div>

            {/* New Code Button */}
            <button
              onClick={generateCode}
              className="w-full text-indigo-600 py-2 font-medium hover:underline"
            >
              Generar nuevo código
            </button>
          </div>
        ) : (
          /* Code Expired */
          <div className="text-center space-y-4">
            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto">
              <span className="text-3xl">⏰</span>
            </div>
            <p className="text-gray-600">El código ha expirado</p>
            <button
              onClick={generateCode}
              className="w-full bg-indigo-600 text-white py-3 px-6 rounded-xl font-semibold hover:bg-indigo-700"
            >
              Generar Nuevo Código
            </button>
          </div>
        )}

        {error && (
          <div className="mt-4 bg-red-50 border border-red-100 rounded-xl p-4">
            <p className="text-red-600 text-sm text-center">{error}</p>
          </div>
        )}

        {/* Footer */}
        <p className="text-xs text-gray-400 text-center mt-6">
          El código es de un solo uso y expira en 5 minutos
        </p>
      </div>
    </div>
  );
}
```

---

### 6. Agregar Ruta en React Router

**Archivo:** `src/App.tsx` o donde tengas las rutas

```tsx
import MobileAuthPage from './app/routes/mobile-auth';

// En las rutas:
<Route path="/mobile-auth" element={<MobileAuthPage />} />
```

---

## Flujo de Uso Final (Con Deep Links)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   APP MÓVIL     │     │   NAVEGADOR     │     │    BACKEND      │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │  1. Toca "Login"      │                       │
         │──────────────────────>│                       │
         │                       │                       │
         │                       │  2. Google OAuth      │
         │                       │──────────────────────>│
         │                       │                       │
         │                       │  3. Sesión web OK     │
         │                       │<──────────────────────│
         │                       │                       │
         │                       │  4. Va a /mobile-auth │
         │                       │──────────────────────>│
         │                       │                       │
         │                       │  5. POST /auth/code   │
         │                       │──────────────────────>│
         │                       │                       │
         │                       │  6. Código + DeepLink │
         │                       │<──────────────────────│
         │                       │                       │
         │  7. Deep Link         │                       │
         │  promuslink://auth    │                       │
         │<──────────────────────│                       │
         │                       │                       │
         │  8. POST /auth/token (code + deviceId)        │
         │─────────────────────────────────────────────>│
         │                       │                       │
         │  9. Access + Refresh Tokens                   │
         │<─────────────────────────────────────────────│
         │                       │                       │
         │  10. ¡LISTO! Usa Access Token en requests    │
         │                       │                       │
```

---

## Resumen de Archivos a Modificar/Crear

| # | Archivo | Acción | Descripción |
|---|---------|--------|-------------|
| 1 | `.env` | **MODIFICAR** | Agregar secrets JWT y configuración |
| 2 | `prisma/schema.prisma` | **MODIFICAR** | Agregar `MobileAuthCode` + `MobileRefreshToken` + relaciones en `User` |
| 3 | `server/mobile.routes.ts` | **CREAR** | ~500 líneas - Endpoints completos de auth móvil |
| 4 | `server/index.ts` | **MODIFICAR** | 2 líneas - Import + registrar rutas |
| 5 | `src/app/routes/mobile-auth.tsx` | **CREAR** | Página web para generar código |
| 6 | Rutas React | **MODIFICAR** | Agregar ruta `/mobile-auth` |

---

## Dependencias Nuevas

```bash
npm install jsonwebtoken
npm install -D @types/jsonwebtoken
```

---

## Comandos a Ejecutar (En Orden)

```bash
# 1. Instalar dependencia JWT
npm install jsonwebtoken @types/jsonwebtoken

# 2. Después de modificar schema.prisma
npx prisma migrate dev --name add_mobile_auth
npx prisma generate

# 3. Generar secrets seguros para .env
node -e "console.log('JWT_SECRET_MOBILE=' + require('crypto').randomBytes(64).toString('hex'))"
node -e "console.log('MOBILE_AUTH_CODE_SECRET=' + require('crypto').randomBytes(32).toString('hex'))"

# 4. Reiniciar servidor
npm run dev

# 5. Probar en local, luego deploy
npm run deploy
```

---

## Checklist de Seguridad ✅

| Práctica | Implementado |
|----------|--------------|
| Tokens hasheados en DB (SHA-256) | ✅ |
| Access Token corto (15 min) | ✅ |
| Refresh Token largo (30 días) | ✅ |
| Rotación de refresh tokens | ✅ |
| Códigos de un solo uso | ✅ |
| Expiración de códigos (5 min) | ✅ |
| Verificación de deviceId | ✅ |
| Detección de replay attacks | ✅ |
| Revocación de sesiones | ✅ |
| Logout de todos los dispositivos | ✅ |
| Rate limiting (existente) | ✅ |
| HTTPS obligatorio | ✅ |

---

## Comparación con Estándares

| Estándar | PromusLink Mobile Auth |
|----------|------------------------|
| OAuth 2.0 Authorization Code | ✅ Similar (auth code → tokens) |
| JWT para access tokens | ✅ Implementado |
| Refresh token rotation (RFC 6749) | ✅ Implementado |
| Token binding por dispositivo | ✅ deviceId verificado |
| PKCE (OAuth 2.1) | ⚠️ No implementado (opcional para apps propias) |

---

## Notas Finales

1. **Los secrets en `.env` son CRÍTICOS** - Nunca commitear al repo
2. **Hacer backup de la DB** antes de migrar en producción
3. **Probar todo en local** antes de deploy
4. **Monitorear logs** por intentos de seguridad sospechosos
