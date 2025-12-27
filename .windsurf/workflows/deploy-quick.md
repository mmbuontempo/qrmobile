---
description: Deploy rápido sin verificaciones (kick deploy)
---

# /deploy-quick

> **Propósito**: Deploy de emergencia - salta verificaciones y va directo a producción.

---

## 📚 GLOSARIO - ¿Qué significa cada cosa?

| Término | Qué es (en simple) | Analogía |
|---------|-------------------|----------|
| **Kick deploy** | Deploy rápido sin verificaciones | Saltar la fila |
| **Hot fix** | Arreglo urgente en producción | Parche de emergencia |
| **Skip checks** | Saltarse tests y verificaciones | Ir sin casco (riesgoso) |

### ⚠️ CUÁNDO USAR ESTO

| ✅ Usar cuando... | ❌ NO usar cuando... |
|------------------|---------------------|
| Bug crítico en producción | Cambios normales de código |
| Arreglo de 1-2 líneas | Nuevas funcionalidades |
| Ya probaste localmente | No estás seguro del cambio |
| Es urgente | Tienes tiempo para tests |

---

## 🎯 QUÉ VAMOS A HACER

1. **Deploy directo** → Sin build local, sin tests
2. **Verificar** → Confirmar que el servidor responde

**RIESGO**: Si hay errores, los usuarios los verán. Usa `/desplegar` para cambios normales.

---

## PASOS

1. Ejecutar deploy directo:
```powershell
.\scripts\vps\deploy.ps1
```

2. Verificar servidor:
// turbo
```powershell
Invoke-WebRequest -Uri "https://mitenda.com" -Method HEAD -TimeoutSec 10 | Select-Object StatusCode
```
