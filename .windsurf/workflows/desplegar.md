---
description: Desplegar aplicación al servidor de producción
---

# /desplegar

> **Propósito**: Subir tu app al servidor real para que los usuarios la puedan usar.

---

## 📚 GLOSARIO - ¿Qué significa cada cosa?

| Término | Qué es (en simple) | Analogía |
|---------|-------------------|----------|
| **Deploy** | Subir tu app a un servidor público | Abrir tu tienda al público |
| **Producción** | El servidor real donde los usuarios usan tu app | La tienda abierta |
| **Build** | Convertir tu código en archivos optimizados | Empaquetar para envío |
| **VPS** | Virtual Private Server - tu servidor en la nube | Tu computadora en internet |
| **SSH** | Conexión segura al servidor remoto | Túnel secreto al servidor |
| **CI/CD** | Automatización de tests y deploy | Robot que hace el deploy por ti |
| **Rollback** | Volver a una versión anterior | "Ctrl+Z" en producción |
| **Downtime** | Tiempo que la app está caída | Tienda cerrada por mantenimiento |

### Flujo de deploy

```
Tu código local
      ↓
Build (npm run build)
      ↓
Tests (npm run test)
      ↓
Crear imagen Docker
      ↓
Subir al VPS
      ↓
Reiniciar contenedor
      ↓
¡App en producción!
```

---

## 🎯 QUÉ VAMOS A HACER

1. **Build** → Verificar que compila sin errores
2. **TypeScript** → Verificar tipos correctos
3. **Tests** → Verificar que nada se rompió
4. **Deploy** → Subir al servidor
5. **Verificar** → Confirmar que funciona

---

## PASOS

1. Verificar que el build funciona localmente:
// turbo
```powershell
npm run build
```

2. Verificar TypeScript:
// turbo
```powershell
npx tsc --noEmit
```

3. Ejecutar tests:
// turbo
```powershell
npm run test
```

4. Ejecutar deploy a producción:
```powershell
npm run deploy
```

5. Verificar que el servidor responde:
// turbo
```powershell
Invoke-WebRequest -Uri "https://mitenda.com" -Method HEAD -TimeoutSec 10 | Select-Object StatusCode
```
